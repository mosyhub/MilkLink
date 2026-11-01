const express = require('express');
const router = express.Router();

const { 
    allRequests,
    createRequest,
    getRequestDetails,
    updateRequest,
    deleteRequest,
    softDeleteRequest,
    restoreRequest,
    archivedRequests,
    updateRequestStatus,
    myRequests,
    updateVolumeRequested,
    inpatientDispense,
    outpatientDispense
} = require('../controllers/requestController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.get('/requests/archived', isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), archivedRequests);

router.route('/requests')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), allRequests)
    .post(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), createRequest);

router.route('/request/:id')
    .get(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), getRequestDetails)
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateRequest)
    .delete(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), deleteRequest);

router.route('/request/:id/soft-delete')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), softDeleteRequest);

router.route('/request/:id/restore')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), restoreRequest);

router.route('/request/:id/volume')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateVolumeRequested);

router.route('/request-status/:id')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff'), updateRequestStatus);

router.route('/myRequests/:id')
    .get(isAuthenticatedUser, authorizeRoles('Staff', 'Admin'), myRequests);

router.route('/inpatient-dispense')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), inpatientDispense);

router.route('/outpatient-dispense')
    .put(isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin'), outpatientDispense);

module.exports = router;
