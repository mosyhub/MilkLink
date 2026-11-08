const express = require('express');
const router = express.Router();

const {
    allSchedules,
    createSchedule,
    getScheduleDetails,
    updateSchedule,
    deleteSchedule,
    requestSchedule,
    approveSchedule,
    getDonorSchedules,
    updateStatus,
    archivedSchedules,
    softDeleteSchedule,
    restoreSchedule,
    getBookedSlots
} = require('../controllers/scheduleController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.route('/schedules')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), allSchedules)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), createSchedule);
router.route('/schedules/booked-slots')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getBookedSlots);
router.route('/schedule/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getScheduleDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateSchedule)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), deleteSchedule);

router.get('/schedules/archived', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), archivedSchedules);
router.put('/schedule/:id/soft-delete', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), softDeleteSchedule);
router.put('/schedule/:id/restore', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), restoreSchedule);

router.route('/me/schedules/:id')
    .get(isAuthenticatedUser, getDonorSchedules);

// Route to request a pickup schedule
router.route('/request-schedule')
    .post(requestSchedule);

// Route to approve or modify a pickup schedule
router.route('/approve-schedule')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), approveSchedule);

router.route('/update-schedule')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateStatus);


module.exports = router;