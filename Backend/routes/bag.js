const express = require('express');
const router = express.Router();


const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');
const { createBag, getDonorBags, getSingleBag, updateBag, deleteBag, allBags, updateTemp } = require('../controllers/bagController');

// Super Admin Routes
router.route('/bag')
    .post(isAuthenticatedUser, createBag);
router.route('/bags')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allBags);
// .get(isAuthenticatedUser, allInventories)
router.route('/bag/donor/:id')
    .get(isAuthenticatedUser, getDonorBags);

router.route('/bag/:id')
    .get(isAuthenticatedUser, getSingleBag)
    .put(isAuthenticatedUser, updateBag)
    .delete(isAuthenticatedUser, deleteBag)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin, Admin'), updateTemp)
//     .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateInventory)
//     .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), deleteInventory);


module.exports = router;