const Schedule = require("../models/schedule");
const Collection = require("../models/collection");
const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const User = require("../models/user");
const Bag = require("../models/bags");
const Donor = require("../models/donor");
const Inventory = require("../models/inventory");
const Fridge = require("../models/fridge");

// --- Helper Functions for Time, Date, and Overlap Prevention ---

let scheduleMutationLock = Promise.resolve();
function withScheduleLock(fn) {
  return new Promise((resolve, reject) => {
    scheduleMutationLock = scheduleMutationLock.then(async () => {
      try {
        const result = await fn();
        resolve(result);
      } catch (err) {
        reject(err);
      }
    });
  });
}

function parseTimeToMinutes(timeStr) {
  if (!timeStr) return null;
  const str = timeStr.toString().trim();
  const match12 = str.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (match12) {
    let hours = parseInt(match12[1], 10);
    const minutes = parseInt(match12[2], 10);
    const modifier = match12[3].toUpperCase();
    if (modifier === 'PM' && hours < 12) hours += 12;
    if (modifier === 'AM' && hours === 12) hours = 0;
    return hours * 60 + minutes;
  }
  const match24 = str.match(/^(\d{1,2}):(\d{2})$/);
  if (match24) {
    const hours = parseInt(match24[1], 10);
    const minutes = parseInt(match24[2], 10);
    return hours * 60 + minutes;
  }
  return null;
}

function minutesToTime12(totalMinutes) {
  let hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  if (hours === 0) hours = 12;
  const minsStr = minutes.toString().padStart(2, '0');
  return `${hours}:${minsStr} ${ampm}`;
}

function minutesToTime24(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
}

function toIsoDateStr(d) {
  if (!d) return null;
  const dateObj = new Date(d);
  if (isNaN(dateObj.getTime())) return null;
  return dateObj.toISOString().split('T')[0];
}

function getDatesCovered(sched) {
  const dates = [];
  const startStr = toIsoDateStr(sched.startDate || sched.date || sched.dates);
  const endStr = toIsoDateStr(sched.endDate || sched.date || sched.dates);

  if (!startStr) return dates;
  if (!endStr || startStr === endStr) {
    dates.push(startStr);
    return dates;
  }

  const current = new Date(startStr);
  const end = new Date(endStr);
  while (current <= end) {
    dates.push(current.toISOString().split('T')[0]);
    current.setUTCDate(current.getUTCDate() + 1);
  }
  return dates;
}

