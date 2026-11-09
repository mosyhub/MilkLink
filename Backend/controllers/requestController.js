const Request = require("../models/request");
const Patient = require("../models/patient");
const Inventory = require("../models/inventory");
const Fridge = require("../models/fridge");
const User = require("../models/user");
const Notification = require("../models/notification");
const AuditLog = require("../models/auditLog");
const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const cloudinary = require("cloudinary");
const mongoose = require("mongoose");

// Helper to notify a user
const sendNotification = async (userId, title, body) => {
  if (!userId) return;
  try {
    await Notification.findOneAndUpdate(
      { user: userId },
      {
        $push: {
          notifications: {
            title,
            body,
            seen: false,
            notifiedAt: new Date()
          }
        }
      },
      { upsert: true }
    );
  } catch (err) {
    console.error("Notification error:", err.message);
  }
};

// Helper to notify Admins and Staff
const notifyStaffAndAdmins = async (title, body) => {
  try {
    const staffAndAdmins = await User.find({
      role: { $in: ["Admin", "SuperAdmin", "Staff"] },
      status: { $ne: "Deactivated" },
      isDeleted: { $ne: true }
    }).select("_id");

    for (const u of staffAndAdmins) {
      await sendNotification(u._id, title, body);
    }
  } catch (err) {
    console.error("Broadcast notification error:", err.message);
  }
};

// Helper to log audit trail
const createAudit = async ({ action, user, userName, targetId, reason = "", details = {} }) => {
  try {
    await AuditLog.create({
      action,
      user,
      userName: userName || "Staff / Admin",
      targetType: "Request",
      targetId,
      reason,
      details,
      timestamp: new Date()
    });
  } catch (err) {
    console.error("AuditLog error:", err.message);
  }
};

// GET /api/v1/requests - All requests with status tabs, search, filter, pagination
exports.allRequests = catchAsyncErrors(async (req, res, next) => {
  const {
    status,
    search,
    relationship,
    startDate,
    endDate,
    page = 1,
    limit = 20,
    sortBy = "date",
    sortOrder = "asc"
  } = req.query;

  const query = {};

  if (status === "Archived") {
    query.isDeleted = true;
  } else if (status && status !== "All") {
    query.isDeleted = false;
    query.status = status;
  } else {
    query.isDeleted = false;
  }

  if (relationship && relationship !== "All") {
    query.relationToRecipient = relationship;
  }

  if (startDate || endDate) {
    query.date = {};
    if (startDate) query.date.$gte = new Date(startDate);
    if (endDate) {
      const e = new Date(endDate);
      e.setHours(23, 59, 59, 999);
      query.date.$lte = e;
    }
  }

  if (search && search.trim() !== "") {
    const regex = new RegExp(search.trim(), "i");
    query.$or = [
      { recipientName: regex },
      { requestNumber: regex },
      { hospital: regex }
    ];
  }

  const pageNum = parseInt(page, 10) || 1;
  const limitNum = parseInt(limit, 10) || 20;
  const skip = (pageNum - 1) * limitNum;

  const sortOption = {};
  sortOption[sortBy] = sortOrder === "desc" ? -1 : 1;

  const findQuery = query.isDeleted
    ? Request.findOnlyDeleted(query)
    : Request.findActive(query);

  const [requests, total] = await Promise.all([
    findQuery
      .populate("patient", "name patientType diagnosis")
      .populate("requestedBy", "name username phone email role")
      .populate("clinicalReview.reviewedBy", "name username role")
      .populate("fulfillmentDetails.fulfilledBy", "name username role")
      .sort(sortOption)
      .skip(skip)
      .limit(limitNum),
    Request.countDocuments(query).setOptions({ skipDeletedFilter: true })
  ]);

  // Aggregate count by status for tab badges
  const statusCountsAgg = await Request.aggregate([
    {
      $group: {
        _id: {
          isDeleted: "$isDeleted",
          status: "$status"
        },
        count: { $sum: 1 }
      }
    }
  ]);

  const counts = {
    Pending: 0,
    "Under Review": 0,
    Approved: 0,
    Fulfilled: 0,
    Rejected: 0,
    Cancelled: 0,
    Archived: 0
  };

  statusCountsAgg.forEach(item => {
    if (item._id.isDeleted === true) {
      counts.Archived += item.count;
    } else if (counts[item._id.status] !== undefined) {
      counts[item._id.status] += item.count;
    }
  });

  res.status(200).json({
    success: true,
    requests,
    total,
    page: pageNum,
    pages: Math.ceil(total / limitNum) || 1,
    counts
  });
});

