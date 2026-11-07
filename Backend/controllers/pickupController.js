const PickupRequest = require('../models/pickup');
const Donor = require('../models/donor');
const Notification = require('../models/notification');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');

// 5 Approved Pasig City Human Milk Bank Collection Outposts
const PASIG_COLLECTION_OUTPOSTS = [
    {
        outpostId: 'OUTPOST-1',
        outpostName: 'Pasig City Central Station (PCGH Complex)',
        barangaysCovered: ['San Nicolas', 'Malinao', 'Santa Cruz', 'Kapasigan', 'San Jose'],
        contactPhone: '(02) 8643-0000',
        active: true
    },
    {
        outpostId: 'OUTPOST-2',
        outpostName: 'Pinagbuhatan Outpost Health Center',
        barangaysCovered: ['Pinagbuhatan', 'Palatiw', 'San Miguel'],
        contactPhone: '(02) 8642-1111',
        active: true
    },
    {
        outpostId: 'OUTPOST-3',
        outpostName: 'Manggahan - Santolan District Station',
        barangaysCovered: ['Manggahan', 'Santolan', 'De La Paz', 'Rosario'],
        contactPhone: '(02) 8642-2222',
        active: true
    },
    {
        outpostId: 'OUTPOST-4',
        outpostName: 'Ugong - Oranbo Western Outpost',
        barangaysCovered: ['Ugong', 'Oranbo', 'Pineda', 'Bagong Ilog', 'Kapitolyo', 'San Antonio'],
        contactPhone: '(02) 8642-3333',
        active: true
    },
    {
        outpostId: 'OUTPOST-5',
        outpostName: 'Caniogan - Maybunga Eastern Station',
        barangaysCovered: ['Caniogan', 'Maybunga', 'Sagad', 'Bagong Katipunan', 'Sumilang', 'Bambang', 'Kalawaan', 'Santa Lucia', 'Santa Rosa'],
        contactPhone: '(02) 8642-4444',
        active: true
    }
];

// Helper to recommend best outpost based on barangay
function recommendOutpostForBarangay(barangay) {
    if (!barangay) return PASIG_COLLECTION_OUTPOSTS[0];
    const match = PASIG_COLLECTION_OUTPOSTS.find(o =>
        o.barangaysCovered.some(b => b.toLowerCase() === barangay.trim().toLowerCase())
    );
    return match || PASIG_COLLECTION_OUTPOSTS[0];
}

// Get Outposts List => /api/v1/pickup/outposts
exports.getCollectionOutposts = catchAsyncErrors(async (req, res, next) => {
    res.status(200).json({
        success: true,
        count: PASIG_COLLECTION_OUTPOSTS.length,
        outposts: PASIG_COLLECTION_OUTPOSTS
    });
});

// Create Pickup Request (Eligible Donors) => /api/v1/pickup/request
exports.createPickupRequest = catchAsyncErrors(async (req, res, next) => {
    const {
        barangay,
        pickupAddress,
        coordinates,
        preferredDate,
        preferredTimeSlot,
        estimatedBags,
        estimatedVolumeMl,
        contactNumber,
        donorNotes,
        selectedOutpostId
    } = req.body;

    if (!barangay || !pickupAddress || !preferredDate || !preferredTimeSlot || !contactNumber) {
        return next(new ErrorHandler('Please complete all required pickup details', 400));
    }

    // Identify donor
    let donor;
    if (req.user) {
        donor = await Donor.findOne({ user: req.user._id, isDeleted: false });
    }
    if (!donor && req.body.donorId) {
        donor = await Donor.findOne({ _id: req.body.donorId, isDeleted: false });
    }

    if (!donor) {
        return next(new ErrorHandler('Registered donor profile required to schedule milk pickup', 404));
    }

    // Verify donor eligibility before allowing pickup scheduling
    if (donor.eligibility !== 'Eligible') {
        return next(new ErrorHandler(
            `Milk pickup scheduling is restricted to eligible donors. Your current status is "${donor.eligibility}". Please complete hospital screening first.`,
            403
        ));
    }

    // Recommendation logic
    let chosenOutpost = recommendOutpostForBarangay(barangay);
    if (selectedOutpostId) {
        const found = PASIG_COLLECTION_OUTPOSTS.find(o => o.outpostId === selectedOutpostId);
        if (found) chosenOutpost = found;
    }

    const pickupCount = await PickupRequest.countDocuments();
    const pickupId = `PICK-${new Date().getFullYear()}-${String(pickupCount + 1).padStart(4, '0')}`;

    const newPickup = await PickupRequest.create({
        pickupId,
        donor: donor._id,
        user: req.user ? req.user._id : donor.user,
        barangay: barangay.trim(),
        pickupAddress: pickupAddress.trim(),
        coordinates: coordinates || {},
        preferredDate: new Date(preferredDate),
        preferredTimeSlot,
        estimatedBags: Number(estimatedBags) || 1,
        estimatedVolumeMl: estimatedVolumeMl ? Number(estimatedVolumeMl) : null,
        contactNumber: contactNumber.trim(),
        donorNotes: donorNotes || '',
        assignedOutpost: {
            outpostId: chosenOutpost.outpostId,
            outpostName: chosenOutpost.outpostName,
            serviceArea: chosenOutpost.barangaysCovered.join(', ')
        },
        status: 'Pending',
        statusHistory: [
            {
                status: 'Pending',
                timestamp: new Date(),
                comment: 'Pickup request submitted by donor. Awaiting staff collection scheduling.'
            }
        ],
        audit: {
            createdBy: req.user ? req.user._id : null
        }
    });

    res.status(201).json({
        success: true,
        message: 'Milk pickup request submitted successfully. Our outpost team will review schedule.',
        pickupId: newPickup.pickupId,
        assignedOutpost: newPickup.assignedOutpost,
        pickup: newPickup
    });
});

