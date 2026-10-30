const Inventory = require('../models/inventory2');
const Fridge = require('../models/fridge');
const Bag = require('../models/bags');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const ErrorHandler = require('../utils/errorHandler');
const Donor = require('../models/donor');




// Get All Patients => /api/v1/inventories
exports.allInventories = catchAsyncErrors(async (req, res, next) => {
    const inventories = await Inventory.find().populate('fridge').populate('unpasteurizedDetails.donor');

    res.status(200).json({
        success: true,
        count: inventories.length,
        inventories,
    });
});

// Create inventory => /api/v1/inventories
exports.createInventory = catchAsyncErrors(async (req, res, next) => {
    const { fridgeId, userId, pasteurizedDetails, unpasteurizedDetails, inventoryDate, status } = req.body;
    
    // Validate fridge
    const fridge = await Fridge.findById(fridgeId);
    if (!fridge) {
        return next(new ErrorHandler('Refrigerator not found', 404));
    }

    if (!fridgeId || !inventoryDate || !userId || !status) {
        return next(new ErrorHandler('Please fill out the required details', 400));
    }

    const inventoryData = { fridge: fridgeId, inventoryDate, user: userId, status: status };

    if (fridge.fridgeType === 'Pasteurized') {
        if (!pasteurizedDetails || !pasteurizedDetails.pasteurizationDate || !pasteurizedDetails.batch ||
            !pasteurizedDetails.pool || !pasteurizedDetails.bottle || !pasteurizedDetails.volume || !pasteurizedDetails.expiration) {
            return next(new ErrorHandler('Pasteurized fridge requires complete pasteurizedDetails', 400));
        }

        inventoryData.pasteurizedDetails = pasteurizedDetails;

    } else if (fridge.fridgeType === 'Unpasteurized') {
        if (!unpasteurizedDetails || !unpasteurizedDetails.donor || !unpasteurizedDetails.expressDate ||
            !unpasteurizedDetails.collectionDate || !unpasteurizedDetails.volume) {
            return next(new ErrorHandler('Unpasteurized fridge requires complete unpasteurizedDetails', 400));
        }

        inventoryData.unpasteurizedDetails = unpasteurizedDetails;

        } else {
            return next(new ErrorHandler('Invalid fridge type', 400));
        }

    const inventory = await Inventory.create(inventoryData);

    res.status(201).json({
        success: true,
        inventory,
    });
});

// Get specific Inventory details => /api/v1/inventory/:id
exports.getInventoryDetails = catchAsyncErrors(async (req, res, next) => {
    const inventory = await Inventory.findById(req.params.id)
        .populate('fridge')
        .populate('unpasteurizedDetails.donor');

    if (!inventory) {
        return next(new ErrorHandler('Inventory not found', 404));
    }

    res.status(200).json({
        success: true,
        inventory,
    });
});

// Update Inventory details => /api/v1/inventory/:id
exports.updateInventory = catchAsyncErrors(async (req, res, next) => {
    const { pasteurizedDetails, unpasteurizedDetails, inventoryDate, status, temp } = req.body;

    const inventory = await Inventory.findById(req.params.id).populate('fridge');

    if (!inventory) {
        return next(new ErrorHandler('Inventory not found', 404));
    }

    const fridge = inventory.fridge;

    // Update inventory date
    if (inventoryDate) {
        inventory.inventoryDate = inventoryDate;
    }

    if (status) {
        inventory.status = status;
    }

    if (temp) {
        inventory.temp = temp;
    }
    console.log("Inventory Data: ",inventory)
    // Validation of Updating based on fridge type
    if (fridge.fridgeType === 'Pasteurized') {
        if (!pasteurizedDetails || !pasteurizedDetails.pasteurizationDate || !pasteurizedDetails.batch || 
            !pasteurizedDetails.pool || !pasteurizedDetails.bottle || !pasteurizedDetails.expiration) {
            return next(new ErrorHandler('Pasteurized fridge requires complete pasteurizedDetails.', 400));
        }

    } else if (fridge.fridgeType === 'Unpasteurized') {
        if (!unpasteurizedDetails || !unpasteurizedDetails.donor || !unpasteurizedDetails.expressDate || 
            !unpasteurizedDetails.collectionDate || !unpasteurizedDetails.volume) {
            return next(new ErrorHandler('Unpasteurized fridge requires complete unpasteurizedDetails.', 400));
        }

    } else {
        return next(new ErrorHandler('Invalid fridge type', 400));
    }

    // await fridge.save(); // Save fridge updates
    await inventory.save(); // Save inventory updates

    res.status(200).json({
        success: true,
        inventory,
    });
});

// Delete Inventory details => /api/v1/inventory/:id
exports.deleteInventory = catchAsyncErrors(async (req, res, next) => {
    const inventory = await Inventory.findById(req.params.id);

    if (!inventory) {
        return next(new ErrorHandler('Inventory not found', 404));
    }

    await inventory.deleteOne();

    res.status(200).json({
        success: true,
        message: 'Inventory deleted successfully',
    });
});