async function findConflictAndSuggest(newSched, excludeId = null) {
  const newStartMin = parseTimeToMinutes(newSched.startTime);
  const newEndMin = parseTimeToMinutes(newSched.endTime);
  if (newStartMin === null || newEndMin === null) return null;

  if (newEndMin <= newStartMin) {
    return {
      error: 'End Time must be later than Start Time.'
    };
  }

  const newDates = getDatesCovered(newSched);
  if (newDates.length === 0) return null;

  const duration = newEndMin - newStartMin;

  const query = {
    isDeleted: { $ne: true }
  };
  if (excludeId) {
    query._id = { $ne: excludeId };
  }

  const allActive = await Schedule.find(query);
  const activeSchedules = allActive.filter(s => {
    if (s.kind === 'Pickup') {
      return s.pickupStatus !== 'Cancelled';
    } else {
      return s.status !== 'Cancelled';
    }
  });

  for (const dateStr of newDates) {
    const dateSchedules = activeSchedules.filter(s => {
      const sDates = getDatesCovered(s);
      return sDates.includes(dateStr);
    });

    for (const existing of dateSchedules) {
      const exStart = parseTimeToMinutes(existing.startTime);
      const exEnd = parseTimeToMinutes(existing.endTime);
      if (exStart === null || exEnd === null) continue;

      // Overlap: new.start < existing.end AND new.end > existing.start
      if (newStartMin < exEnd && newEndMin > exStart) {
        const type = existing.kind || 'Event';
        const titleOrDonor = type === 'Event'
          ? (existing.title || 'Untitled Event')
          : (existing.donorName || 'Unnamed Donor');
        const timeRangeStr = `${minutesToTime12(exStart)} - ${minutesToTime12(exEnd)}`;

        const intervals = dateSchedules
          .map(s => ({
            start: parseTimeToMinutes(s.startTime),
            end: parseTimeToMinutes(s.endTime)
          }))
          .filter(i => i.start !== null && i.end !== null && i.end > i.start)
          .sort((a, b) => a.start - b.start);

        let candidateStart = exEnd;
        let suggestedSlot = null;

        while (candidateStart + duration <= 1440) {
          const candidateEnd = candidateStart + duration;
          const overlaps = intervals.find(i => candidateStart < i.end && candidateEnd > i.start);
          if (!overlaps) {
            suggestedSlot = {
              start: candidateStart,
              end: candidateEnd,
              start12: minutesToTime12(candidateStart),
              end12: minutesToTime12(candidateEnd),
              start24: minutesToTime24(candidateStart),
              end24: minutesToTime24(candidateEnd),
              formatted: `${minutesToTime12(candidateStart)} - ${minutesToTime12(candidateEnd)}`
            };
            break;
          } else {
            candidateStart = overlaps.end;
          }
        }

        if (!suggestedSlot) {
          candidateStart = 480; // 8:00 AM
          while (candidateStart + duration <= exStart) {
            const candidateEnd = candidateStart + duration;
            const overlaps = intervals.find(i => candidateStart < i.end && candidateEnd > i.start);
            if (!overlaps) {
              suggestedSlot = {
                start: candidateStart,
                end: candidateEnd,
                start12: minutesToTime12(candidateStart),
                end12: minutesToTime12(candidateEnd),
                start24: minutesToTime24(candidateStart),
                end24: minutesToTime24(candidateEnd),
                formatted: `${minutesToTime12(candidateStart)} - ${minutesToTime12(candidateEnd)}`
              };
              break;
            } else {
              candidateStart = overlaps.end;
            }
          }
        }

        const suggestionText = suggestedSlot ? suggestedSlot.formatted : 'No remaining slot today';

        return {
          conflict: true,
          type,
          titleOrDonor,
          date: dateStr,
          timeRange: timeRangeStr,
          suggestedSlot: suggestionText,
          suggestedDetails: suggestedSlot,
          message: `Conflict with ${type} '${titleOrDonor}' on ${dateStr} (${timeRangeStr}). Next free slot: ${suggestionText}`
        };
      }
    }
  }

  return null;
}

async function handlePickupInventoryMove(schedule, userId) {
  let collection = await Collection.findOne({ privDetails: schedule._id });
  if (!collection) {
    collection = await Collection.create({
      collectionType: 'Private',
      collectionDate: schedule.startDate || schedule.date || schedule.dates || new Date(),
      privDetails: schedule._id,
      status: 'Collected',
      user: userId ? [userId] : [],
      notes: `Pickup donation from: ${schedule.donorName || 'Private Donor'}`
    });
  } else {
    collection.status = 'Collected';
    if (userId && (!collection.user || collection.user.length === 0)) {
      collection.user = [userId];
    }
    await collection.save();
  }

  let fridge = await Fridge.findOne({ fridgeType: 'Unpasteurized' });
  if (!fridge) {
    fridge = await Fridge.findOne({});
  }

  if (fridge) {
    let inv = await Inventory.findOne({ 'unpasteurizedDetails.collectionId': collection._id });
    if (!inv) {
      const startDate = schedule.startDate || schedule.date || schedule.dates || new Date();
      const endDate = schedule.endDate || schedule.date || schedule.dates || new Date();
      const expiration = new Date(startDate);
      expiration.setDate(expiration.getDate() + 14);

      const vol = Math.round(Number(schedule.totalVolume || 0));
      await Inventory.create({
        fridge: fridge._id,
        user: userId || schedule.approvedBy || collection.user?.[0],
        status: 'Available',
        volume: vol,
        donorName: schedule.donorName || 'Private Donor',
        expiration,
        unpasteurizedDetails: {
          collectionId: collection._id,
          expressDateStart: startDate,
          expressDateEnd: endDate,
          expiration
        }
      });
      collection.volume = vol;
      collection.status = 'Stored';
      await collection.save();
    }
  }

  if (schedule.donorDetails?.bags?.length > 0) {
    await Bag.updateMany(
      { _id: { $in: schedule.donorDetails.bags } },
      { $set: { status: 'Collected' } }
    );
  }
}

// --- Controller Actions ---

