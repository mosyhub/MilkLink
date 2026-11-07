const express = require('express');
const router = express.Router();

const {
    getCollectionOutposts,
    createPickupRequest,
    getMyPickupHistory,
    updatePickupStatus,
    getAllPickups
} = require('../controllers/pickupController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.get('/pickup/outposts', getCollectionOutposts);
router.post('/pickup/request', isAuthenticatedUser, createPickupRequest);
router.get('/pickup/my-history', isAuthenticatedUser, getMyPickupHistory);

// Staff routes
router.get('/staff/pickups', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getAllPickups);
router.put('/pickup/:id/status', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updatePickupStatus);

module.exports = router;
