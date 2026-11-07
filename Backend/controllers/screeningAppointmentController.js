const ScreeningAppointment = require('../models/screeningAppointment');
const HospitalScreeningSchedule = require('../models/hospitalScreeningSchedule');
const Donor = require('../models/donor');
const User = require('../models/user');
const Notification = require('../models/notification');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');

// Default Hospital Schedule fallback if database configuration hasn't been seeded yet
const DEFAULT_HOSPITAL_SLOTS = [
  { slotTime: '08:30 AM - 09:30 AM', capacity: 3, isActive: true },
  { slotTime: '09:30 AM - 10:30 AM', capacity: 3, isActive: true },
  { slotTime: '10:30 AM - 11:30 AM', capacity: 3, isActive: true },
  { slotTime: '01:00 PM - 02:00 PM', capacity: 3, isActive: true },
  { slotTime: '02:00 PM - 03:00 PM', capacity: 3, isActive: true },
  { slotTime: '03:00 PM - 04:00 PM', capacity: 3, isActive: true },
];

const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// Helper to seed or get default hospital schedule
const getOrCreateScheduleForDay = async (dayOfWeek) => {
  let schedule = await HospitalScreeningSchedule.findOne({ dayOfWeek, isDeleted: false });
  if (!schedule) {
    const isWeekend = (dayOfWeek === 0 || dayOfWeek === 6);
    schedule = await HospitalScreeningSchedule.create({
      dayOfWeek,
      dayName: DAY_NAMES[dayOfWeek],
      timeSlots: isWeekend ? [] : DEFAULT_HOSPITAL_SLOTS,
      isActive: !isWeekend,
    });
  }
  return schedule;
};

// Helper: generate unique appointment ID: "APT-2026-0001"
const generateAppointmentId = async () => {
  const year = new Date().getFullYear();
  const prefix = `APT-${year}-`;
  const count = await ScreeningAppointment.countDocuments();
  return `${prefix}${String(count + 1).padStart(4, '0')}`;
};

// Helper to send in-app notification to a user
const createInAppNotification = async ({ userId, title, message, type = 'System' }) => {
  try {
    if (!userId) return;
    await Notification.create({
      recipient: userId,
      title,
      message,
      type,
    });
  } catch (err) {
    console.error('Failed to create notification:', err.message);
  }
};

// ============================================================================
// 1. GET AVAILABLE APPOINTMENT SLOTS FOR A GIVEN DATE
// GET /api/v1/screening/slots?date=YYYY-MM-DD
// ============================================================================
exports.getAvailableSlots = catchAsyncErrors(async (req, res, next) => {
  const { date } = req.query;
  if (!date) {
    return next(new ErrorHandler('Date query parameter (YYYY-MM-DD) is required', 400));
  }

  const queryDate = new Date(date);
  if (isNaN(queryDate.getTime())) {
    return next(new ErrorHandler('Invalid date format. Use YYYY-MM-DD', 400));
  }

  // Set boundary for full day
  const startOfDay = new Date(queryDate.getFullYear(), queryDate.getMonth(), queryDate.getDate(), 0, 0, 0, 0);
  const endOfDay = new Date(queryDate.getFullYear(), queryDate.getMonth(), queryDate.getDate(), 23, 59, 59, 999);

  const dayOfWeek = startOfDay.getDay(); // 0-6
  const schedule = await getOrCreateScheduleForDay(dayOfWeek);

  if (!schedule || !schedule.isActive) {
    return res.status(200).json({
      success: true,
      date: startOfDay.toISOString().split('T')[0],
      dayName: DAY_NAMES[dayOfWeek],
      isOpen: false,
      message: 'The hospital screening clinic is closed on this day.',
      slots: [],
    });
  }

  // Check special closed dates
  const isSpecialClosed = schedule.specialDates && schedule.specialDates.some(
    sd => sd.isClosed && sd.date && new Date(sd.date).toDateString() === startOfDay.toDateString()
  );
  if (isSpecialClosed) {
    return res.status(200).json({
      success: true,
      date: startOfDay.toISOString().split('T')[0],
      dayName: DAY_NAMES[dayOfWeek],
      isOpen: false,
      message: 'The clinic is closed for a hospital holiday or maintenance on this date.',
      slots: [],
    });
  }

  // Active bookings on this date (excluding cancelled/rejected)
  const activeAppointments = await ScreeningAppointment.find({
    appointmentDate: { $gte: startOfDay, $lte: endOfDay },
    status: { $nin: ['Cancelled by User', 'Rejected by Staff'] },
    isDeleted: false,
  });

  // Calculate booked counts per time slot
  const slotBookings = {};
  activeAppointments.forEach(apt => {
    slotBookings[apt.timeSlot] = (slotBookings[apt.timeSlot] || 0) + 1;
  });

  const slots = (schedule.timeSlots || [])
    .filter(s => s.isActive)
    .map(s => {
      const booked = slotBookings[s.slotTime] || 0;
      const remaining = Math.max(0, s.capacity - booked);
      return {
        slotTime: s.slotTime,
        capacity: s.capacity,
        booked,
        remaining,
        isAvailable: remaining > 0,
      };
    });

  res.status(200).json({
    success: true,
    date: startOfDay.toISOString().split('T')[0],
    dayName: DAY_NAMES[dayOfWeek],
    isOpen: true,
    totalSlots: slots.length,
    slots,
  });
});