// Get All schedules => /api/v1/schedules
exports.allSchedules = catchAsyncErrors(async (req, res, next) => {
  const { kind, search } = req.query;
  const query = {};
  if (kind) query.kind = kind;
  if (search) {
    query.$or = [
      { title: { $regex: search, $options: 'i' } },
      { donorName: { $regex: search, $options: 'i' } },
      { location: { $regex: search, $options: 'i' } },
      { pickupAddress: { $regex: search, $options: 'i' } }
    ];
  }

  const schedules = await Schedule.find(query)
    .sort({ createdAt: -1 })
    .populate({
      path: "donorDetails.donorId",
      populate: { path: "user" },
    })
    .populate("donorDetails.bags");

  const count = await Schedule.countDocuments(query);

  res.status(200).json({
    success: true,
    count,
    schedules,
  });
});

exports.archivedSchedules = catchAsyncErrors(async (req, res, next) => {
  const { kind, search } = req.query;
  const query = {};
  if (kind) query.kind = kind;
  if (search) {
    query.$or = [
      { title: { $regex: search, $options: 'i' } },
      { donorName: { $regex: search, $options: 'i' } },
      { location: { $regex: search, $options: 'i' } },
      { pickupAddress: { $regex: search, $options: 'i' } }
    ];
  }

  const schedules = await Schedule.findOnlyDeleted(query)
    .sort({ createdAt: -1 })
    .populate("donorDetails.donorId")
    .populate("donorDetails.bags");
  res.status(200).json({ success: true, count: schedules.length, schedules });
});

exports.getBookedSlots = catchAsyncErrors(async (req, res, next) => {
  const { date, excludeId } = req.query;
  if (!date) {
    return res.status(400).json({ success: false, message: 'date query parameter required' });
  }

  const query = { isDeleted: { $ne: true } };
  if (excludeId) query._id = { $ne: excludeId };

  const allActive = await Schedule.find(query);
  const activeSchedules = allActive.filter(s => {
    if (s.kind === 'Pickup') {
      return s.pickupStatus !== 'Cancelled';
    } else {
      return s.status !== 'Cancelled';
    }
  });

  const slots = [];
  for (const s of activeSchedules) {
    const dates = getDatesCovered(s);
    if (dates.includes(date)) {
      const startMin = parseTimeToMinutes(s.startTime);
      const endMin = parseTimeToMinutes(s.endTime);
      if (startMin !== null && endMin !== null) {
        slots.push({
          id: s._id,
          kind: s.kind,
          name: s.kind === 'Event' ? (s.title || 'Event') : (s.donorName || 'Pickup'),
          startTime: s.startTime,
          endTime: s.endTime,
          start12: minutesToTime12(startMin),
          end12: minutesToTime12(endMin),
          startMinutes: startMin,
          endMinutes: endMin,
        });
      }
    }
  }

  slots.sort((a, b) => a.startMinutes - b.startMinutes);

  res.status(200).json({
    success: true,
    date,
    bookedSlots: slots
  });
});

exports.softDeleteSchedule = catchAsyncErrors(async (req, res, next) => {
  const schedule = await Schedule.softDeleteById(req.params.id);
  if (!schedule) return next(new ErrorHandler("Schedule not found", 404));
  res.status(200).json({ success: true, schedule });
});

exports.restoreSchedule = catchAsyncErrors(async (req, res, next) => {
  return withScheduleLock(async () => {
    const schedule = await Schedule.findOneOnlyDeleted({ _id: req.params.id });
    if (!schedule) return next(new ErrorHandler("Archived schedule not found", 404));

    const isNowActive = schedule.kind === 'Pickup' ? schedule.pickupStatus !== 'Cancelled' : schedule.status !== 'Cancelled';
    if (isNowActive) {
      const conflict = await findConflictAndSuggest(schedule, schedule._id);
      if (conflict) {
        return res.status(409).json({
          success: false,
          message: conflict.message || conflict.error,
          conflict
        });
      }
    }

    const restored = await Schedule.restoreById(req.params.id);
    res.status(200).json({ success: true, schedule: restored });
  });
});

