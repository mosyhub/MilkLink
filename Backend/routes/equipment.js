const express = require('express');
const router = express.Router();

const { 
    allEquipments,
    createEquipment,
    getEquipmentDetails,
    updateEquipment,
    deleteEquipment,
} = require('../controllers/equipController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// Super Admin Routes
router.route('/equipments')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allEquipments)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createEquipment);
router.route('/equipment/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getEquipmentDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateEquipment)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteEquipment);


module.exports = router;