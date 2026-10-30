const express = require('express');
const router = express.Router();

const { 
    allPatients,
    createPatient,
    getPatientDetails,
    updatePatient,
    deletePatient,
    tallyCreatePatient,
} = require('../controllers/patientController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.route('/patients')
    .get(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), allPatients)
    .post(isAuthenticatedUser, authorizeRoles('Staff','SuperAdmin', 'Admin'), createPatient);
router.route('/patient/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getPatientDetails)
    .put(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), updatePatient)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deletePatient);

router.route('/tally/patient').post(tallyCreatePatient)


module.exports = router;