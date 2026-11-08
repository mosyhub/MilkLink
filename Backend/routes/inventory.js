const express = require('express');
const router = express.Router();

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
    pasteurize,
    getFefoPreview,
    fulfillRequest,
    updateInventoryEntry,
    deleteInventoryEntry,
    softDeleteInventory,
    restoreInventory,
} = require('../controllers/inventoryController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

const allowedRoles = authorizeRoles('SuperAdmin', 'Admin', 'Staff');

router.route('/inventories')
    .get(isAuthenticatedUser, allowedRoles, allInventories)
    .post(isAuthenticatedUser, allowedRoles, createInventory);

// Pasteurization endpoint
router.route('/inventories/pasteurize')
    .post(isAuthenticatedUser, allowedRoles, pasteurize);

// FEFO Preview and Fulfill Request
router.route('/inventories/fefo-preview')
    .get(isAuthenticatedUser, allowedRoles, getFefoPreview);

router.route('/inventories/fulfill-request')
    .post(isAuthenticatedUser, allowedRoles, fulfillRequest);

router.route('/inventory/:id')
    .get(isAuthenticatedUser, allowedRoles, getInventoryDetails)
    .put(isAuthenticatedUser, allowedRoles, updateInventoryEntry)
    .delete(isAuthenticatedUser, allowedRoles, deleteInventoryEntry);

router.route('/inventory/:id/soft-delete')
    .put(isAuthenticatedUser, allowedRoles, softDeleteInventory);

router.route('/inventory/:id/restore')
    .put(isAuthenticatedUser, allowedRoles, restoreInventory);

router.route('/inventory-status/:id')
    .put(isAuthenticatedUser, allowedRoles, updateInventoryStatus);

router.route('/check-inventories')
    .put(updateAllInventoriesStatus);

router.route('/reserved-bottle/:id')
    .put(isAuthenticatedUser, allowedRoles, reserveInventoryForRequest);

module.exports = router;
