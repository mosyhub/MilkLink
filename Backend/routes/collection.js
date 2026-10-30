const express = require('express');
const router = express.Router();

const { 
    allCollections,
    createCollection,
    getCollectionDetails,
    updateCollection,
    deleteCollection,
    recordPublicDonation,
    recordPrivateDonation,
    getCollections
} = require('../controllers/collectController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.route('/collections')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getCollections)
router.route('/allCollections')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allCollections)
//     .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createCollection);
router.route('/collection/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getCollectionDetails)
//     .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateCollection)
//     .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteCollection);

// Route for recording Public Donation (Milk Letting)
router.route('/record-public')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), recordPublicDonation)

// Route for recording Private Donation (Scheduled Pickup)
router.route('/record-private')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), recordPrivateDonation)

module.exports = router;