const Donor = require("../models/donor");
const Letting = require("../models/letting");
const Schedule = require("../models/schedule");
const Collection = require("../models/collection");
const Bag = require("../models/bags");
const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");

// Record Public Donation after Milk Letting
exports.recordPublicDonation = catchAsyncErrors(async (req, res, next) => {
  const { lettingId } = req.body;

  try {
    const milkLetting = await Letting.findById(lettingId).populate(
      "attendance.donor"
    );
    if (!milkLetting) {
      return next(
        new ErrorHandler(`Milk Letting Event not found with ID: ${lettingId}`)
      );
    }

    const donorIds = milkLetting.attendance.map((att) => att.donor);

    const result = await Donor.updateMany(
      { _id: { $in: donorIds } },
      {
        $push: {
          donations: {
            donationType: "Public",
            milkLettingEvent: lettingId,
          },
        },
      }
    );

    if (result.matchedCount === 0) {
      return next(new ErrorHandler("No matching donors found for this event."));
    }

    res.status(200).json({
      success: true,
      message: 'Donation recorded successfully',
      updatedDonors: result.modifiedCount
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to record donation',
      details: error.message
    });
  }
});

// Record Private Donation after Schedule Approval
exports.recordPrivateDonation = catchAsyncErrors(async (req, res, next) => {
  const { donorId, scheduleId, collectionId } = req.body;

  try {
    const donor = await Donor.findById(donorId);
    if (!donor) return res.status(404).json({ error: "Donor not found" });

    const schedule = await Schedule.findById(scheduleId);
    if (!schedule) return res.status(404).json({ error: "Schedule not found" });

    const collection = await Collection.findById(collectionId);
    if (!collection)
      return res.status(404).json({ error: "collection not found" });

    donor.donations.push({
      donationType: "Private",
      schedule: scheduleId,
    });

    schedule.status = "Completed";


    await Bag.updateMany(
      { _id: { $in: schedule.donorDetails.bags } },
      { $set: { status: "Collected" } }
    );

    await donor.save();
    await schedule.save();
    await collection.save();

    res.status(200).json({ message: "Donation recorded successfully", donor });
  } catch (error) {
    res.status(500).json({ error: "Failed to record donation", details: error.message });
  }
});

exports.getCollections = catchAsyncErrors(async (req, res, next) => {
  try {
    const { search, type } = req.query;

    const regexType = type ? new RegExp(type, 'i') : /.*/; // Match all if type is not specified
    const matchStage = { collectionType: { $regex: regexType } };

    const pipeline = [
      { $match: matchStage },

      // Lookup pubDetails → Letting
      {
        $lookup: {
          from: 'lettings',
          localField: 'pubDetails',
          foreignField: '_id',
          as: 'pubDetails'
        }
      },
      { $unwind: { path: '$pubDetails', preserveNullAndEmptyArrays: true } },

      // Lookup privDetails → Schedule
      {
        $lookup: {
          from: 'schedules',
          localField: 'privDetails',
          foreignField: '_id',
          as: 'privDetails'
        }
      },
      { $unwind: { path: '$privDetails', preserveNullAndEmptyArrays: true } },

      // Lookup privDetails.donorDetails.donorId → Donor
      {
        $lookup: {
          from: 'donors',
          localField: 'privDetails.donorDetails.donorId',
          foreignField: '_id',
          as: 'privDetails.donorDetails.donor'
        }
      },
      { $unwind: { path: '$privDetails.donorDetails.donor', preserveNullAndEmptyArrays: true } },


      // Lookup donor.user → User
      {
        $lookup: {
          from: 'users',
          localField: 'privDetails.donorDetails.donor.user',
          foreignField: '_id',
          as: 'privDetails.donorDetails.donor.user'
        }
      },
      { $unwind: { path: '$privDetails.donorDetails.donor.user', preserveNullAndEmptyArrays: true } },

    ];

    // Only add the $match for search if a search query is present
    if (search) {
      const regexQuery = new RegExp(search, 'i');
      pipeline.push({
        $match: {
          $or: [
            { 'pubDetails.activity': { $regex: regexQuery } },
            { 'donorUser.name.firstName': { $regex: regexQuery } },
            { 'donorUser.name.lastName': { $regex: regexQuery } },
          ]
        }
      });
    }

    // Add sort stage
    pipeline.push({ $sort: { collectionDate: -1 } });

    const collections = await Collection.aggregate(pipeline);

    res.status(200).json({
      success: true,
      count: collections.length,
      collections
    })
  }
  catch (error) {
    res.status(500).json({ error: 'Failed to retrieve collections', message: error.message });
  }
})

// Get specific collection details => /api/v1/collection/:id
exports.getCollectionDetails = catchAsyncErrors(async (req, res, next) => {
  const collection = await Collection.findById(req.params.id)
    .populate({
      path: "pubDetails",
      select: "totalVolume attendance.bags",
      populate: {
        path: "attendance.bags",
        select: "expressDate volume",
      },
    })
    .populate({
      path: "privDetails",
      select: "totalVolume dateRange dates startDate endDate startTime endTime time donorName pickupAddress address contactNumber donorDetails.bags",
      populate: {
        path: "donorDetails.bags",
        select: "expressDate volume",
      },
    });

  if (!collection) {
    return next(
      new ErrorHandler(`Collection is not found with this id: ${req.params.id}`)
    );
  }

  res.status(200).json({
    success: true,
    collection,
  });
});

