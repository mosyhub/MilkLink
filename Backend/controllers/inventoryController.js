const Inventory = require("../models/inventory");
const Request = require("../models/request");
const Fridge = require("../models/fridge");
const Collection = require("../models/collection");
const Schedule = require("../models/schedule");
const Letting = require("../models/letting");
const Bags = require("../models/bags");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const ErrorHandler = require("../utils/errorHandler");

// Get All Patients => /api/v1/inventories
exports.allInventories = catchAsyncErrors(async (req, res, next) => {
  const inventories = await Inventory.find({ status: "Available" })
    .populate("fridge")
    .populate({
      path: "unpasteurizedDetails.collectionId",
      select: "collectionType pubDetails privDetails collectionDate",
      populate: [
        {
          path: "pubDetails",
          select: "attendance totalVolume actDetails",
          populate: {
            path: "attendance.bags attendance.donor",
          },
        },
        {
          path: "privDetails",
          select: "donorDetails totalVolume dates",
          populate: {
            path: "donorDetails.bags donorDetails.donorId",
          },
        },
      ],
    });

  res.status(200).json({
    success: true,
    count: inventories.length,
    inventories,
  });
});

// Create inventory => /api/v1/inventories
exports.createInventory = catchAsyncErrors(async (req, res, next) => {
  const { fridgeId, userId, pasteurizedDetails, unpasteurizedDetails } =
    req.body;

  // Validate fridge
  const fridge = await Fridge.findById(fridgeId);
  if (!fridge) {
    return next(new ErrorHandler("Refrigerator not found", 404));
  }

  if (!fridgeId || !userId) {
    return next(new ErrorHandler("Please fill out the required details", 400));
  }

  const inventoryData = { fridge: fridgeId, user: userId };

  if (fridge.fridgeType === "Pasteurized") {
    console.log("This is where I go in pasteur");
    if (
      !pasteurizedDetails ||
      !pasteurizedDetails.pasteurizationDate ||
      !pasteurizedDetails.batch ||
      !pasteurizedDetails.pool ||
      !pasteurizedDetails.bottleType ||
      !pasteurizedDetails.bottleQty ||
      !pasteurizedDetails.donors
    ) {
      return next(
        new ErrorHandler(
          "Pasteurized fridge requires complete pasteurizedDetails",
          400
        )
      );
    }
    const expiration = new Date(pasteurizedDetails.pasteurizationDate);
    expiration.setDate(expiration.getDate() + 183);
    const batchVolume =
      pasteurizedDetails.bottleType * pasteurizedDetails.bottleQty;
    const pastDetails = {
      ...pasteurizedDetails,
      batchVolume: batchVolume,
      expiration: expiration.getTime(),
    };
    inventoryData.pasteurizedDetails = pastDetails;




  } else if (fridge.fridgeType === "Unpasteurized") {
    if (!unpasteurizedDetails || !unpasteurizedDetails.collectionId) {
      return next(
        new ErrorHandler(
          "Unpasteurized fridge requires complete unpasteurizedDetails",
          400
        )
      );
    }

    const unpast = {
      collectionId: unpasteurizedDetails.collectionId,
    };

    const collection = await Collection.findById(
      unpasteurizedDetails.collectionId
    );

    if (collection.pubDetails) {
      const letting = await Letting.findById(collection.pubDetails).populate({
        path: "attendance.bags",
        select: "expressDate"
      })
        .populate({
          path: "attendance.additionalBags",
          select: "expressDate"
        });
      if (!letting) {
        return next(new ErrorHandler("Letting not found", 404));
      }
      if (letting) {
        // Extract and flatten all bags and additionalBags from attendance
        const allBags = letting.attendance.flatMap(att => [
          ...(att.bags || []),
          ...(att.additionalBags || [])
        ]);

        // Filter out any objects without expressDate
        const validBags = allBags.filter(bag => bag.expressDate);

        // Sort by expressDate
        validBags.sort((a, b) => new Date(a.expressDate) - new Date(b.expressDate));

        // Get earliest and latest expressDate
        unpast.expressDateStart = earliestExpressDate = validBags.length > 0 ? validBags[0].expressDate : null;
        unpast.expressDateEnd = latestExpressDate = validBags.length > 0 ? validBags[validBags.length - 1].expressDate : null;

      }
      const expiration = new Date(earliestExpressDate);
      expiration.setDate(expiration.getDate() + 14);

      unpast.expiration = expiration.getTime();


    } else if (collection.privDetails) {
      const schedule = await Schedule.findById(collection.privDetails);
      if (!schedule) {
        return next(new ErrorHandler("Schedule not found", 404));
      }
      // Retrieve bags linked to the donor in the schedule
      const bags = await Bags.find({ donor: schedule.donorDetails.donorId });

      if (!bags || bags.length === 0) {
        return next(new ErrorHandler("No bags found for this donor.", 404));
      }

      // Sort bags to find the oldest and newest expressDate
      const expressStartDate = bags.reduce(
        (oldest, bag) => (bag.expressDate < oldest ? bag.expressDate : oldest),
        bags[0].expressDate
      );

      const expressEndDate = bags.reduce(
        (latest, bag) => (bag.expressDate > latest ? bag.expressDate : latest),
        bags[0].expressDate
      );
      unpast.expressDateStart = expressStartDate;
      unpast.expressDateEnd = expressEndDate;

      const expiration = new Date(expressStartDate);
      expiration.setDate(expiration.getDate() + 14);

      unpast.expiration = expiration.getTime();
    } else {
      return next(new ErrorHandler("No public or private details", 400));
    }
    collection.status = "Stored";
    await collection.save();
    inventoryData.unpasteurizedDetails = unpast;
    await Collection.findByIdAndUpdate(unpasteurizedDetails.collectionId, { $set: { status: "Stored" } }, { new: true });
  } else {
    return next(new ErrorHandler("Invalid fridge type", 400));
  }

  const inventory = await Inventory.create(inventoryData);

  if (fridge.fridgeType === "Pasteurized" && pasteurizedDetails) {
    const updateBagsPromise = Bags.updateMany(
      { _id: { $in: pasteurizedDetails.items } },
      { $set: { status: "Pasteurized" } }
    );

    const bottleDetails = Array.from(
      { length: pasteurizedDetails.bottleQty },
      (_, i) => ({
        bottleNumber: i + 1,
        status: "Available",
      })
    );
    inventory.pasteurizedDetails.bottles.push(...bottleDetails);

    await Promise.all([updateBagsPromise, inventory.save()]);
  }


  res.status(201).json({
    success: true,
    inventory,
  });
});

