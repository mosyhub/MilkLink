const express = require('express');
const router = express.Router();


const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');
const { updateSignatories, createSignatories, getSignatories } = require('../controllers/signatoriesController');

router.route('/update/signatories/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), updateSignatories);

router.route('/signatories')
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), createSignatories)
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), getSignatories);
module.exports = router;