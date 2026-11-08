const express = require('express');
const router = express.Router();

const {
    allFridges,
    archivedFridges,
    createFridge,
    getFridgeDetails,
    updateFridge,
    deleteFridge,
    softDeleteFridge,
    restoreFridge,
    getFridgeEntries,
    openFridge
} = require('../controllers/fridgeController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

const allowedRoles = authorizeRoles('SuperAdmin', 'Admin', 'Staff');

router.route('/fridges')
    .get(isAuthenticatedUser, allowedRoles, allFridges)
    .post(isAuthenticatedUser, allowedRoles, createFridge);

router.route('/fridges/archived')
    .get(isAuthenticatedUser, allowedRoles, archivedFridges);

router.route('/fridge/:id')
    .get(isAuthenticatedUser, allowedRoles, getFridgeDetails)
    .put(isAuthenticatedUser, allowedRoles, updateFridge)
    .delete(isAuthenticatedUser, allowedRoles, deleteFridge);

router.route('/fridge/:id/soft-delete')
    .put(isAuthenticatedUser, allowedRoles, softDeleteFridge);

router.route('/fridge/:id/restore')
    .put(isAuthenticatedUser, allowedRoles, restoreFridge);

router.route('/fridge/:id/entries')
    .get(isAuthenticatedUser, allowedRoles, getFridgeEntries);

router.route('/fridge/open/:id')
    .get(isAuthenticatedUser, allowedRoles, openFridge);

module.exports = router;