// Get specific Inventory details => /api/v1/inventory/:id
exports.getInventoryDetails = catchAsyncErrors(async (req, res, next) => {
  const inventory = await Inventory.findById(req.params.id)
    .populate("fridge")
    .populate("unpasteurizedDetails");

  if (!inventory) {
    return next(new ErrorHandler("Inventory not found", 404));
  }

  res.status(200).json({
    success: true,
    inventory,
  });
});

// Update Inventory details => /api/v1/inventory/:id
exports.updateInventory = catchAsyncErrors(async (req, res, next) => {
  const {
    pasteurizedDetails,
    unpasteurizedDetails,
    inventoryDate,
    status,
    temp,
  } = req.body;

  const inventory = await Inventory.findById(req.params.id).populate("fridge");

  if (!inventory) {
    return next(new ErrorHandler("Inventory not found", 404));
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
  console.log("Inventory Data: ", inventory);
  // Validation of Updating based on fridge type
  if (fridge.fridgeType === "Pasteurized") {
    if (
      !pasteurizedDetails ||
      !pasteurizedDetails.pasteurizationDate ||
      !pasteurizedDetails.batch ||
      !pasteurizedDetails.pool ||
      !pasteurizedDetails.bottle ||
      !pasteurizedDetails.expiration
    ) {
      return next(
        new ErrorHandler(
          "Pasteurized fridge requires complete pasteurizedDetails.",
          400
        )
      );
    }
  } else if (fridge.fridgeType === "Unpasteurized") {
    if (
      !unpasteurizedDetails ||
      !unpasteurizedDetails.donor ||
      !unpasteurizedDetails.expressDate ||
      !unpasteurizedDetails.collectionDate ||
      !unpasteurizedDetails.volume
    ) {
      return next(
        new ErrorHandler(
          "Unpasteurized fridge requires complete unpasteurizedDetails.",
          400
        )
      );
    }
  } else {
    return next(new ErrorHandler("Invalid fridge type", 400));
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
    return next(new ErrorHandler("Inventory not found", 404));
  }

  await inventory.deleteOne();

  res.status(200).json({
    success: true,
    message: "Inventory deleted successfully",
  });
});

// Update Inventory Status
exports.updateInventoryStatus = catchAsyncErrors(async (req, res, next) => {
  const { status } = req.body;

  try {
    const inventory = await Inventory.findById(req.params.id);
    if (!inventory) {
      return next(new ErrorHandler("Inventory not found", 404));
    }

    inventory.status = status;
    await inventory.save();

    res.status(200).json({
      success: true,
      message: "Inventory status updated successfully",
      data: inventory,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Reserve Inventory for Request => /api/v1/inventories/:id/reserve
exports.reserveInventoryForRequest = catchAsyncErrors(
  async (req, res, next) => {
    const { ebmData } = req.body;

    try {
      if (!Array.isArray(ebmData) || ebmData.length === 0) {
        return next(new ErrorHandler("EBM data are required.", 400));
      }

      for (const ebm of ebmData) {
        const { invId, bottle } = ebm;

        const inventory = await Inventory.findById(invId);
        if (!inventory) {
          return next(new ErrorHandler("Inventory not found", 404));
        }

        const { start, end } = bottle;

        // Update bottle statuses to Reserved within the selected range
        inventory.pasteurizedDetails.bottles =
          inventory.pasteurizedDetails.bottles.map((bot) => {
            if (
              bot.bottleNumber >= start &&
              bot.bottleNumber <= end &&
              bot.status === "Available"
            ) {
              return { ...bot.toObject(), status: "Reserved" };
            }
            return bot;
          });

        // Check if all bottles are now reserved
        const allReserved = inventory.pasteurizedDetails.bottles.every(
          (bot) => bot.status !== "Available"
        );

        if (allReserved) {
          inventory.status = "Reserved";
        }

        await inventory.save();
      }

      const updatedRequest = await Request.findByIdAndUpdate(
        req.params.id,
        { $push: { "milklink.ebm": { $each: ebmData } } },
        { new: true }
      );

      if (!updatedRequest) {
        return next(new ErrorHandler("Request not found.", 404));
      }

      updatedRequest.status = "Reserved";
      await updatedRequest.save();

      res.status(200).json({
        message: "Inventory updated and EBM added to request successfully.",
        updatedRequest,
      });
    } catch (error) {
      console.error("Error in reserving inventory for request:", error);
      res.status(500).json({ message: "Server error", error: error.message });
    }
  }
);

// Controller to check all inventories and update their status
exports.updateAllInventoriesStatus = catchAsyncErrors(
  async (req, res, next) => {
    try {
      const inventories = await Inventory.find({
        "unpasteurizedDetails.collectionId": { $exists: true },
      }).populate("unpasteurizedDetails.collectionId");

      let updatedCount = 0;
      for (const inventory of inventories) {
        const collection = inventory.unpasteurizedDetails.collectionId;
        let bags = [];

        if (collection.pubDetails) {
          const letting = await Letting.findById(
            collection.pubDetails
          ).populate("attendance.bags");
          if (letting) {
            bags = [
              ...letting.attendance.flatMap((attendee) => attendee.bags),
              ...letting.attendance.flatMap(
                (attendee) => attendee.additionalBags
              ),
            ];
          }
        } else if (collection.privDetails) {
          const schedule = await Schedule.findById(
            collection.privDetails
          ).populate("donorDetails.bags");
          if (schedule) {
            bags = schedule.donorDetails.bags;
          }
        }

        if (bags.length) {
          const allPasteurized = bags.every(
            (bag) => bag.status === "Pasteurized"
          );
          if (allPasteurized) {
            inventory.status = "Unavailable";
            console.log("Nagana here")
            await inventory.save();
            updatedCount++;
          }
        }
      }

      return res.status(200).json({
        message: `${updatedCount} inventories checked and updated successfully.`,
      });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  }
);

const AuditLog = require('../models/auditLog');

// Mutex lock for multi-record inventory changes
let inventoryMutex = Promise.resolve();
function withInventoryLock(fn) {
  return new Promise((resolve, reject) => {
    inventoryMutex = inventoryMutex.then(async () => {
      try {
        const result = await fn();
        resolve(result);
      } catch (err) {
        reject(err);
      }
    });
  });
}

// Pasteurization Endpoint => /api/v1/inventories/pasteurize
exports.pasteurize = catchAsyncErrors(async (req, res, next) => {
  return withInventoryLock(async () => {
    const {
      unpasteurizedFridgeId,
      pasteurizedFridgeId,
      selectedEntryIds,
      pasteurizationDate,
      batchNumber,
      poolNumber,
      bottleType,
      availableBottles
    } = req.body;

    if (!selectedEntryIds || !Array.isArray(selectedEntryIds) || selectedEntryIds.length === 0) {
      return next(new ErrorHandler("Select at least one unpasteurized entry", 400));
    }

    if (!pasteurizationDate || !batchNumber || !poolNumber || !bottleType || !availableBottles) {
      return next(new ErrorHandler("All pasteurization fields are required", 400));
    }

    // Pasteurization Date cannot be in the future
    const pDate = new Date(pasteurizationDate);
    const now = new Date();
    if (pDate > now) {
      return next(new ErrorHandler("Pasteurization Date cannot be in the future", 400));
    }

    const bTypeNum = Math.round(Number(bottleType));
    const bottlesCount = Math.round(Number(availableBottles));
    const batchNum = Math.round(Number(batchNumber));
    const poolNum = Math.round(Number(poolNumber));

    if (bTypeNum <= 0 || bottlesCount <= 0) {
      return next(new ErrorHandler("Bottle type and bottle count must be positive numbers", 400));
    }

    // Uniqueness of Batch Number and Pool Number
    const existingBatch = await Inventory.findOne({
      $or: [
        { batchNumber: batchNum },
        { "pasteurizedDetails.batch": batchNum }
      ]
    });
    if (existingBatch) {
      return next(new ErrorHandler(`Batch Number ${batchNum} is already in use. It must be unique.`, 400));
    }

    const existingPool = await Inventory.findOne({
      $or: [
        { poolNumber: poolNum },
        { "pasteurizedDetails.pool": poolNum }
      ]
    });
    if (existingPool) {
      return next(new ErrorHandler(`Pool Number ${poolNum} is already in use. It must be unique.`, 400));
    }

    // Verify unpasteurized fridge and entries
    const unpastFridge = await Fridge.findById(unpasteurizedFridgeId);
    const pastFridge = await Fridge.findById(pasteurizedFridgeId);
    if (!unpastFridge || !pastFridge) {
      return next(new ErrorHandler("Selected refrigerators not found", 404));
    }

    const entries = await Inventory.find({
      _id: { $in: selectedEntryIds },
      isDeleted: false
    });

    if (entries.length === 0) {
      return next(new ErrorHandler("Selected entries not found or already deleted", 404));
    }

    // Check none are expired
    for (const ent of entries) {
      const exp = ent.expiration || ent.unpasteurizedDetails?.expiration;
      if (exp && new Date(exp) < now) {
        return next(new ErrorHandler(`Entry from ${ent.donorName || 'donor'} is expired and cannot be pasteurized`, 400));
      }
    }

    // Total pooled volume
    const pooledVolume = entries.reduce((sum, e) => sum + Math.round(e.volume || 0), 0);
    const totalBottleVolume = bTypeNum * bottlesCount;

    if (totalBottleVolume > pooledVolume) {
      return next(new ErrorHandler(
        `Total bottle volume (${totalBottleVolume} ml) exceeds the pooled volume (${pooledVolume} ml). Available bottles: ${bottlesCount} x ${bTypeNum} ml = ${totalBottleVolume} ml.`,
        400
      ));
    }

    // Collect donor names from entries
    const donorNamesSet = new Set();
    for (const ent of entries) {
      if (ent.donorName) donorNamesSet.add(ent.donorName);
      if (ent.donorNames && Array.isArray(ent.donorNames)) {
        ent.donorNames.forEach(d => donorNamesSet.add(d));
      }
    }
    const donorNamesList = Array.from(donorNamesSet);

    // Subtract/deplete pooled volume from unpasteurized entries and remove from unpasteurized fridge
    for (const ent of entries) {
      const beforeVol = ent.volume;
      ent.volume = 0;
      ent.isPasteurized = true;
      ent.status = 'Pasteurized';
      ent.fridge = null; // Removed from unpasteurized fridge
      await ent.save();

      await AuditLog.create({
        action: 'PASTEURIZE',
        user: req.user?._id,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Inventory',
        targetId: ent._id,
        beforeVolume: beforeVol,
        afterVolume: 0,
        volumeChanged: -beforeVol,
        reason: `Pooled into Batch #${batchNum} (Pool #${poolNum})`
      });
    }

    // Expiration date is Pasteurization Date + 183 days (6 months)
    const expirationDate = new Date(pDate);
    expirationDate.setDate(expirationDate.getDate() + 183);

    // Create pasteurized batch in Pasteurized fridge
    const newBatch = await Inventory.create({
      fridge: pastFridge._id,
      user: req.user?._id,
      status: 'Available',
      volume: totalBottleVolume,
      batchNumber: batchNum,
      poolNumber: poolNum,
      bottleType: bTypeNum,
      availableBottles: bottlesCount,
      donorNames: donorNamesList,
      sourceEntries: selectedEntryIds,
      expiration: expirationDate,
      pasteurizedDetails: {
        pasteurizationDate: pDate,
        batch: batchNum,
        pool: poolNum,
        bottleType: bTypeNum,
        batchVolume: totalBottleVolume,
        expiration: expirationDate,
        bottles: Array.from({ length: bottlesCount }, (_, i) => ({
          bottleNumber: i + 1,
          status: 'Available'
        }))
      }
    });

    await AuditLog.create({
      action: 'PASTEURIZE',
      user: req.user?._id,
      userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
      targetType: 'Inventory',
      targetId: newBatch._id,
      beforeVolume: 0,
      afterVolume: totalBottleVolume,
      volumeChanged: totalBottleVolume,
      reason: `Created Pasteurized Batch #${batchNum} (Pool #${poolNum}) with ${bottlesCount} bottles of ${bTypeNum}ml`
    });

    res.status(201).json({
      success: true,
      message: `Batch #${batchNum} pasteurized successfully (${totalBottleVolume} ml created)`,
      batch: newBatch,
    });
  });
});

// FEFO Preview for milk request => /api/v1/inventories/fefo-preview
exports.getFefoPreview = catchAsyncErrors(async (req, res, next) => {
  const { volumeNeeded, bottlesNeeded, bottleType } = req.query;
  const now = new Date();

  const query = {
    isDeleted: false,
    status: 'Available',
    availableBottles: { $gt: 0 },
    expiration: { $gt: now }, // Never allocate expired batches
  };

  if (bottleType) {
    query.bottleType = Number(bottleType);
  }

  // Allocate earliest expiration first (FEFO)
  const candidateBatches = await Inventory.find(query)
    .populate('fridge')
    .sort({ expiration: 1 });

  let needed = volumeNeeded ? Number(volumeNeeded) : 0;
  const allocated = [];
  let totalAllocatedMl = 0;

  for (const b of candidateBatches) {
    if (needed <= 0 && volumeNeeded) break;
    const bType = b.bottleType || 100;
    const bAvailable = b.availableBottles || 0;
    const bVol = bAvailable * bType;

    let takeBottles = bAvailable;
    if (needed > 0) {
      takeBottles = Math.min(bAvailable, Math.ceil(needed / bType));
    }

    allocated.push({
      inventoryId: b._id,
      batchNumber: b.batchNumber,
      poolNumber: b.poolNumber,
      bottleType: bType,
      availableBottles: bAvailable,
      allocatedBottles: takeBottles,
      allocatedVolume: takeBottles * bType,
      expiration: b.expiration,
      donorNames: b.donorNames
    });

    totalAllocatedMl += takeBottles * bType;
    if (needed > 0) needed -= takeBottles * bType;
  }

  res.status(200).json({
    success: true,
    allocatedBatches: allocated,
    totalAllocatedMl,
    isSufficient: needed <= 0
  });
});

// Fulfill Request with FEFO => /api/v1/inventories/fulfill-request
exports.fulfillRequest = catchAsyncErrors(async (req, res, next) => {
  return withInventoryLock(async () => {
    const { requestId, allocatedBatches, approvedBy, transport, dispenseAt } = req.body;

    const request = await Request.findById(requestId);
    if (!request) return next(new ErrorHandler("Request not found", 404));

    if (!allocatedBatches || !Array.isArray(allocatedBatches) || allocatedBatches.length === 0) {
      return next(new ErrorHandler("Allocated batch details are required", 400));
    }

    const now = new Date();
    const ebmRecords = [];

    for (const alloc of allocatedBatches) {
      const { inventoryId, allocatedBottles } = alloc;
      const count = Number(allocatedBottles);

      const batch = await Inventory.findById(inventoryId);
      if (!batch) return next(new ErrorHandler(`Batch ${inventoryId} not found`, 404));

      // Never allocate expired batches
      if (batch.expiration && new Date(batch.expiration) < now) {
        return next(new ErrorHandler(`Batch #${batch.batchNumber} has expired and cannot be allocated.`, 400));
      }

      if (batch.availableBottles < count) {
        return next(new ErrorHandler(`Batch #${batch.batchNumber} has only ${batch.availableBottles} bottles available (requested ${count})`, 400));
      }

      const beforeBottles = batch.availableBottles;
      const beforeVol = batch.volume;
      const bType = batch.bottleType || 100;

      batch.availableBottles -= count;
      batch.volume = batch.availableBottles * bType;

      // When batch reaches 0 bottles left, status moves to 'Depleted'
      if (batch.availableBottles <= 0) {
        batch.status = 'Depleted';
        batch.availableBottles = 0;
        batch.volume = 0;
      }

      // Update bottles array if present
      if (batch.pasteurizedDetails?.bottles?.length) {
        let marked = 0;
        for (const bot of batch.pasteurizedDetails.bottles) {
          if (bot.status === 'Available' && marked < count) {
            bot.status = 'Dispensed';
            marked++;
          }
        }
      }

      await batch.save();

      ebmRecords.push({
        invId: batch._id,
        bottleType: bType,
        batch: batch.batchNumber,
        pool: batch.poolNumber,
        bottlesAllocated: count,
        volDischarge: count * bType
      });

      await AuditLog.create({
        action: 'FULFILL_REQUEST',
        user: req.user?._id || approvedBy,
        userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
        targetType: 'Request',
        targetId: request._id,
        beforeVolume: beforeVol,
        afterVolume: batch.volume,
        volumeChanged: -(count * bType),
        reason: `Allocated ${count} bottles (${count * bType} ml) from Batch #${batch.batchNumber} for Request #${request._id}`
      });
    }

    request.status = 'Done';
    request.milklink.ebm = ebmRecords;
    if (transport) request.milklink.transport = transport;
    request.milklink.dispenseAt = dispenseAt ? new Date(dispenseAt) : new Date();
    if (approvedBy || req.user?._id) request.milklink.approvedBy = approvedBy || req.user?._id;

    await request.save();

    res.status(200).json({
      success: true,
      message: 'Request fulfilled and milk successfully dispensed using FEFO',
      request,
    });
  });
});

// Update Inventory Entry => /api/v1/inventory/:id
exports.updateInventoryEntry = catchAsyncErrors(async (req, res, next) => {
  const { volume, expiration, reasonForChange, donorName } = req.body;
  const inventory = await Inventory.findById(req.params.id);
  if (!inventory) {
    return next(new ErrorHandler("Inventory entry not found", 404));
  }

  const beforeVol = inventory.volume;
  if (volume !== undefined) {
    inventory.volume = Math.round(Number(volume));
    if (inventory.bottleType && inventory.availableBottles) {
      inventory.availableBottles = Math.floor(inventory.volume / inventory.bottleType);
    }
  }
  if (expiration) {
    inventory.expiration = new Date(expiration);
  }
  if (donorName) {
    inventory.donorName = donorName.trim();
  }
  if (reasonForChange) {
    inventory.reasonForChange = reasonForChange.trim();
  }

  await inventory.save();

  await AuditLog.create({
    action: 'UPDATE_ENTRY',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Inventory',
    targetId: inventory._id,
    beforeVolume: beforeVol,
    afterVolume: inventory.volume,
    volumeChanged: inventory.volume - beforeVol,
    reason: reasonForChange || 'Manual entry volume/date adjustment'
  });

  res.status(200).json({
    success: true,
    inventory,
  });
});

// Delete Inventory Entry => /api/v1/inventory/:id
exports.deleteInventoryEntry = catchAsyncErrors(async (req, res, next) => {
  const inventory = await Inventory.findById(req.params.id);
  if (!inventory) {
    return next(new ErrorHandler("Inventory entry not found", 404));
  }

  const beforeVol = inventory.volume;
  await inventory.deleteOne();

  await AuditLog.create({
    action: 'DELETE_ENTRY',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Inventory',
    targetId: inventory._id,
    beforeVolume: beforeVol,
    afterVolume: 0,
    volumeChanged: -beforeVol,
    reason: 'Entry permanently deleted'
  });

  res.status(200).json({
    success: true,
    message: 'Inventory entry deleted permanently'
  });
});

// Soft Delete (Archive) Entry => /api/v1/inventory/:id/soft-delete
exports.softDeleteInventory = catchAsyncErrors(async (req, res, next) => {
  const inventory = await Inventory.softDeleteById(req.params.id);
  if (!inventory) {
    return next(new ErrorHandler("Inventory entry not found", 404));
  }

  await AuditLog.create({
    action: 'ARCHIVE_ENTRY',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Inventory',
    targetId: inventory._id,
    reason: 'Archived inventory entry'
  });

  res.status(200).json({
    success: true,
    inventory,
  });
});

// Restore Entry => /api/v1/inventory/:id/restore
exports.restoreInventory = catchAsyncErrors(async (req, res, next) => {
  const inventory = await Inventory.restoreById(req.params.id);
  if (!inventory) {
    return next(new ErrorHandler("Archived inventory entry not found", 404));
  }

  await AuditLog.create({
    action: 'RESTORE_ENTRY',
    user: req.user?._id,
    userName: req.user?.name ? `${req.user.name.first} ${req.user.name.last}` : 'Staff / Admin',
    targetType: 'Inventory',
    targetId: inventory._id,
    reason: 'Restored archived inventory entry'
  });

  res.status(200).json({
    success: true,
    inventory,
  });
});