// Create schedule => /api/v1/schedules
exports.createSchedule = catchAsyncErrors(async (req, res, next) => {
  return withScheduleLock(async () => {
    const data = { ...req.body };

    // Format dates
    if (data.dates) {
      data.dates = new Date(data.dates);
    } else if (data.startDate) {
      data.dates = new Date(data.startDate);
    }
    if (data.startDate) data.startDate = new Date(data.startDate);
    if (data.endDate) data.endDate = new Date(data.endDate);

    // Automatically make the event pending status on creation
    if (data.kind === 'Event') {
      data.status = 'Pending';
    }

    // Overlap prevention check
    const conflict = await findConflictAndSuggest(data);
    if (conflict) {
      return res.status(409).json({
        success: false,
        message: conflict.message || conflict.error,
        conflict
      });
    }

    const schedule = await Schedule.create(data);

    // Check inventory link if Pickup has status 'Picked Up'
    if (schedule.pickupStatus === 'Picked Up' || schedule.status === 'Completed') {
      await handlePickupInventoryMove(schedule, req.user?._id || req.body.admin);
    }

    res.status(201).json({
      success: true,
      schedule,
    });
  });
});

// Get specific schedule details => /api/v1/schedule/:id
exports.getScheduleDetails = catchAsyncErrors(async (req, res, next) => {
  let schedule = await Schedule.findOne({ _id: req.params.id })
    .populate({
      path: "donorDetails.donorId",
      populate: { path: "user" },
    })
    .populate("donorDetails.bags");

  if (!schedule) {
    return next(
      new ErrorHandler(`schedule is not found with this id: ${req.params.id}`)
    );
  }

  res.status(200).json({
    success: true,
    schedule,
  });
});

// Update schedule => /api/v1/schedule/:id
exports.updateSchedule = catchAsyncErrors(async (req, res, next) => {
  return withScheduleLock(async () => {
    const existing = await Schedule.findById(req.params.id);
    if (!existing) {
      return next(new ErrorHandler(`Schedule not found with this id: ${req.params.id}`, 404));
    }

    const updatedData = { ...req.body };
    if (updatedData.dates) updatedData.dates = new Date(updatedData.dates);
    if (updatedData.startDate) updatedData.startDate = new Date(updatedData.startDate);
    if (updatedData.endDate) updatedData.endDate = new Date(updatedData.endDate);

    // If changing from "Picked Up" back to another status, check if milk was already pasteurized or requested
    if (existing.pickupStatus === 'Picked Up' && updatedData.pickupStatus && updatedData.pickupStatus !== 'Picked Up') {
      const collection = await Collection.findOne({ privDetails: existing._id });
      if (collection) {
        const inv = await Inventory.findOne({ 'unpasteurizedDetails.collectionId': collection._id });
        if (inv) {
          if (inv.isPasteurized || inv.isRequested || inv.status === 'Unavailable' || inv.volume === 0) {
            return next(new ErrorHandler(
              "Cannot reverse pickup status. The collected milk from this donor has already been pasteurized into a batch or allocated for milk requests.",
              400
            ));
          }
          // Reverse inventory entry
          await inv.deleteOne();
          collection.status = 'Pending';
          await collection.save();
        }
      }
    }

    const merged = { ...existing.toObject(), ...updatedData };
    const isNowActive = merged.kind === 'Pickup' ? merged.pickupStatus !== 'Cancelled' : merged.status !== 'Cancelled';

    if (isNowActive) {
      const conflict = await findConflictAndSuggest(merged, req.params.id);
      if (conflict) {
        return res.status(409).json({
          success: false,
          message: conflict.message || conflict.error,
          conflict
        });
      }
    }

    const schedule = await Schedule.findByIdAndUpdate(
      req.params.id,
      updatedData,
      {
        new: true,
        runValidators: true,
        useFindAndModify: false,
      }
    );

    // Inventory link: Status "Picked Up" moves collected volume to Unpasteurized refrigerator
    // Note: Changing a pickup's time does not change inventory totals.
    if (schedule.pickupStatus === 'Picked Up' || schedule.status === 'Completed') {
      await handlePickupInventoryMove(schedule, req.user?._id || req.body.admin);
    }

    res.status(200).json({
      success: true,
      schedule,
    });
  });
});

