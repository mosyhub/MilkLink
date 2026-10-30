const express = require('express');
const router = express.Router();
const Letting = require('../models/letting');
const {
    allInventories,
    createInventory,
    getInventoryDetails,
    updateInventory,
    deleteInventory,
    updateInventoryStatus,
    reserveInventoryForRequest,
    returnBagsFromFridge,
    updateAllInventoriesStatus,
} = require('../controllers/inventoryController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.route('/inventories')
    .get(isAuthenticatedUser, allInventories)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createInventory);
router.route('/inventory/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getInventoryDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateInventory)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteInventory);

router.route('/inventory-status/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateInventoryStatus)

router.route('/check-inventories').put(updateAllInventoriesStatus)

router.route('/reserved-bottle/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), reserveInventoryForRequest)

module.exports = router;