// GET /api/v1/request/:id - Request details + stock panel
exports.getRequestDetails = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findById(req.params.id)
    .setOptions({ skipDeletedFilter: true })
    .populate("patient", "name patientType diagnosis")
    .populate("requestedBy", "name username phone email role")
    .populate("clinicalReview.reviewedBy", "name username role")
    .populate("fulfillmentDetails.fulfilledBy", "name username role");

  if (!request) {
    return next(new ErrorHandler(`Request not found with ID: ${req.params.id}`, 404));
  }

  // Stock panel: fetch all active Pasteurized batches that have availableBottles > 0 and are not expired
  const now = new Date();
  const pasteurizedBatches = await Inventory.find({
    isPasteurized: true,
    isDeleted: false,
    availableBottles: { $gt: 0 },
    expiration: { $gt: now }
  })
    .sort({ expiration: 1 }) // FEFO
    .select("batchNumber poolNumber bottleType availableBottles volume expiration status");

  const totalPasteurizedVolume = pasteurizedBatches.reduce(
    (acc, b) => acc + (b.availableBottles * (b.bottleType || 100)),
    0
  );

  res.status(200).json({
    success: true,
    request,
    stockPanel: {
      totalAvailableVolume: totalPasteurizedVolume,
      batches: pasteurizedBatches
    }
  });
});

// POST /api/v1/donor/request-milk
exports.donorSubmitMilkRequest = catchAsyncErrors(async (req, res, next) => {
  const {
    recipientName,
    recipientDob,
    relationToRecipient = "Mother / Guardian",
    hospitalOrHomeAddress,
    reasonForRequest,
    volumeRequested,
    feedingDurationDays = 7,
    additionalRemarks
  } = req.body;

  if (!recipientName || !volumeRequested || !reasonForRequest) {
    return next(new ErrorHandler("Please provide recipient name, requested volume, and reason", 400));
  }

  let patient = await Patient.findOne({
    "name.first": recipientName.split(" ")[0],
    "name.last": recipientName.split(" ").slice(1).join(" ") || "Child"
  });

  if (!patient) {
    patient = await Patient.create({
      name: {
        first: recipientName.split(" ")[0],
        last: recipientName.split(" ").slice(1).join(" ") || "Child"
      },
      patientType: "Outpatient",
      diagnosis: reasonForRequest,
      birthday: recipientDob ? new Date(recipientDob) : new Date(),
      home_address: {
        street: hospitalOrHomeAddress || "Pasig City",
        brgy: "Community",
        city: "Pasig City"
      }
    });
  }

  const vol = Number(volumeRequested) || 0;
  const days = Number(feedingDurationDays) || 7;

  const newRequest = await Request.create({
    patient: patient._id,
    recipientName: recipientName.trim(),
    relationToRecipient,
    requestedBy: req.user ? req.user._id : null,
    volumeRequested: {
      volume: vol,
      days: days
    },
    approvedVolume: vol,
    hospital: hospitalOrHomeAddress || "Pasig City Residence / PPDH",
    reason: reasonForRequest,
    additionalRemarks,
    notes: `Duration: ${days} days. ${additionalRemarks || ""}`,
    status: "Pending",
    date: new Date(),
    history: [
      {
        action: "SUBMITTED",
        actor: req.user?._id,
        actorName: req.user?.fullName || req.user?.username || "Donor",
        timestamp: new Date(),
        notes: `Submitted request for ${vol} ml.`
      }
    ]
  });

  patient.requested.push(newRequest._id);
  await patient.save();

  // Notify Admins & Staff
  await notifyStaffAndAdmins(
    "New Milk Request",
    `A new milk request for ${recipientName} (${vol} mL) was submitted by ${req.user?.fullName || "a donor"}.`
  );

  // Audit
  await createAudit({
    action: "CREATE_REQUEST",
    user: req.user?._id,
    userName: req.user?.fullName || req.user?.username,
    targetId: newRequest._id,
    reason: "Submitted by donor"
  });

  res.status(201).json({
    success: true,
    message: "Milk request submitted successfully. Awaiting healthcare personnel review.",
    request: newRequest
  });
});

