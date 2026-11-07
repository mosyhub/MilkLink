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
    registerFirstTimeDonor,
    searchReturningDonor,
    recordReturningDonation,
    getPendingOnlineRegistrations,
    staffLinkUserToDonor,
    staffCreateDonorForUser,
} = require('../controllers/donorController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Public & shared routes
router.post('/donor/register', registerFirstTimeDonor);
router.get('/donor/search-returning', searchReturningDonor);
router.post('/donor/:id/record-donation', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), recordReturningDonation);
router.get('/donor/me', isAuthenticatedUser, getMyDonorProfile);

// Staff / Admin routes
router.get('/staff/pending-registrations', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getPendingOnlineRegistrations);
router.post('/staff/user/:userId/link-donor', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), staffLinkUserToDonor);
router.post('/staff/user/:userId/create-donor', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), staffCreateDonorForUser);
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
