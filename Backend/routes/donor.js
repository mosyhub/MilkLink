const express = require('express');
const router = express.Router();

const { 
    allDonors,
    createDonor,
    getDonorDetails,
    updateDonor,
    deleteDonor,
    testDonors,
    predictEligibility,
    checkEligibility,
    getNewSubmissions,
    getMyDonorProfile,
} = require('../controllers/donorController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.post('/test-donor', testDonors);
router.post('/predict', predictEligibility);
router.get('/check-eligibility/:id', checkEligibility);
router.get('/donor/submissions', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getNewSubmissions);
router.get('/donor/me', isAuthenticatedUser, getMyDonorProfile);
router.route('/donors')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allDonors)
    .post(createDonor);
    // .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createDonor);
router.route('/donor/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getDonorDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateDonor)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteDonor);



module.exports = router;