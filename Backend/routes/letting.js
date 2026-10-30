const express = require('express');
const router = express.Router();

const {
    allLettings,
    createLetting,
    getLettingDetails,
    updateLetting,
    deleteletting,
    createEvent,
    markAttendance,
    finalizeSession,
    newPublicDonor,
    getUpcomingLettings,
    newPublicDonorTally,
    updateAttendance,
    checkLettingBagStatus,
    
    deleteAttendance,
} = require('../controllers/lettingController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');


router.get('/upcoming/lettings', getUpcomingLettings)

router.route('/lettings')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allLettings)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createLetting);
router.route('/letting/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getLettingDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateLetting)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteletting);

// Route to create a new Milk Letting Event
router.route('/create-letting')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createEvent);

// Route to mark attendance for donors
router.route('/mark-attendance')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), markAttendance);

// Route to finalize the Milk Letting Session
router.route('/finalize-session')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), finalizeSession);
router.route('/letting-newDonor')
    .post(isAuthenticatedUser, newPublicDonor);
router.route('/tally/newDonor')
    .post(newPublicDonorTally)
router.route('/additional-bags/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateAttendance)

router.route('/lettings/:lettingId/attendance/:attendanceId')
    .delete(isAuthenticatedUser, authorizeRoles("SuperAdmin", "Admin"), deleteAttendance);
module.exports = router;