// Delete schedule => /api/v1/schedule/:id
exports.deleteSchedule = catchAsyncErrors(async (req, res, next) => {
  const schedule = await Schedule.findById(req.params.id);

  if (!schedule) {
    return next(
      new ErrorHandler(`schedule is not found with this id: ${req.params.id}`)
    );
  }

  await schedule.deleteOne();

  res.status(200).json({
    success: true,
    message: "schedule Deleted",
  });
});

// Request a Pickup Schedule
exports.requestSchedule = catchAsyncErrors(async (req, res) => {
  const { date, userId } = req.body;

  try {
    const donor = await Donor.findOne({ user: userId });
    if (!donor) return res.status(404).json({ error: "Donor not found" });

    const sched = await Schedule.findOne({
      "donorDetails.donorId": donor._id,
      status: "Pending",
    });
    if (sched)
      return res
        .status(400)
        .json({ error: "You already have a pending schedule" });

    const bags = await Bag.find({
      donor: donor._id,
      status: "Expressed",
      collectionType: "Private",
    });
    if (bags.length === 0)
      return res.status(404).json({ error: "No bags found for this donor" });

    const address =
      donor.home_address.street +
      ", " +
      donor.home_address.brgy +
      ", " +
      donor.home_address.city;

    const totalVolume = bags.reduce((total, item) => {
      return total + item.volume;
    }, 0);

    const newSchedule = await Schedule.create({
      address,
      dates: date,
      donorDetails: { donorId: donor._id, bags },
      totalVolume,
    });

    await Bag.updateMany(
      { _id: { $in: newSchedule.donorDetails.bags } },
      { $set: { status: "Scheduled" } }
    );

    res
      .status(201)
      .json({ message: "Schedule requested successfully", newSchedule });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to request schedule", details: error.message });
  }
});

exports.getDonorSchedules = catchAsyncErrors(async (req, res) => {
  const { id } = req.params;

  const donor = await Donor.findOne({ user: id });
  if (!donor) return res.status(404).json({ error: "Donor not found" });

  const sched = await Schedule.aggregate([
    { $match: { "donorDetails.donorId": donor._id } },
    {
      $facet: {
        allSchedules: [
          {
            $addFields: {
              statusOrder: {
                $switch: {
                  branches: [
                    { case: { $eq: ["$status", "Pending"] }, then: 1 },
                    { case: { $eq: ["$status", "Approved"] }, then: 2 },
                    { case: { $eq: ["$status", "Completed"] }, then: 3 },
                  ],
                  default: 4,
                },
              },
            },
          },
          { $sort: { statusOrder: 1, date: -1 } },
          { $project: { statusOrder: 0 } },
        ],
        pendingCount: [{ $match: { status: "Pending" } }, { $count: "count" }],
      },
    },
  ]);

  const allSchedules = sched[0].allSchedules;
  const pendingCount =
    sched[0].pendingCount.length > 0 ? sched[0].pendingCount[0].count : 0;

  res.status(200).json({
    success: true,
    count: pendingCount,
    schedules: allSchedules,
  });
});

// Approve or Modify a Pickup Schedule
exports.approveSchedule = catchAsyncErrors(async (req, res) => {
  const { scheduleId, newDate, adminId, venue } = req.body;

  try {
    const schedule = await Schedule.findById(scheduleId);
    if (!schedule) return res.status(404).json({ error: "Schedule not found" });

    if (newDate) schedule.dates = newDate;
    schedule.venue = venue;
    schedule.status = "Approved";
    schedule.approvedBy = adminId;
    await schedule.save();

    const newCollection = await Collection.create({
      collectionType: "Private",
      collectionDate: schedule.dates,
      user: adminId,
      privDetails: scheduleId,
    });

    res
      .status(200)
      .json({ message: "Schedule approved successfully", newCollection });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to approve schedule", details: error.message });
  }
});

exports.updateStatus = catchAsyncErrors(async (req, res, next) => {
  const { schedId, status } = req.body;

  const schedule = await Schedule.findById(schedId);
  if (!schedule) return res.status(404).json({ error: "Schedule not found" });

  schedule.status = status;
  if (schedule.kind === 'Pickup' && status === 'Cancelled') {
    schedule.pickupStatus = 'Cancelled';
  }

  if (status === "Completed" || status === "Picked Up") {
    await handlePickupInventoryMove(schedule, req.user?._id || req.body.admin);
  }

  await schedule.save();

  res.status(200).json({
    success: true,
    schedule,
  });
});
