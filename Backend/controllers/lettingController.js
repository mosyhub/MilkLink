const Letting = require("../models/letting");
const Collection = require("../models/collection");
const User = require("../models/user");
const Donor = require("../models/donor");
const Bag = require("../models/bags");
const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const Event = require("../models/event");
const Inventory = require("../models/inventory");
const mongoose = require("mongoose");
const { calculateAge } = require("../utils/helper");

exports.getUpcomingLettings = catchAsyncErrors(async (req, res, next) => {
  try {
    const events = await Letting.find({
      "actDetails.date": {
        $gte: new Date(),
      },
    }).sort("actDetails.date");

    return res.status(200).json({
      success: true,
      count: events.length,
      events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get All lettings => /api/v1/lettings
exports.allLettings = catchAsyncErrors(async (req, res, next) => {
  try {
    const lettings = await Letting.find()
      .populate({
        path: "attendance.donor",
        select: "user home_address",
        populate: {
          path: "user",
          select: "name phone",
        },
      })
      .populate({
        path: "attendance.bags",
        select: "volume",
      });
    if (!lettings || lettings.length === 0) {
      return res.status(404).json({ error: "No Milk Letting Events Found" });
    }

    const count = await Letting.countDocuments();

    res.status(200).json({
      success: true,
      count,
      lettings,
    });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to finalize session", details: error.message });
  }
});

// Create letting => /api/v1/lettings
exports.createLetting = catchAsyncErrors(async (req, res, next) => {
  const actDetails = {
    start: new Date(req.body.start), // This stores in UTC
    end: new Date(req.body.end), // This stores in UTC
  };

  const letting = await Letting.create({
    ...req.body,
    actDetails,
  });

  res.status(201).json({
    success: true,
    letting,
  });
});

// Get specific letting details => /api/v1/letting/:id
exports.getLettingDetails = catchAsyncErrors(async (req, res, next) => {
  const letting = await Letting.findById(req.params.id)
    .populate({
      path: "attendance.donor",
      select: "user home_address",
      populate: {
        path: "user",
        select: "name phone",
      },
    })
    .populate({
      path: "attendance.bags",
      select: "volume expressDate status",
    })
    .populate({
      path: "attendance.additionalBags",
      select: "volume expressDate status",
    });
  if (!letting) {
    return next(
      new ErrorHandler(`letting is not found with this id: ${req.params.id}`)
    );
  }

  res.status(200).json({
    success: true,
    letting,
  });
});

// Update letting => /api/v1/letting/:id
exports.updateLetting = catchAsyncErrors(async (req, res, next) => {
  const actDetails = {
    date: req.body.date,
  };

  const newLettingData = {
    ...req.body,
    actDetails,
  };

  const letting = await Letting.findByIdAndUpdate(
    req.params.id,
    newLettingData,
    {
      new: true,
      runValidators: true,
      useFindAndModify: false,
    }
  );

  res.status(200).json({
    success: true,
    letting,
  });
});

// Delete letting => /api/v1/letting/:id
exports.deleteletting = catchAsyncErrors(async (req, res, next) => {
  const letting = await Letting.findById(req.params.id).populate('attendance.bags', 'volume')
    .populate('attendance.additionalBags', 'volume');


  if (!letting) {
    throw new Error("Letting not found.")
  }

  const bagIdsToDelete = [];
  const attendance = letting.attendance;

  for (const item of attendance) {
    if (item?.bags?.length > 0) {
      bagIdsToDelete.push(...item.bags.map(bag => bag._id));
    }

    if (item?.additionalBags?.length > 0) {
      bagIdsToDelete.push(...item.additionalBags.map(bag => bag._id));
    }
  }

  // Delete all collected bag IDs in one go
  if (bagIdsToDelete.length > 0) {
    await Bag.deleteMany({ _id: { $in: bagIdsToDelete } });
  }


  await letting.deleteOne();

  res.status(200).json({
    success: true,
    message: "Milk Letting Deleted",
  });
});

// Create Milk Letting Event
exports.createEvent = catchAsyncErrors(async (req, res) => {
  const { activity, venue, actDetails, admin, description, status } = req.body;

  try {
    const newEvent = await Letting.create({
      activity,
      venue,
      actDetails,
      admin,
      description,
      status
    });
    res
      .status(201)
      .json({ success: true, message: "Created Milk Letting Event", newEvent });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to create event", details: error.message });
  }
});

// Mark Attendance for Donors
exports.markAttendance = catchAsyncErrors(async (req, res, next) => {
  const { lettingId, donorId, donorType, bags, lastDonation, dateTested } = req.body;

  try {
    const event = await Letting.findById(lettingId);
    if (!event) return res.status(404).json({ error: "Event not found" });

    let total = Number(event.totalVolume) || 0;

    const newBags = bags.flatMap((bag) => {
      if (bag.quantity === 0)
        throw new ErrorHandler("Bag quantity cannot be zero");

      const numericVolume = Number(bag.volume) || 0;
      total += numericVolume * bag.quantity;

      return Array.from({ length: bag.quantity }, () => ({
        collectionType: "Public",
        donor: donorId,
        status: "Collected",
        volume: bag.volume,
      }));
    });

    const createdBags = await Bag.insertMany(newBags);
    const bagIds = createdBags.map((bag) => bag._id);

    const attendanceEntry = {
      donor: donorId,
      donorType,
      bags: bagIds,
      ...(lastDonation && { lastDonation }), // Conditionally add `lastDonation`
    };

    event.attendance.push(attendanceEntry);
    event.totalVolume = total;
    await event.save();

    const donor = await Donor.findOneAndUpdate(
      { _id: donorId },
      {

        $set: { dateTested: dateTested }, // Update totalVolume
      },
      { new: true }
    );
    res.status(200).json({
      success: true,
      message: "Attendance recorded successfully",
      event,
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to mark attendance",
      details: error.message,
    });
  }
});

exports.updateAttendance = catchAsyncErrors(async (req, res, next) => {
  const { donorId, bags } = req.body;
  const { id } = req.params;
  const donorObjectID = new mongoose.Types.ObjectId(donorId);
  try {
    const event = await Letting.findById(id);
    if (!event) return res.status(404).json({ error: "Event not found" });

    let total = Number(event.totalVolume) || 0;

    // Calculate new total volume
    const newBags = bags.map((bag) => {
      const numericVolume = Number(bag.volume) || 0;
      total += numericVolume;

      return {
        collectionType: "Public",
        donor: donorId,
        status: "Collected",
        volume: bag.volume,
        expressDate: bag.expressDate,
      };
    });

    // Insert new bags
    const createdBags = await Bag.insertMany(newBags);
    const bagIds = createdBags.map((bag) => bag._id);

    // Find the donor's attendance entry
    const donorAttendance = event.attendance.find(
      (a) => a.donor.toString() === donorId
    );

    if (donorAttendance) {
      // Donor exists in attendance
      if (
        Array.isArray(donorAttendance.additionalBags) &&
        donorAttendance.additionalBags.length > 0
      ) {
        // Donor already has additional bags, so push new ones
        const updatedEvent = await Letting.findOneAndUpdate(
          { _id: id, "attendance.donor": donorObjectID },
          {
            $push: { "attendance.$.additionalBags": { $each: bagIds } }, // Append new bags
            $set: { totalVolume: total }, // Update totalVolume
          },
          { new: true }
        );
        res.status(200).json({
          success: true,
          message: "Additional bags recorded successfully",
          event: updatedEvent,
        });
      } else {
        // Donor exists but additionalBags is empty or undefined, initialize it
        const updatedEvent = await Letting.findOneAndUpdate(
          { _id: id, "attendance.donor": donorObjectID },
          {
            $set: { "attendance.$.additionalBags": bagIds, totalVolume: total }, // Initialize additionalBags
          },
          { new: true }
        );
        res.status(200).json({
          success: true,
          message: "Additional bags recorded successfully",
          event: updatedEvent,
        });
      }
    } else {
      res.status(404).json({ error: "Donor not found in attendance" });
    }
  } catch (error) {
    res.status(500).json({
      error: "Failed to add additional bags",
      details: error.message,
    });
  }
});

// Finalize the Milk Letting Session
exports.finalizeSession = catchAsyncErrors(async (req, res) => {
  const { lettingId, adminId, percent } = req.body;
  console.log(percent)
  try {
    const event = await Letting.findById(lettingId);
    if (!event) return res.status(404).json({ error: "Event not found" });

    let collection = await Collection.findOne({ pubDetails: lettingId });

    if (!collection) {
      if (event.status !== "Done") {
        await Bag.updateMany(
          { _id: { $in: event.attendance.bags } },
          { $set: { status: "Collected" } }
        );

        event.status = "Done";
        event.performance = Number(percent);
        await event.save();

        collection = await Collection.create({
          collectionType: "Public",
          collectionDate: new Date(),
          status: "Collected",
          pubDetails: lettingId,
          user: [adminId],
        });
      } else {
        return res
          .status(400)
          .json({ error: "Session already finalized, no new data created." });
      }
    } else {
      if (!collection.user.includes(adminId)) {
        collection.user.push(adminId);
        await collection.save();
      }
    }

    res.status(200).json({
      success: true,
      message: "Session finalized successfully",
      collection,
    });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to finalize session", details: error.message });
  }
});

exports.newPublicDonorTally = catchAsyncErrors(async (req, res, next) => {
  try {
    let data = {};
    req.body.data.fields.forEach((field) => {
      if (field.type === 'DROPDOWN' && Array.isArray(field.value)) {
        // Find the matching option by ID
        const selectedId = field.value[0]; // assuming single select dropdown
        const selectedOption = field.options.find(option => option.id === selectedId);
        data[field.label] = selectedOption ? selectedOption.text : null;
      } else {
        data[field.label] = field.value;
      }
    });
    // Prepare children array with one child object
    const { age, unit } = calculateAge(data.child_age);
    const children = [
      {
        name: data.child_name,
        age: { value: age, unit: unit },
        birth_weight: data.birth_weight,
        aog: data.aog,
      },
    ];
    let password = `${data.first_name
      .replace(/\s+/g, "")
      .toLowerCase()}${data.last_name.replace(/\s+/g, "").toLowerCase()}`;

    const name = {
      first: data.first_name || "",
      middle: data.middle_name || "",
      last: data.last_name || "",
    };

    const userExist = await User.findOne({
      name,
      email: data.email,
    });

    if (userExist) {
      return res.status(400).json({
        success: false,
        message: "User already exists",
      });
    }

    const user = await User.create({
      name: name,
      email: data.email,
      phone: data.phone,
      password: password,
      role: "User",
    });
    const { age: donorAge, unit: donorUnit } = calculateAge(data.birthday);
    // Create donor
    const donor = await Donor.create({
      user: user._id,
      home_address: {
        street: data.street,
        brgy: data.brgy,
        city: data.city || "Taguig City",
      },
      age: { value: donorAge, unit: donorUnit },
      birthday: data.birthday,
      children: children,
      office_address: data.office_address,
      contact_number: data.contact_number_2,
      donorType: "Community",
      occupation: data.occupation,
      verified: true,
      lastSubmissionDate: new Date(),
      eligibility: "Eligible"
    });

    res.status(200).json({
      success: true,
      user,
      donor,
    });
  } catch (error) {
    console.error("Error in createDonor:", error);
    res.status(500).json({ error: error.message });
  }
});

// New Public Donor
exports.newPublicDonor = catchAsyncErrors(async (req, res, next) => {
  try {
    const formData = req.body.formData;

    // Prepare children array with one child object
    const { age: child_age, unit: child_unit } = calculateAge(formData.child_bday);
    const children = [
      {
        name: formData.child_name,
        age: { value: child_age, unit: child_unit },
        birth_weight: formData.birth_weight,
        aog: formData.aog,
      },
    ];
    let password = `${formData.first_name
      .replace(/\s+/g, "")
      .toLowerCase()}${formData.last_name.replace(/\s+/g, "").toLowerCase()}`;

    const name = {
      first: formData.first_name || "",
      middle: formData.middle_name || "",
      last: formData.last_name || "",
    };

    const userExist = await User.findOne({
      name,
      email: formData.email,
    });

    if (userExist) {
      return res.status(400).json({
        success: false,
        message: "User already exists",
      });
    }

    const user = await User.create({
      name: name,
      email: formData.email,
      phone: formData.contact_number,
      password: password,
      role: "User",
    });

    // Create donor
    const { age, unit } = calculateAge(formData.birthday);
    const donor = await Donor.create({
      user: user._id,
      home_address: {
        street: formData.street,
        brgy: formData.brgy,
        city: formData.city || "Taguig City",
      },
      age: { value: age, unit: unit },
      birthday: formData.birthday,
      children: children,
      office_address: formData.office_address,
      contact_number: formData.contact_number_2,
      donorType: formData.donor_type,
      occupation: formData.occupation,
      verified: true,
      lastSubmissionDate: new Date(),
      eligibility: "Eligible"
    });

    res.status(200).json({
      success: true,
      user,
      donor,
    });
  } catch (error) {
    console.error("Error in createDonor:", error);
    res.status(500).json({ error: error.message });
  }
});


exports.deleteAttendance = catchAsyncErrors(async (req, res, next) => {
  try {
    const { lettingId, attendanceId } = req.params
    const letting = await Letting
      .findById(lettingId)
      .populate('attendance.bags', 'volume')
      .populate('attendance.additionalBags', 'volume');
    if (!letting) {
      throw new Error("Letting not found.")
    }


    const attendance = letting.attendance.find(att => att._id.toString() === attendanceId);
    const expressedMilk = attendance.bags.reduce((acc, bag) => acc + bag.volume, 0)
    const additionalBags = attendance.additionalBags.reduce((acc, bag) => acc + bag.volume, 0)
    if (attendance?.bags?.length > 0) {
      await Bag.deleteMany({ _id: { $in: attendance.bags } })
    }
    if (attendance?.additionalBags?.length > 0) {
      await Bag.deleteMany({ _id: { $in: attendance.additionalBags } });
    }




    await Letting.updateOne(
      { _id: letting._id },
      {
        $pull: {
          attendance: { _id: attendanceId }
        }
      }
    );

    letting.totalVolume -= Number(expressedMilk + additionalBags);
    await letting.save()
    res.status(200).json({
      success: true,
      message: "Attendance successfully deleted"
    })
  } catch (error) {
    console.error('Error deleting attendance:', error.message);
    res.status(500).json({ error: error.message });
  }

})