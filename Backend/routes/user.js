const express = require('express');
const router = express.Router();

const { registerUser, 
    loginUser, 
    logout, 
    forgotPassword, 
    resetPassword, 
    getUserProfile, 
    updatePassword, 
    updateProfile,
    allUsers,
    getUserDetails,
    updateUser,
    deleteUser,
    allStaffs,
    getStaffDetails,
    updateStaff,
    deleteStaff,
    
} = require('../controllers/userController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

// All Users Routes
router.route('/register').post(registerUser);
router.route('/login').post(loginUser);
router.route('/password/reset').post(forgotPassword);
router.route('/password/reset/:token').put( resetPassword );

router.route('/logout').get(logout);

router.route('/me').get( isAuthenticatedUser, getUserProfile);
router.route('/password/update').put(isAuthenticatedUser, updatePassword);
router.route('/me/update').put(isAuthenticatedUser, updateProfile);

// Super Admin Routes
router.route('/super/users').get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), allUsers);
router.route('/super/user/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin'), getUserDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin'), updateUser)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin'), deleteUser);

// Admin Routes
router.route('/admin/users').get(isAuthenticatedUser, authorizeRoles('Admin'), allStaffs);
router.route('/admin/user/:id')
    .get(isAuthenticatedUser, authorizeRoles('Admin'), getStaffDetails)
    .put(isAuthenticatedUser, authorizeRoles('Admin'), updateStaff)
    .delete(isAuthenticatedUser, authorizeRoles('Admin'), deleteStaff);


module.exports = router;