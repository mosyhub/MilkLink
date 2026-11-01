const express = require('express');
const router = express.Router();

const { 
    allDonors,
    getDonorDetails,
    updateDonor,
    deleteDonor,
    softDeleteDonor,
    restoreDonor,
    archivedDonors,
    getNewSubmissions,
    getMyDonorProfile,
    staffCreateDonor,
    generateDonorClaimToken,
    updateDonorScreeningStatus,
    getStaffDonorDashboard,
} = require('../controllers/donorController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Public & shared routes
router.get('/donor/me', isAuthenticatedUser, getMyDonorProfile);

// Staff / Admin routes
router.get('/donor/submissions', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getNewSubmissions);
router.get('/donors/archived', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), archivedDonors);
router.get('/staff/donors/dashboard', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getStaffDonorDashboard);
router.post('/staff/donor', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), staffCreateDonor);
router.post('/donor/:id/claim-token', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), generateDonorClaimToken);
router.put('/donor/:id/screening-status', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateDonorScreeningStatus);

router.route('/donors')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), allDonors);

router.route('/donor/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getDonorDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateDonor)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), deleteDonor);

router.route('/donor/:id/soft-delete')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), softDeleteDonor);

router.route('/donor/:id/restore')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), restoreDonor);

module.exports = router;