// POST /api/v1/requests - Create on behalf of donor (walk-in/phone)
exports.createRequest = catchAsyncErrors(async (req, res, next) => {
  const {
    recipientName,
    relationToRecipient = "Mother / Guardian",
    volumeRequested,
    feedingDurationDays = 7,
    reasonForRequest,
    hospitalOrHomeAddress,
    additionalRemarks,
    donorAccountId
  } = req.body;

  if (!recipientName || !volumeRequested || !reasonForRequest) {
    return next(new ErrorHandler("Please provide recipient name, volume, and medical reason", 400));
  }

  const vol = Number(volumeRequested) || 0;
  const days = Number(feedingDurationDays) || 7;

  const newRequest = await Request.create({
    recipientName: recipientName.trim(),
    relationToRecipient,
    requestedBy: donorAccountId || req.user._id,
    volumeRequested: {
      volume: vol,
      days: days
    },
    approvedVolume: vol,
    hospital: hospitalOrHomeAddress || "Pasig City General Hospital",
    reason: reasonForRequest,
    additionalRemarks,
    status: "Pending",
    date: new Date(),
    history: [
      {
        action: "SUBMITTED_WALKIN",
        actor: req.user._id,
        actorName: req.user.fullName || req.user.username || "Staff",
        timestamp: new Date(),
        notes: `Created walk-in/phone request for ${vol} ml.`
      }
    ]
  });

  await createAudit({
    action: "CREATE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: newRequest._id,
    reason: "Created walk-in/phone request on behalf of donor"
  });

  res.status(201).json({
    success: true,
    message: "Request created successfully",
    request: newRequest
  });
});

// PUT /api/v1/request/:id/start-review - Start clinical review
exports.startClinicalReview = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  if (request.status !== "Pending") {
    return next(new ErrorHandler(`Cannot start review from ${request.status} status`, 400));
  }

  request.status = "Under Review";
  request.history.push({
    action: "STARTED_REVIEW",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: "Review started by staff."
  });

  await request.save();

  // Notify Donor
  await sendNotification(
    request.requestedBy,
    "Milk Request Under Review",
    `Your request #${request.requestNumber || request._id} for ${request.recipientName} is now under clinical assessment.`
  );

  await createAudit({
    action: "REVIEW_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: "Started clinical review"
  });

  res.status(200).json({
    success: true,
    message: "Request is now Under Review",
    request
  });
});

// PUT /api/v1/request/:id/record-review - Save assessment notes & eligibility decision
exports.recordClinicalReview = catchAsyncErrors(async (req, res, next) => {
  const { assessmentNotes, decision } = req.body;

  if (!assessmentNotes || !assessmentNotes.trim()) {
    return next(new ErrorHandler("Clinical assessment notes are required", 400));
  }
  if (!decision || !["Eligible", "Not Eligible"].includes(decision)) {
    return next(new ErrorHandler("Decision must be Eligible or Not Eligible", 400));
  }

  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  request.clinicalReview = {
    reviewedBy: req.user._id,
    reviewerName: req.user.fullName || req.user.username,
    reviewDate: new Date(),
    assessmentNotes: assessmentNotes.trim(),
    decision
  };

  request.history.push({
    action: "ASSESSED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: `Assessment completed: ${decision}. Notes: ${assessmentNotes}`
  });

  await request.save();

  await createAudit({
    action: "REVIEW_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: `Recorded clinical assessment: ${decision}`,
    details: { decision, assessmentNotes }
  });

  res.status(200).json({
    success: true,
    message: "Clinical review recorded successfully",
    request
  });
});

