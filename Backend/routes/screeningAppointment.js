const express = require('express');
const router = express.Router();
const {
  getAvailableSlots,
  bookScreeningAppointment,
  cancelScreeningAppointment,
  rescheduleScreeningAppointment,
  getMyScreeningAppointments,
  staffGetScreeningAppointments,
  staffUpdateAppointmentStatus,
  staffCompleteMedicalScreening,
} = require('../controllers/screeningAppointmentController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Public or Authenticated User Routes
router.route('/screening/slots').get(getAvailableSlots);
router.route('/screening/book').post(isAuthenticatedUser, bookScreeningAppointment);
router.route('/screening/my-appointments').get(isAuthenticatedUser, getMyScreeningAppointments);
router.route('/screening/appointment/:id/cancel').put(isAuthenticatedUser, cancelScreeningAppointment);
router.route('/screening/appointment/:id/reschedule').put(isAuthenticatedUser, rescheduleScreeningAppointment);

// Staff / Admin Management Routes
router.route('/staff/screening/appointments').get(
  isAuthenticatedUser,
  authorizeRoles('SuperAdmin', 'Admin', 'Staff'),
  staffGetScreeningAppointments
);
router.route('/staff/screening/appointment/:id/status').put(
  isAuthenticatedUser,
  authorizeRoles('SuperAdmin', 'Admin', 'Staff'),
  staffUpdateAppointmentStatus
);
router.route('/staff/screening/appointment/:id/complete-screening').post(
  isAuthenticatedUser,
  authorizeRoles('SuperAdmin', 'Admin', 'Staff'),
  staffCompleteMedicalScreening
);

module.exports = router;