// ============================================================================
// 2. USER BOOKS A SCREENING APPOINTMENT
// POST /api/v1/screening/book
// ============================================================================
exports.bookScreeningAppointment = catchAsyncErrors(async (req, res, next) => {
  const {
    appointmentDate,
    timeSlot,
    purpose = 'First-Time Donor Screening',
    donorNotes = '',
  } = req.body;

  if (!req.user) {
    return next(new ErrorHandler('Authentication required to book a screening appointment', 401));
  }

  if (!appointmentDate || !timeSlot) {
    return next(new ErrorHandler('Appointment date and time slot are required', 400));
  }

  const selectedDate = new Date(appointmentDate);
  if (isNaN(selectedDate.getTime())) {
    return next(new ErrorHandler('Invalid appointment date format', 400));
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const targetDay = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate(), 0, 0, 0, 0);

  if (targetDay < today) {
    return next(new ErrorHandler('Appointment date cannot be in the past', 400));
  }

  // 1. Prevent duplicate active appointments for the same user
  const existingActive = await ScreeningAppointment.findOne({
    user: req.user._id,
    status: { $in: ['Pending Confirmation', 'Confirmed', 'Rescheduled'] },
    isDeleted: false,
  });

  if (existingActive) {
    return res.status(409).json({
      success: false,
      message: 'You already have an active screening appointment. Please attend or reschedule your existing booking.',
      appointment: existingActive,
    });
  }

  // 2. Capacity conflict prevention for the chosen slot
  const startOfDay = new Date(targetDay);
  const endOfDay = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate(), 23, 59, 59, 999);

  const schedule = await getOrCreateScheduleForDay(targetDay.getDay());
  if (!schedule || !schedule.isActive) {
    return next(new ErrorHandler('The clinic is not accepting appointments on the selected day', 400));
  }

  const configuredSlot = (schedule.timeSlots || []).find(s => s.slotTime === timeSlot && s.isActive);
  const slotCapacity = configuredSlot ? configuredSlot.capacity : 3;

  const currentCount = await ScreeningAppointment.countDocuments({
    appointmentDate: { $gte: startOfDay, $lte: endOfDay },
    timeSlot,
    status: { $nin: ['Cancelled by User', 'Rejected by Staff'] },
    isDeleted: false,
  });

  if (currentCount >= slotCapacity) {
    return next(new ErrorHandler(`The selected time slot (${timeSlot}) is fully booked. Please select another time.`, 400));
  }

  // 3. Find associated donor record if user has one
  const donor = await Donor.findOne({ user: req.user._id, isDeleted: false });

  const appointmentId = await generateAppointmentId();

  const appointment = await ScreeningAppointment.create({
    appointmentId,
    user: req.user._id,
    donor: donor ? donor._id : null,
    purpose,
    appointmentDate: targetDay,
    timeSlot,
    donorNotes: donorNotes.trim(),
    status: 'Pending Confirmation',
    audit: {
      createdBy: req.user._id,
      updatedBy: req.user._id,
    },
  });

  // Notify user
  await createInAppNotification({
    userId: req.user._id,
    title: 'Screening Appointment Requested',
    message: `Your hospital screening appointment request for ${targetDay.toISOString().split('T')[0]} at ${timeSlot} has been submitted. Awaiting staff confirmation.`,
    type: 'Screening',
  });

  res.status(201).json({
    success: true,
    message: 'Screening appointment booked successfully. Our medical staff will confirm your slot.',
    appointment,
  });
});