// PUT /api/v1/request/:id/approve - Approve with bottle reservation
exports.approveRequest = catchAsyncErrors(async (req, res, next) => {
  const { approvedVolume, allocatedBatches } = req.body;

  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  if (request.status !== "Under Review" && request.status !== "Pending") {
    return next(new ErrorHandler("Request must be Under Review to approve", 400));
  }

  if (!request.clinicalReview?.decision || request.clinicalReview.decision !== "Eligible") {
    return next(new ErrorHandler("Cannot approve: Clinical review decision must be recorded as Eligible first", 400));
  }

  if (!Array.isArray(allocatedBatches) || allocatedBatches.length === 0) {
    return next(new ErrorHandler("Please select at least one bottle batch to cover the volume", 400));
  }

  const now = new Date();
  let totalAllocatedVolume = 0;

  // Validate stock availability and lock bottles
  for (const item of allocatedBatches) {
    const inv = await Inventory.findById(item.invId);
    if (!inv || inv.isDeleted) {
      return next(new ErrorHandler(`Batch ${item.batch} not found or archived`, 400));
    }
    if (inv.expiration && new Date(inv.expiration) <= now) {
      return next(new ErrorHandler(`Batch ${item.batch} has expired and cannot be dispensed`, 400));
    }
    if (inv.availableBottles < item.bottlesAllocated) {
      return next(new ErrorHandler(
        `Insufficient stock for batch ${item.batch}: requested ${item.bottlesAllocated} bottle(s), only ${inv.availableBottles} available`,
        400
      ));
    }

    const bType = inv.bottleType || 100;
    totalAllocatedVolume += (item.bottlesAllocated * bType);
  }

  const appVol = Number(approvedVolume) || request.volumeRequested.volume;

  // Reserve bottles on inventory records
  for (const item of allocatedBatches) {
    await Inventory.findByIdAndUpdate(item.invId, {
      $inc: { availableBottles: -item.bottlesAllocated }
    });
  }

  request.status = "Approved";
  request.approvedVolume = appVol;
  request.allocatedBatches = allocatedBatches.map(b => ({
    invId: b.invId,
    batch: String(b.batch),
    pool: String(b.pool || ""),
    bottleType: b.bottleType,
    bottlesAllocated: b.bottlesAllocated,
    volDischarge: b.bottlesAllocated * b.bottleType,
    expiryDate: b.expiration
  }));

  request.history.push({
    action: "APPROVED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: `Approved volume: ${appVol} mL (${totalAllocatedVolume} mL allocated across ${allocatedBatches.length} batch(es)).`
  });

  await request.save();

  // Notify Donor
  await sendNotification(
    request.requestedBy,
    "Milk Request Approved",
    `Your request #${request.requestNumber || request._id} has been approved for ${appVol} mL. It is ready for schedule/fulfillment.`
  );

  await createAudit({
    action: "APPROVE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: `Approved ${appVol} mL`,
    details: { approvedVolume: appVol, allocatedBatches }
  });

  res.status(200).json({
    success: true,
    message: "Request approved and bottles reserved",
    request
  });
});

// PUT /api/v1/request/:id/reject - Reject with required reason
exports.rejectRequest = catchAsyncErrors(async (req, res, next) => {
  const { reason } = req.body;
  if (!reason || !reason.trim()) {
    return next(new ErrorHandler("A rejection reason is required", 400));
  }

  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  // Release any reserved bottles if it was approved
  if (request.status === "Approved" && request.allocatedBatches?.length > 0) {
    for (const b of request.allocatedBatches) {
      if (b.invId && b.bottlesAllocated > 0) {
        await Inventory.findByIdAndUpdate(b.invId, {
          $inc: { availableBottles: b.bottlesAllocated }
        });
      }
    }
  }

  request.status = "Rejected";
  request.rejectionReason = reason.trim();
  request.history.push({
    action: "REJECTED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: `Rejected with reason: ${reason}`
  });

  await request.save();

  // Notify donor
  await sendNotification(
    request.requestedBy,
    "Milk Request Update",
    `Your request #${request.requestNumber || request._id} was not approved: ${reason.trim()}`
  );

  await createAudit({
    action: "REJECT_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: reason.trim()
  });

  res.status(200).json({
    success: true,
    message: "Request rejected",
    request
  });
});

