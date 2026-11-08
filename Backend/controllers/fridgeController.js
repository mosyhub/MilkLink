const Fridge = require('../models/fridge');
const Inventory = require('../models/inventory');
const AuditLog = require('../models/auditLog');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');

// Helper to compute fridge totals dynamically
async function computeFridgeStats(fridgeId) {
    const fridge = await Fridge.findById(fridgeId);
    if (!fridge) return null;

    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const isUnpast = fridge.fridgeType === 'Unpasteurized';

    // Find all non-deleted inventories in this fridge
    const query = { fridge: fridge._id, isDeleted: false };
    if (isUnpast) {
        query.isPasteurized = { $ne: true };
        query.status = { $ne: 'Pasteurized' };
        query.volume = { $gt: 0 };
    }
    const entries = await Inventory.find(query);

    let totalVolume = 0;
    let entryCount = entries.length;
    let nearExpiryCount = 0;
    let expiredCount = 0;

    for (const item of entries) {
        const exp = item.expiration || item.unpasteurizedDetails?.expiration || item.pasteurizedDetails?.expiration;
        const isExpired = exp && new Date(exp) < now;
        const isNearExpiry = exp && new Date(exp) >= now && new Date(exp) <= sevenDaysFromNow;

        if (isExpired) expiredCount++;
        if (isNearExpiry) nearExpiryCount++;

        if (isUnpast) {
            // Unpasteurized volume is item.volume or bags volume
            if (item.status !== 'Unavailable') {
                totalVolume += Math.round(item.volume || 0);
            }
        } else {
            // Pasteurized volume is availableBottles * bottleType
            if (item.status !== 'Depleted' && item.status !== 'Unavailable') {
                const bottles = item.availableBottles || (item.pasteurizedDetails?.bottles?.filter(b => b.status === 'Available').length) || 0;
                const bType = item.bottleType || item.pasteurizedDetails?.bottleType || 0;
                totalVolume += Math.round(bottles * bType);
            }
        }
    }

    return {
        ...fridge.toObject(),
        totalVolume,
        entryCount,
        nearExpiryCount,
        expiredCount,
    };
}

// Get All fridges => /api/v1/fridges
exports.allFridges = catchAsyncErrors(async (req, res) => {
    const { includeArchived } = req.query;
    const query = includeArchived === 'true' ? {} : { isDeleted: false };
    const rawFridges = await Fridge.find(query).sort({ createdAt: 1 });

    const fridgesWithStats = await Promise.all(
        rawFridges.map(f => computeFridgeStats(f._id))
    );

    res.status(200).json({
        success: true,
        count: fridgesWithStats.length,
        fridges: fridgesWithStats.filter(Boolean),
    });
});

// Get Archived fridges => /api/v1/fridges/archived
exports.archivedFridges = catchAsyncErrors(async (req, res) => {
    const rawFridges = await Fridge.findOnlyDeleted({});
    const fridgesWithStats = await Promise.all(
        rawFridges.map(f => computeFridgeStats(f._id))
    );

    res.status(200).json({
        success: true,
        count: fridgesWithStats.length,
        fridges: fridgesWithStats.filter(Boolean),
    });
});

// Create fridge => /api/v1/fridges
exports.createFridge = catchAsyncErrors(async (req, res, next) => {
    const { name, fridgeType } = req.body;
    if (!name || !fridgeType) {
        return next(new ErrorHandler('Refrigerator name and type are required', 400));
    }

    const fridge = await Fridge.create({
        name: name.trim(),
        fridgeType: fridgeType.trim(),
    });

    await AuditLog.create({
        action: 'CREATE_FRIDGE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Fridge',
        targetId: fridge._id,
        details: { name: fridge.name, fridgeType: fridge.fridgeType },
    });

    const stats = await computeFridgeStats(fridge._id);

    res.status(201).json({
        success: true,
        fridge: stats,
    });
});

// Get specific fridge details => /api/v1/fridge/:id
exports.getFridgeDetails = catchAsyncErrors(async (req, res, next) => {
    const stats = await computeFridgeStats(req.params.id);
    if (!stats) {
        return next(new ErrorHandler(`Refrigerator not found with ID: ${req.params.id}`, 404));
    }

    res.status(200).json({
        success: true,
        fridge: stats,
    });
});