// ============================================================================
// 3. USER CANCELS THEIR APPOINTMENT
// PUT /api/v1/screening/appointment/:id/cancel
// ============================================================================
exports.cancelScreeningAppointment = catchAsyncErrors(async (req, res, next) => {
  const { id } = req.params;
  const { reason = '' } = req.body;

  const appointment = await ScreeningAppointment.findById(id);
  if (!appointment || appointment.isDeleted) {
    return next(new ErrorHandler('Appointment not found', 404));
  }

  // Only the owner or staff can cancel
  const isOwner = appointment.user.toString() === req.user._id.toString();
  const isStaff = ['SuperAdmin', 'Admin', 'Staff'].includes(req.user.role);

  if (!isOwner && !isStaff) {
    return next(new ErrorHandler('Unauthorized to cancel this appointment', 403));
  }

  if (['Cancelled by User', 'Rejected by Staff', 'Completed', 'Attended'].includes(appointment.status)) {
    return next(new ErrorHandler(`Cannot cancel an appointment that is already ${appointment.status}`, 400));
  }

  appointment.status = isStaff ? 'Rejected by Staff' : 'Cancelled by User';
  appointment.statusReason = reason.trim() || (isStaff ? 'Cancelled by staff' : 'Cancelled by user');
  appointment.audit.updatedBy = req.user._id;

  await appointment.save();

  await createInAppNotification({
    userId: appointment.user,
    title: 'Screening Appointment Cancelled',
    message: `Your appointment for ${appointment.timeSlot} on ${new Date(appointment.appointmentDate).toISOString().split('T')[0]} has been cancelled.`,
    type: 'Screening',
  });

  res.status(200).json({
    success: true,
    message: 'Screening appointment cancelled successfully',
    appointment,
  });
});

// ============================================================================
// 4. USER OR STAFF RESCHEDULES APPOINTMENT
// PUT /api/v1/screening/appointment/:id/reschedule
// ============================================================================
exports.rescheduleScreeningAppointment = catchAsyncErrors(async (req, res, next) => {
  const { id } = req.params;
  const { newDate, newTimeSlot, reason = '' } = req.body;

  if (!newDate || !newTimeSlot) {
    return next(new ErrorHandler('New appointment date and time slot are required', 400));
  }

  const appointment = await ScreeningAppointment.findById(id);
  if (!appointment || appointment.isDeleted) {
    return next(new ErrorHandler('Appointment not found', 404));
  }

  const isOwner = appointment.user.toString() === req.user._id.toString();
  const isStaff = ['SuperAdmin', 'Admin', 'Staff'].includes(req.user.role);

  if (!isOwner && !isStaff) {
    return next(new ErrorHandler('Unauthorized to reschedule this appointment', 403));
  }

  const parsedDate = new Date(newDate);
  const targetDay = new Date(parsedDate.getFullYear(), parsedDate.getMonth(), parsedDate.getDate(), 0, 0, 0, 0);
  const endOfDay = new Date(parsedDate.getFullYear(), parsedDate.getMonth(), parsedDate.getDate(), 23, 59, 59, 999);

  // Capacity check
  const schedule = await getOrCreateScheduleForDay(targetDay.getDay());
  const configuredSlot = (schedule.timeSlots || []).find(s => s.slotTime === newTimeSlot && s.isActive);
  const slotCapacity = configuredSlot ? configuredSlot.capacity : 3;

  const currentCount = await ScreeningAppointment.countDocuments({
    _id: { $ne: appointment._id },
    appointmentDate: { $gte: targetDay, $lte: endOfDay },
    timeSlot: newTimeSlot,
    status: { $nin: ['Cancelled by User', 'Rejected by Staff'] },
    isDeleted: false,
  });

  if (currentCount >= slotCapacity) {
    return next(new ErrorHandler(`The new slot (${newTimeSlot}) is fully booked. Please choose another slot.`, 400));
  }

  // Push to history
  appointment.rescheduledHistory.push({
    previousDate: appointment.appointmentDate,
    previousTimeSlot: appointment.timeSlot,
    rescheduledBy: req.user._id,
    reason: reason.trim(),
    rescheduledAt: new Date(),
  });

  appointment.appointmentDate = targetDay;
  appointment.timeSlot = newTimeSlot;
  appointment.status = isStaff ? 'Confirmed' : 'Rescheduled';
  appointment.statusReason = reason.trim() || 'Rescheduled';
  appointment.audit.updatedBy = req.user._id;

  await appointment.save();

  await createInAppNotification({
    userId: appointment.user,
    title: 'Screening Appointment Rescheduled',
    message: `Your appointment has been rescheduled to ${targetDay.toISOString().split('T')[0]} at ${newTimeSlot}.`,
    type: 'Screening',
  });

  res.status(200).json({
    success: true,
    message: 'Appointment rescheduled successfully',
    appointment,
  });
});

