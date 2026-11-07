const express = require('express');
const router = express.Router();

const {
    getConsentTemplate,
    submitSignedConsent,
    getDonorConsent
} = require('../controllers/consentController');

const { isAuthenticatedUser, authorizeRoles } = require('../middlewares/auth');

router.get('/consent/template', getConsentTemplate);
router.post('/consent/sign', submitSignedConsent);
router.get('/consent/donor/:donorId', isAuthenticatedUser, getDonorConsent);

module.exports = router;
