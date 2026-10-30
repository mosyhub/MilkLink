const express = require('express');
const router = express.Router();

const {
    allFridges,
    createFridge,
    getFridgeDetails,
    updateFridge,
    deleteFridge,
    openFridge
} = require('../controllers/fridgeController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.route('/fridges')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allFridges)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createFridge);
router.route('/fridge/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getFridgeDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateFridge)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteFridge);

router.route('/fridge/open/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), openFridge);

module.exports = router;