// ============================================================================
// 5. GET USER'S APPOINTMENT HISTORY AND ACTIVE APPOINTMENT
// GET /api/v1/screening/my-appointments
// ============================================================================
exports.getMyScreeningAppointments = catchAsyncErrors(async (req, res, next) => {
  if (!req.user) {
    return next(new ErrorHandler('Authentication required', 401));
  }

  const appointments = await ScreeningAppointment.find({
    user: req.user._id,
    isDeleted: false,
  })
    .sort({ appointmentDate: -1, createdAt: -1 })
    .populate('assignedStaff', 'name username role')
    .populate('donor', 'donorId eligibility verified');

  const activeAppointment = appointments.find(a =>
    ['Pending Confirmation', 'Confirmed', 'Rescheduled'].includes(a.status)
  ) || null;

  res.status(200).json({
    success: true,
    count: appointments.length,
    activeAppointment,
    appointments,
  });
});

// ============================================================================
// 6. STAFF: LIST ALL APPOINTMENTS WITH FILTERS
// GET /api/v1/staff/screening/appointments
// ============================================================================
exports.staffGetScreeningAppointments = catchAsyncErrors(async (req, res, next) => {
  const { status, date, search, page = 1, pageSize = 20 } = req.query;
  const filter = { isDeleted: false };

  if (status) {
    filter.status = status;
  }

  if (date) {
    const d = new Date(date);
    if (!isNaN(d.getTime())) {
      const startOfDay = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
      const endOfDay = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
      filter.appointmentDate = { $gte: startOfDay, $lte: endOfDay };
    }
  }

  const pageNum = Math.max(1, parseInt(page, 10));
  const limitNum = Math.max(1, parseInt(pageSize, 10));
  const skip = (pageNum - 1) * limitNum;

  let query = ScreeningAppointment.find(filter)
    .sort({ appointmentDate: 1, timeSlot: 1 })
    .populate('user', 'name username phone email')
    .populate('donor', 'donorId name eligibility verified screening')
    .populate('assignedStaff', 'name username employeeID');

  const [appointments, total] = await Promise.all([
    query.skip(skip).limit(limitNum),
    ScreeningAppointment.countDocuments(filter),
  ]);

  // Summary counts
  const [pendingCount, confirmedCount, attendedCount, completedCount] = await Promise.all([
    ScreeningAppointment.countDocuments({ isDeleted: false, status: 'Pending Confirmation' }),
    ScreeningAppointment.countDocuments({ isDeleted: false, status: 'Confirmed' }),
    ScreeningAppointment.countDocuments({ isDeleted: false, status: 'Attended' }),
    ScreeningAppointment.countDocuments({ isDeleted: false, status: 'Completed' }),
  ]);

  res.status(200).json({
    success: true,
    summary: {
      total,
      pendingCount,
      confirmedCount,
      attendedCount,
      completedCount,
    },
    page: pageNum,
    pageSize: limitNum,
    totalPages: Math.ceil(total / limitNum),
    appointments,
  });
});