// Get Donor Pickup History => /api/v1/pickup/my-history
exports.getMyPickupHistory = catchAsyncErrors(async (req, res, next) => {
    let donorId;
    if (req.user) {
        const donor = await Donor.findOne({ user: req.user._id });
        if (donor) donorId = donor._id;
    }

    const query = donorId ? { donor: donorId, isDeleted: false } : { user: req.user?._id, isDeleted: false };
    const pickups = await PickupRequest.find(query)
        .sort({ createdAt: -1 });

    res.status(200).json({
        success: true,
        count: pickups.length,
        pickups
    });
});

// Staff Update Pickup Status => /api/v1/pickup/:id/status
exports.updatePickupStatus = catchAsyncErrors(async (req, res, next) => {
    const { status, comment, bagsCollected, volumeCollectedMl, batchReference } = req.body;
    const allowed = ['Pending', 'Assigned', 'On the Way', 'Arrived', 'Collected', 'Rescheduled', 'Cancelled'];

    if (!allowed.includes(status)) {
        return next(new ErrorHandler(`Invalid status. Must be one of: ${allowed.join(', ')}`, 400));
    }

    const pickup = await PickupRequest.findById(req.params.id).populate('donor');
    if (!pickup) {
        return next(new ErrorHandler('Pickup request not found', 404));
    }

    pickup.status = status;
    pickup.statusHistory.push({
        status,
        timestamp: new Date(),
        updatedBy: req.user?._id,
        comment: comment || `Status updated to ${status}`
    });

    if (status === 'Collected') {
        pickup.collectedDonationRecord = {
            bagsCollected: Number(bagsCollected) || pickup.estimatedBags,
            volumeCollectedMl: Number(volumeCollectedMl) || (pickup.estimatedVolumeMl || 0),
            collectedAt: new Date(),
            batchReference: batchReference || `PICK-BATCH-${Date.now().toString().slice(-6)}`
        };

        // Also append directly to donor's permanent donation history
        if (pickup.donor) {
            pickup.donor.donations.push({
                donationType: 'Public',
                totalVolume: pickup.collectedDonationRecord.volumeCollectedMl,
                numberOfBags: pickup.collectedDonationRecord.bagsCollected,
                collectionDate: new Date(),
                batchReference: pickup.collectedDonationRecord.batchReference,
                status: 'Collected',
                recordedBy: req.user?._id,
                notes: `Collected via home pickup ${pickup.pickupId}`
            });
            await pickup.donor.save();
        }
    }

    if (pickup.audit) {
        pickup.audit.updatedBy = req.user?._id;
    }
    await pickup.save();

    res.status(200).json({
        success: true,
        message: `Pickup status updated to '${status}'`,
        pickup
    });
});

// Staff All Pickups List => /api/v1/staff/pickups
exports.getAllPickups = catchAsyncErrors(async (req, res, next) => {
    const { status, outpost } = req.query;
    const filter = { isDeleted: false };
    if (status) filter.status = status;
    if (outpost) filter['assignedOutpost.outpostId'] = outpost;

    const pickups = await PickupRequest.find(filter)
        .sort({ preferredDate: 1 })
        .populate('donor', 'donorId name contact_number eligibility');

    res.status(200).json({
        success: true,
        count: pickups.length,
        pickups
    });
});