// PUT /api/v1/request/:id/fulfill - Fulfill/hand over bottles
exports.fulfillRequest = catchAsyncErrors(async (req, res, next) => {
  const { receiverName } = req.body;
  if (!receiverName || !receiverName.trim()) {
    return next(new ErrorHandler("Receiver's name is required for fulfillment", 400));
  }

  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  if (request.status !== "Approved") {
    return next(new ErrorHandler("Only Approved requests can be fulfilled", 400));
  }

  // Deduct actual volume & update status of inventory if bottles become 0
  for (const b of request.allocatedBatches) {
    if (b.invId) {
      const inv = await Inventory.findById(b.invId);
      if (inv) {
        if (inv.availableBottles <= 0) {
          inv.status = "Depleted";
        }
        await inv.save();
      }
    }
  }

  request.status = "Fulfilled";
  request.fulfillmentDetails = {
    fulfilledAt: new Date(),
    fulfilledBy: req.user._id,
    staffName: req.user.fullName || req.user.username,
    receiverName: receiverName.trim()
  };

  request.history.push({
    action: "FULFILLED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: `Handed over to ${receiverName.trim()} by ${req.user.fullName || req.user.username}.`
  });

  await request.save();

  // Notify donor
  await sendNotification(
    request.requestedBy,
    "Milk Request Handed Over",
    `Your requested milk has been fulfilled and received by ${receiverName.trim()}.`
  );

  await createAudit({
    action: "FULFILL_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: `Handed over to ${receiverName.trim()}`
  });

  res.status(200).json({
    success: true,
    message: "Request fulfilled successfully",
    request
  });
});

// PUT /api/v1/request/:id/cancel - Cancel with required reason
exports.cancelRequest = catchAsyncErrors(async (req, res, next) => {
  const { reason } = req.body;
  if (!reason || !reason.trim()) {
    return next(new ErrorHandler("A cancellation reason is required", 400));
  }

  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  // Release any reserved bottles
  if (request.status === "Approved" && request.allocatedBatches?.length > 0) {
    for (const b of request.allocatedBatches) {
      if (b.invId && b.bottlesAllocated > 0) {
        await Inventory.findByIdAndUpdate(b.invId, {
          $inc: { availableBottles: b.bottlesAllocated }
        });
      }
    }
  }

  request.status = "Cancelled";
  request.cancellationReason = reason.trim();
  request.history.push({
    action: "CANCELLED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: `Cancelled with reason: ${reason}`
  });

  await request.save();

  await sendNotification(
    request.requestedBy,
    "Milk Request Cancelled",
    `Your request #${request.requestNumber || request._id} was cancelled: ${reason.trim()}`
  );

  await createAudit({
    action: "CANCEL_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: reason.trim()
  });

  res.status(200).json({
    success: true,
    message: "Request cancelled",
    request
  });
});

// PUT /api/v1/request/:id - Edit pending request
exports.updateRequest = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  if (request.status !== "Pending") {
    return next(new ErrorHandler("Request fields can only be edited while status is Pending", 400));
  }

  const {
    recipientName,
    relationToRecipient,
    volumeRequested,
    feedingDurationDays,
    reasonForRequest,
    hospitalOrHomeAddress,
    additionalRemarks
  } = req.body;

  if (recipientName !== undefined) request.recipientName = recipientName.trim();
  if (relationToRecipient !== undefined) request.relationToRecipient = relationToRecipient;
  if (reasonForRequest !== undefined) request.reason = reasonForRequest;
  if (hospitalOrHomeAddress !== undefined) request.hospital = hospitalOrHomeAddress;
  if (additionalRemarks !== undefined) request.additionalRemarks = additionalRemarks;

  if (volumeRequested !== undefined) {
    request.volumeRequested.volume = Number(volumeRequested);
    request.approvedVolume = Number(volumeRequested);
  }
  if (feedingDurationDays !== undefined) {
    request.volumeRequested.days = Number(feedingDurationDays);
  }

  request.history.push({
    action: "EDITED",
    actor: req.user._id,
    actorName: req.user.fullName || req.user.username,
    timestamp: new Date(),
    notes: "Request fields updated."
  });

  await request.save();

  await createAudit({
    action: "UPDATE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: "Updated pending request fields"
  });

  res.status(200).json({
    success: true,
    message: "Request updated successfully",
    request
  });
});