// ============================================================================
// 7. STAFF: CONFIRM OR REJECT APPOINTMENT
// PUT /api/v1/staff/screening/appointment/:id/status
// ============================================================================
exports.staffUpdateAppointmentStatus = catchAsyncErrors(async (req, res, next) => {
  const { id } = req.params;
  const { status, statusReason = '', assignedStaffId } = req.body;

  const validStatuses = [
    'Confirmed',
    'Rejected by Staff',
    'Attended',
    'Completed',
    'No Show',
    'Rescheduled',
  ];

  if (!validStatuses.includes(status)) {
    return next(new ErrorHandler(`Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400));
  }

  const appointment = await ScreeningAppointment.findById(id).populate('user');
  if (!appointment || appointment.isDeleted) {
    return next(new ErrorHandler('Appointment not found', 404));
  }

  appointment.status = status;
  if (statusReason) appointment.statusReason = statusReason.trim();
  if (assignedStaffId) appointment.assignedStaff = assignedStaffId;
  else if (!appointment.assignedStaff) appointment.assignedStaff = req.user._id;

  if (status === 'Attended') {
    appointment.attendanceRecorded = true;
    appointment.attendanceRecordedAt = new Date();
  }

  if (status === 'Completed') {
    appointment.screeningCompleted = true;
    appointment.screeningCompletedAt = new Date();
  }

  appointment.audit.updatedBy = req.user._id;
  await appointment.save();

  // Notify user
  await createInAppNotification({
    userId: appointment.user._id || appointment.user,
    title: `Screening Appointment ${status}`,
    message: `Your screening appointment for ${appointment.timeSlot} on ${new Date(appointment.appointmentDate).toISOString().split('T')[0]} is now marked as ${status}.`,
    type: 'Screening',
  });

  res.status(200).json({
    success: true,
    message: `Appointment status updated to ${status}`,
    appointment,
  });
});

// ============================================================================
// 8. STAFF: RECORD ATTENDANCE AND COMPLETE MEDICAL SCREENING VISIT
// POST /api/v1/staff/screening/appointment/:id/complete-screening
// ============================================================================
exports.staffCompleteMedicalScreening = catchAsyncErrors(async (req, res, next) => {
  const { id } = req.params;
  const {
    attendanceRecorded = true,
    screeningCompleted = true,
    staffReviewNotes = '',
    eligibilityDecisionRecommendation = 'Recommend Eligible',
    updateDonorEligibility = true,
    eligibilityStatus = 'Eligible', // 'Eligible', 'For Laboratory Verification', 'Temporarily Deferred', 'Not Eligible'
  } = req.body;

  const appointment = await ScreeningAppointment.findById(id);
  if (!appointment || appointment.isDeleted) {
    return next(new ErrorHandler('Appointment not found', 404));
  }

  appointment.attendanceRecorded = Boolean(attendanceRecorded);
  appointment.attendanceRecordedAt = new Date();
  appointment.screeningCompleted = Boolean(screeningCompleted);
  appointment.screeningCompletedAt = new Date();
  appointment.status = 'Completed';
  appointment.assignedStaff = req.user._id;
  appointment.staffReviewNotes = staffReviewNotes.trim();
  appointment.eligibilityDecisionRecommendation = eligibilityDecisionRecommendation;
  appointment.audit.updatedBy = req.user._id;

  await appointment.save();

  // If updateDonorEligibility is true, link or update donor record
  let donor = null;
  if (appointment.donor) {
    donor = await Donor.findById(appointment.donor);
  } else {
    donor = await Donor.findOne({ user: appointment.user, isDeleted: false });
  }

  if (donor && updateDonorEligibility) {
    donor.eligibility = eligibilityStatus;
    donor.verified = (eligibilityStatus === 'Eligible');
    if (!donor.screening) donor.screening = {};
    donor.screening.reviewedBy = req.user._id;
    donor.screening.reviewedAt = new Date();
    donor.screening.reviewNotes = (donor.screening.reviewNotes ? `${donor.screening.reviewNotes}\n` : '') +
      `Screening Visit Completed on ${new Date().toISOString().split('T')[0]}: ${staffReviewNotes}`;
    await donor.save();

    // Link donor to appointment if not linked
    if (!appointment.donor) {
      appointment.donor = donor._id;
      await appointment.save();
    }
  }

  // Notify user
  await createInAppNotification({
    userId: appointment.user,
    title: 'Hospital Screening Completed',
    message: `Your hospital screening visit has been recorded as Completed. Status: ${eligibilityStatus}.`,
    type: 'Screening',
  });

  res.status(200).json({
    success: true,
    message: 'Screening visit completed and donor record updated successfully.',
    appointment,
    donor,
  });
});
