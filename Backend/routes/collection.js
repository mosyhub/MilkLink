const express = require('express');
const router = express.Router();

const { 
    allCollections,
    createCollection,
    getCollectionDetails,
    updateCollection,
    softDeleteCollection,
    restoreCollection,
    deleteCollection,
    recordPublicDonation,
    recordPrivateDonation,
    getCollections
} = require('../controllers/collectController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

const allowedRoles = authorizeRoles('SuperAdmin', 'Admin', 'Staff');

router.route('/collections')
    .get(isAuthenticatedUser, allowedRoles, allCollections);

router.route('/allCollections')
    .get(isAuthenticatedUser, allowedRoles, allCollections);

router.route('/collection/:id')
    .get(isAuthenticatedUser, allowedRoles, getCollectionDetails)
    .put(isAuthenticatedUser, allowedRoles, updateCollection)
    .delete(isAuthenticatedUser, allowedRoles, deleteCollection);

router.route('/collection/:id/soft-delete')
    .put(isAuthenticatedUser, allowedRoles, softDeleteCollection);

router.route('/collection/:id/restore')
    .put(isAuthenticatedUser, allowedRoles, restoreCollection);

// Route for recording Public Donation (Milk Letting)
router.route('/record-public')
    .post(isAuthenticatedUser, allowedRoles, recordPublicDonation);

// Route for recording Private Donation (Scheduled Pickup)
router.route('/record-private')
    .post(isAuthenticatedUser, allowedRoles, recordPrivateDonation);

module.exports = router;