// Archive Request
exports.softDeleteRequest = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findById(req.params.id);
  if (!request) {
    return next(new ErrorHandler("Request not found", 404));
  }

  if (!["Fulfilled", "Rejected", "Cancelled"].includes(request.status)) {
    return next(new ErrorHandler("Only Fulfilled, Rejected, or Cancelled requests can be archived", 400));
  }

  const archived = await Request.softDeleteById(req.params.id);

  await createAudit({
    action: "ARCHIVE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: request._id,
    reason: "Archived request"
  });

  res.status(200).json({
    success: true,
    message: "Request successfully archived",
    request: archived
  });
});

// Restore Request
exports.restoreRequest = catchAsyncErrors(async (req, res, next) => {
  const restored = await Request.restoreById(req.params.id);
  if (!restored) {
    return next(new ErrorHandler("Archived request not found", 404));
  }

  await createAudit({
    action: "RESTORE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: restored._id,
    reason: "Restored archived request"
  });

  res.status(200).json({
    success: true,
    message: "Request successfully restored",
    request: restored
  });
});

// Delete permanently (only from archived; block if fulfilled)
exports.deleteRequest = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findOne({ _id: req.params.id, isDeleted: true }).setOptions({ skipDeletedFilter: true });
  if (!request) {
    return next(new ErrorHandler("Permanent delete is only permitted on archived requests", 400));
  }

  if (request.status === "Fulfilled") {
    return next(new ErrorHandler("Fulfilled requests cannot be permanently deleted because inventory was dispensed. Keep it archived instead.", 400));
  }

  await Request.findByIdAndDelete(req.params.id);

  await createAudit({
    action: "DELETE_REQUEST",
    user: req.user._id,
    userName: req.user.fullName || req.user.username,
    targetId: req.params.id,
    reason: "Permanently deleted archived request"
  });

  res.status(200).json({
    success: true,
    message: "Request permanently deleted"
  });
});

// Donor my requests
exports.getMyMilkRequests = catchAsyncErrors(async (req, res, next) => {
  if (!req.user) return next(new ErrorHandler("Authentication required", 401));

  const requests = await Request.find({ requestedBy: req.user._id, isDeleted: false })
    .populate("clinicalReview.reviewedBy", "name username role")
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: requests.length,
    requests
  });
});

exports.archivedRequests = catchAsyncErrors(async (req, res, next) => {
  const requests = await Request.findOnlyDeleted()
    .populate("patient", "name")
    .populate("requestedBy", "name username phone email role")
    .sort({ deletedAt: -1 });

  res.status(200).json({
    success: true,
    count: requests.length,
    requests
  });
});

// Legacy backward-compatibility endpoints
exports.updateRequestStatus = catchAsyncErrors(async (req, res, next) => {
  const request = await Request.findById(req.params.id);
  if (!request) return next(new ErrorHandler("Request not found", 404));
  request.status = req.body.status || request.status;
  await request.save();
  res.status(200).json({ success: true, data: request });
});
exports.updateVolumeRequested = catchAsyncErrors(async (req, res, next) => {
  res.status(200).json({ success: true });
});
exports.inpatientDispense = catchAsyncErrors(async (req, res, next) => {
  res.status(200).json({ success: true });
});
exports.outpatientDispense = catchAsyncErrors(async (req, res, next) => {
  res.status(200).json({ success: true });
});
exports.myRequests = catchAsyncErrors(async (req, res, next) => {
  res.status(200).json({ success: true, count: 0, requests: [] });
});
