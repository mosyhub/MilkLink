const express = require('express');
const router = express.Router();

const { 
    allPatients,
    getPatientDetails,
    updatePatient,
    deletePatient,
    softDeletePatient,
    restorePatient,
    archivedPatients,
    staffCreatePatient,
    generatePatientClaimToken,
    getStaffPatientDashboard,
} = require('../controllers/patientController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.get('/patients/archived', isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), archivedPatients);
router.get('/staff/patients/dashboard', isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), getStaffPatientDashboard);
router.post('/staff/patient', isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), staffCreatePatient);
router.post('/patient/:id/claim-token', isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), generatePatientClaimToken);

router.route('/patients')
    .get(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), allPatients);

router.route('/patient/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getPatientDetails)
    .put(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), updatePatient)
    .delete(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), deletePatient);

router.route('/patient/:id/soft-delete')
    .put(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), softDeletePatient);

router.route('/patient/:id/restore')
    .put(isAuthenticatedUser, authorizeRoles('Staff', 'SuperAdmin', 'Admin'), restorePatient);

module.exports = router;
