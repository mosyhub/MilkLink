const express = require('express');
const router = express.Router();
const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');
const {
    getAccounts,
    getAccountById,
    createAccount,
    updateAccountRole,
    deactivateAccount,
    reactivateAccount,
    deleteAccount
} = require('../controllers/accountController');

const adminOnly = [isAuthenticatedUser, authorizeRoles('Admin', 'SuperAdmin')];

router.get('/admin/accounts', ...adminOnly, getAccounts);
router.post('/admin/accounts', ...adminOnly, createAccount);
router.get('/admin/account/:id', ...adminOnly, getAccountById);
router.put('/admin/account/:id/role', ...adminOnly, updateAccountRole);
router.put('/admin/account/:id/deactivate', ...adminOnly, deactivateAccount);
router.put('/admin/account/:id/reactivate', ...adminOnly, reactivateAccount);
router.delete('/admin/account/:id', ...adminOnly, deleteAccount);

module.exports = router;

