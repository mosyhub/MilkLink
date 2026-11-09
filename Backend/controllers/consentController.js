const DonorConsent = require('../models/consent');
const Donor = require('../models/donor');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');

// Hospital-approved Standard Pasig City Human Milk Bank Consent Text
const PASIG_HMB_CONSENT_TEXT = `PASIG CITY HUMAN MILK BANK - ELECTRONIC DONOR CONSENT ()

1. I voluntarily agree to donate my excess breast milk to the Pasig City Human Milk Bank (MilkLink).
2. I certify that all personal, health, and medical information provided in my screening questionnaire is true and accurate.
3. I authorize the milk bank staff and designated healthcare personnel to review my laboratory test records (CBC, HIV, HBsAg, Anti-HCV) and use them solely for donation eligibility evaluation.
4. I understand that my donated breast milk will undergo inspection, pasteurization, microbiological testing, and quality control review before being dispensed to vulnerable infants.
5. I understand that this donation is altruistic and free of charge, with no financial compensation.
6. In compliance with the Data Privacy Act of 2012 (R.A. 10173), I understand that my personal information will remain confidential and protected.`;

// Get Approved Consent Template => /api/v1/consent/template
exports.getConsentTemplate = catchAsyncErrors(async (req, res, next) => {
    res.status(200).json({
        success: true,
        version: '1.0',
        title: 'Pasig City Human Milk Bank Electronic Donor Consent Form',
        consentText: PASIG_HMB_CONSENT_TEXT
    });
});

// Submit Signed Consent => /api/v1/consent/sign
exports.submitSignedConsent = catchAsyncErrors(async (req, res, next) => {
    const { donorId, acknowledged, signatureDataUrl, signerName, consentVersion = '1.0' } = req.body;

    if (!acknowledged) {
        return next(new ErrorHandler('You must check and confirm the acknowledgment statement', 400));
    }
    if (!signatureDataUrl || !signatureDataUrl.trim()) {
        return next(new ErrorHandler('Electronic signature cannot be empty', 400));
    }
    if (!signerName || !signerName.trim()) {
        return next(new ErrorHandler('Signer name is required', 400));
    }

    // Resolve donor record either by ID or current logged in user
    let donor;
    if (donorId) {
        donor = await Donor.findById(donorId);
    } else if (req.user) {
        donor = await Donor.findOne({ user: req.user._id, isDeleted: false });
    }

    if (!donor) {
        return next(new ErrorHandler('Associated donor record not found', 404));
    }

    // Mark previous active consents as Superseded if renewing
    await DonorConsent.updateMany(
        { donor: donor._id, status: 'Active' },
        { status: 'Superseded', renewedAt: new Date() }
    );

    const consent = await DonorConsent.create({
        donor: donor._id,
        user: req.user ? req.user._id : donor.user,
        consentVersion,
        consentText: PASIG_HMB_CONSENT_TEXT,
        acknowledged: true,
        signatureDataUrl,
        signerName: signerName.trim(),
        signedAt: new Date(),
        ipAddress: req.ip || req.connection.remoteAddress,
        userAgent: req.headers['user-agent'] || '',
        status: 'Active',
        audit: {
            recordedBy: req.user ? req.user._id : null
        }
    });

    // Update donor screening consent fields
    if (!donor.screening) donor.screening = {};
    donor.screening.consentSigned = true;
    donor.screening.consentDate = consent.signedAt;
    donor.screening.consentVersion = consent.consentVersion;
    donor.screening.signatureUrl = consent.signatureDataUrl;
    await donor.save();

    res.status(201).json({
        success: true,
        message: 'Electronic consent form signed and recorded successfully.',
        consentId: consent._id,
        signedAt: consent.signedAt,
        donorId: donor.donorId,
        consent
    });
});

// Get Donor Consent History => /api/v1/consent/donor/:donorId
exports.getDonorConsent = catchAsyncErrors(async (req, res, next) => {
    const { donorId } = req.params;

    const consents = await DonorConsent.find({ donor: donorId, isDeleted: false })
        .sort({ signedAt: -1 })
        .populate('donor', 'donorId name eligibility');

    res.status(200).json({
        success: true,
        count: consents.length,
        consents
    });
});