// Update fridge => /api/v1/fridge/:id
exports.updateFridge = catchAsyncErrors(async (req, res, next) => {
    const { name, fridgeType } = req.body;
    const fridge = await Fridge.findById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler(`Refrigerator not found with ID: ${req.params.id}`, 404));
    }

    if (name) fridge.name = name.trim();
    if (fridgeType) fridge.fridgeType = fridgeType.trim();
    await fridge.save();

    await AuditLog.create({
        action: 'UPDATE_FRIDGE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Fridge',
        targetId: fridge._id,
        details: { name: fridge.name, fridgeType: fridge.fridgeType },
    });

    const stats = await computeFridgeStats(fridge._id);

    res.status(200).json({
        success: true,
        fridge: stats,
    });
});

// Delete fridge => /api/v1/fridge/:id
exports.deleteFridge = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.findById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler(`Refrigerator not found with ID: ${req.params.id}`, 404));
    }

    // Rule: Delete is blocked while a fridge still holds entries
    const holdingCount = await Inventory.countDocuments({ fridge: fridge._id, isDeleted: false });
    if (holdingCount > 0) {
        return next(new ErrorHandler(
            `Cannot delete refrigerator "${fridge.name}". It currently holds ${holdingCount} active entries. Please move or remove them first.`,
            400
        ));
    }

    await fridge.deleteOne();

    await AuditLog.create({
        action: 'DELETE_FRIDGE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Fridge',
        targetId: fridge._id,
        details: { name: fridge.name },
    });

    res.status(200).json({
        success: true,
        message: 'Refrigerator deleted successfully',
    });
});

// Soft Delete (Archive) fridge => /api/v1/fridge/:id/soft-delete
exports.softDeleteFridge = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.softDeleteById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler('Refrigerator not found', 404));
    }

    await AuditLog.create({
        action: 'ARCHIVE_FRIDGE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Fridge',
        targetId: fridge._id,
    });

    res.status(200).json({
        success: true,
        fridge,
    });
});

// Restore fridge => /api/v1/fridge/:id/restore
exports.restoreFridge = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.restoreById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler('Archived refrigerator not found', 404));
    }

    await AuditLog.create({
        action: 'RESTORE_FRIDGE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Fridge',
        targetId: fridge._id,
    });

    res.status(200).json({
        success: true,
        fridge,
    });
});

// Get Fridge Entries (detail screen entries list) => /api/v1/fridge/:id/entries
exports.getFridgeEntries = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.findById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler('Refrigerator not found', 404));
    }

    const { status, search, isArchived } = req.query;

    const query = { fridge: fridge._id };
    if (fridge.fridgeType === 'Unpasteurized') {
        query.isPasteurized = { $ne: true };
        query.status = { $ne: 'Pasteurized' };
        query.volume = { $gt: 0 };
    }
    if (isArchived === 'true') {
        query.isDeleted = true;
    } else {
        query.isDeleted = false;
    }

    const entries = await Inventory.find(query)
        .populate('user', 'name email')
        .populate({
            path: 'unpasteurizedDetails.collectionId',
            populate: { path: 'privDetails' }
        })
        .sort({ expiration: 1 }); // Sort by Expiration Date, earliest first

    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const formatted = entries.map(item => {
        const exp = item.expiration || item.unpasteurizedDetails?.expiration || item.pasteurizedDetails?.expiration;
        const isExp = exp && new Date(exp) < now;
        const isNear = exp && new Date(exp) >= now && new Date(exp) <= sevenDaysFromNow;

        // Extract donor name
        let donorName = item.donorName;
        if (!donorName && item.unpasteurizedDetails?.collectionId?.privDetails?.donorName) {
            donorName = item.unpasteurizedDetails.collectionId.privDetails.donorName;
        }
        if (!donorName && item.donorNames?.length > 0) {
            donorName = item.donorNames.join(', ');
        }

        return {
            ...item.toObject(),
            donorName: donorName || 'Unknown Donor',
            expiration: exp,
            isExpired: isExp,
            isNearExpiry: isNear,
            isPasteurizable: !isExp && item.status !== 'Unavailable' && item.volume > 0,
        };
    });

    // Optional search filter
    let results = formatted;
    if (search) {
        const q = search.toLowerCase();
        results = results.filter(e =>
            (e.donorName && e.donorName.toLowerCase().includes(q)) ||
            (e.batchNumber && e.batchNumber.toString().includes(q)) ||
            (e.poolNumber && e.poolNumber.toString().includes(q))
        );
    }

    res.status(200).json({
        success: true,
        count: results.length,
        entries: results,
    });
});

exports.openFridge = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.findById(req.params.id);
    if (!fridge) {
        return next(new ErrorHandler('Refrigerator not found', 404));
    }
    res.status(200).json({ success: true, message: 'Fridge lock opened' });
});