// Get All Collection => /api/v1/collections
exports.allCollections = catchAsyncErrors(async (req, res, next) => {
  const { isArchived, status, search, startDate, endDate } = req.query;

  const query = {};
  if (isArchived === 'true') {
    // Handled below via findOnlyDeleted
  } else {
    query.isDeleted = false;
  }
  if (status) {
    query.status = status;
  }
  if (startDate && endDate) {
    query.collectionDate = {
      $gte: new Date(startDate),
      $lte: new Date(endDate)
    };
  }

  let collectionsQuery = isArchived === 'true'
    ? Collection.findOnlyDeleted(query)
    : Collection.find(query);

  const rawCollections = await collectionsQuery
    .sort({ collectionDate: -1 })
    .populate({
      path: "pubDetails",
      select: "totalVolume attendance.bags",
      populate: {
        path: "attendance.bags",
        select: "expressDate volume",
      },
    })
    .populate({
      path: "privDetails",
      select: "totalVolume dateRange dates startDate endDate startTime endTime time donorName pickupAddress address contactNumber donorDetails.donorId donorDetails.bags",
      populate: [
        {
          path: "donorDetails.donorId",
          select: "user home_address age birthday",
          populate: {
            path: "user",
            select: "name email",
          },
        },
        {
          path: "donorDetails.bags",
          select: "expressDate volume",
        },
      ],
    });

  let collections = rawCollections;
  if (search) {
    const q = search.toLowerCase();
    collections = rawCollections.filter(c => {
      const donorName = c.privDetails?.donorName || c.privDetails?.donorDetails?.donorId?.user?.name || '';
      return donorName.toLowerCase().includes(q);
    });
  }

  res.status(200).json({
    success: true,
    count: collections.length,
    collections,
  });
});

// Update Collection => /api/v1/collection/:id
exports.updateCollection = catchAsyncErrors(async (req, res, next) => {
  const { collectionDate, status, volume, reasonForCorrection } = req.body;
  const collection = await Collection.findById(req.params.id);
  if (!collection) {
    return next(new ErrorHandler("Collection record not found", 404));
  }

  const beforeVol = collection.volume || 0;
  if (collectionDate) collection.collectionDate = new Date(collectionDate);
  if (status) collection.status = status;
  if (volume !== undefined) collection.volume = Math.round(Number(volume));
  if (reasonForCorrection) collection.reasonForCorrection = reasonForCorrection.trim();

  await collection.save();

  // If volume was corrected, update corresponding inventory entry
  if (volume !== undefined && collection.privDetails) {
    const inv = await Inventory.findOne({ "unpasteurizedDetails.collectionId": collection._id });
    if (inv) {
      const invBefore = inv.volume;
      inv.volume = Math.round(Number(volume));
      inv.reasonForChange = reasonForCorrection || 'Volume corrected in Collections';
      await inv.save();

      await AuditLog.create({
        action: 'UPDATE_COLLECTION',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Collection',
        targetId: collection._id,
        beforeVolume: invBefore,
        afterVolume: inv.volume,
        volumeChanged: inv.volume - invBefore,
        reason: reasonForCorrection || 'Volume correction'
      });
    }
  }

  res.status(200).json({
    success: true,
    collection,
  });
});

// Soft Delete (Archive) Collection => /api/v1/collection/:id/soft-delete
exports.softDeleteCollection = catchAsyncErrors(async (req, res, next) => {
  const collection = await Collection.softDeleteById(req.params.id);
  if (!collection) {
    return next(new ErrorHandler("Collection record not found", 404));
  }

  await AuditLog.create({
    action: 'ARCHIVE_COLLECTION',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Collection',
    targetId: collection._id,
    reason: 'Archived collection record (Milk remains in refrigerator)'
  });

  res.status(200).json({
    success: true,
    collection,
  });
});

// Restore Collection => /api/v1/collection/:id/restore
exports.restoreCollection = catchAsyncErrors(async (req, res, next) => {
  const collection = await Collection.restoreById(req.params.id);
  if (!collection) {
    return next(new ErrorHandler("Archived collection record not found", 404));
  }

  await AuditLog.create({
    action: 'RESTORE_COLLECTION',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Collection',
    targetId: collection._id,
    reason: 'Restored collection record'
  });

  res.status(200).json({
    success: true,
    collection,
  });
});

// Delete Collection permanently => /api/v1/collection/:id
exports.deleteCollection = catchAsyncErrors(async (req, res, next) => {
  const collection = await Collection.findById(req.params.id);
  if (!collection) {
    return next(new ErrorHandler("Collection record not found", 404));
  }

  await collection.deleteOne();

  res.status(200).json({
    success: true,
    message: "Collection record deleted permanently",
  });
});

