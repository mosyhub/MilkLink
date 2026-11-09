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
    outpatientDispense,
    donorSubmitMilkRequest,
    getMyMilkRequests,
    startClinicalReview,
    recordClinicalReview,
    approveRequest,
    rejectRequest,
    fulfillRequest,
    cancelRequest
} = require('../controllers/requestController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

const staffAndAdmin = [isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin', 'Staff')];

// Donor Milk Request Routes
router.post('/donor/request-milk', isAuthenticatedUser, donorSubmitMilkRequest);
router.get('/donor/my-requests', isAuthenticatedUser, getMyMilkRequests);

// Staff and Admin routes
router.get('/requests/archived', ...staffAndAdmin, archivedRequests);

router.route('/requests')
    .get(...staffAndAdmin, allRequests)
    .post(...staffAndAdmin, createRequest);

router.route('/request/:id')
    .get(...staffAndAdmin, getRequestDetails)
    .put(...staffAndAdmin, updateRequest)
    .delete(...staffAndAdmin, deleteRequest);

router.route('/request/:id/archive')
    .put(...staffAndAdmin, softDeleteRequest);

router.route('/request/:id/restore')
    .put(...staffAndAdmin, restoreRequest);

// Workflow endpoints
router.route('/request/:id/start-review')
    .put(...staffAndAdmin, startClinicalReview);

router.route('/request/:id/record-review')
    .put(...staffAndAdmin, recordClinicalReview);

router.route('/request/:id/approve')
    .put(...staffAndAdmin, approveRequest);

router.route('/request/:id/reject')
    .put(...staffAndAdmin, rejectRequest);

router.route('/request/:id/fulfill')
    .put(...staffAndAdmin, fulfillRequest);

router.route('/request/:id/cancel')
    .put(...staffAndAdmin, cancelRequest);

// Legacy compat
router.route('/request/:id/soft-delete')
    .put(...staffAndAdmin, softDeleteRequest);
router.route('/request/:id/volume')
    .put(...staffAndAdmin, updateVolumeRequested);
router.route('/request-status/:id')
    .put(...staffAndAdmin, updateRequestStatus);
router.route('/myRequests/:id')
    .get(...staffAndAdmin, myRequests);
router.route('/inpatient-dispense')
    .put(...staffAndAdmin, inpatientDispense);
router.route('/outpatient-dispense')
    .put(...staffAndAdmin, outpatientDispense);

module.exports = router;
