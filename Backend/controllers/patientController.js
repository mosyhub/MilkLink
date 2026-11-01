const Patient = require('../models/patient')
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const { generateClaimCredentials } = require('../utils/qrHelper');

// Get All Patients => /api/v1/patients
exports.allPatients = catchAsyncErrors(async (req, res, next) => {
    // Destructure search query parameters from the request
    const { search, type, brgy } = req.query;

    // Create a query object to hold the search criteria
    const query = {};

    if (search) {
        query.$or = [
            { 'name': { $regex: search, $options: 'i' } },
            { 'patientType': { $regex: search, $options: 'i' } },

        ];
    }
    if (type) {
        query.patientType = type;
    }
    if (brgy) {
        query['home_address.brgy'] = brgy;
    }

    // Optional: Add pagination (e.g., limit results and skip for page number)
    const page = Number(req.query.page) || 1;
    const pageSize = 12; // Adjust page size as needed
    const skip = (page - 1) * pageSize;

    try {
        // Find donors based on the query object
        const patients = await Patient.find(query)
            .populate('requested', 'date volumeRequested')
            .sort({ name: 1 })

        const totalPatients = await Patient.countDocuments(query);
        const totalPages = Math.ceil(totalPatients / pageSize);


        res.status(200).json({
            success: true,
            totalPatients,
            totalPages,
            pageSize,
            patients
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }


})

// Get specific Patient details => /api/v1/patient/:id
exports.getPatientDetails = catchAsyncErrors(async (req, res, next) => {
    const patient = await Patient.findById(req.params.id)
        .populate([{ path: 'requested' }, { path: 'staff', select: 'name' }]);

    if (!patient) {
        return next(new ErrorHandler(`Patient is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        patient
    })
})

// Update Patient => /api/v1/patient/:id
exports.updatePatient = catchAsyncErrors(async (req, res, next) => {

    const patient = await Patient.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        patient
    })

})

// Delete Patient => /api/v1/patient/:id
exports.deletePatient = catchAsyncErrors(async (req, res, next) => {
    const patient = await Patient.findById(req.params.id);

    if (!patient) {
        return next(new ErrorHandler(`Patient is not found with this id: ${req.params.id}`))
    }

    await Patient.deleteOne();

    res.status(200).json({
        success: true,
        message: "Patient Deleted"
    })
})

// Soft Delete (Archive) Patient => /api/v1/patient/:id/soft-delete
exports.softDeletePatient = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const patient = await Patient.softDeleteById(cleanId);

    if (!patient) {
        return next(new ErrorHandler(`Patient not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Patient successfully archived',
        patient,
    });
});

// Restore Patient => /api/v1/patient/:id/restore
exports.restorePatient = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const patient = await Patient.restoreById(cleanId);

    if (!patient) {
        return next(new ErrorHandler(`Archived patient not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Patient successfully restored',
        patient,
    });
});

// Get Archived Patients => /api/v1/patients/archived
exports.archivedPatients = catchAsyncErrors(async (req, res) => {
    const patients = await Patient.findOnlyDeleted()
        .populate('requested', 'date volumeRequested')
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: patients.length,
        patients,
    });
});

// ============================================================================
// FLOW B - STEP 1: STAFF CREATES UNCLAIMED PATIENT RECORD
// ============================================================================
// Staff Register Patient => POST /api/v1/staff/patient
exports.staffCreatePatient = catchAsyncErrors(async (req, res, next) => {
    const {
        name,
        motherName,
        phone,
        patientType,
        home_address,
        age,
        aog,
        admissionDate,
        intakeQuestionnaire
    } = req.body;

    if (!name || !name.trim()) {
        return next(new ErrorHandler('Patient name is required', 400));
    }
    if (!motherName || !motherName.trim()) {
        return next(new ErrorHandler("Mother's name is required", 400));
    }
    if (!phone || !phone.trim()) {
        return next(new ErrorHandler('Contact number is required', 400));
    }

    const address = home_address || {
        street: req.body.street || '',
        brgy: req.body.brgy || '',
        city: req.body.city || 'Pasig City'
    };

    if (!address.street || !address.brgy || !address.city) {
        return next(new ErrorHandler('Street, Barangay, and City are required', 400));
    }

    // Generate secure single-use claim token and QR code footprint
    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Patient');

    const patient = await Patient.create({
        user: null, // Explicitly Unclaimed
        name: name.trim(),
        motherName: motherName.trim(),
        phone: phone.trim(),
        patientType: patientType || 'Inpatient',
        home_address: address,
        age: age || '',
        aog: aog || '',
        admissionDate: admissionDate ? new Date(admissionDate) : new Date(),
        staff: req.user?.id, // Staff member logging the record
        requested: [],
        intakeQuestionnaire: intakeQuestionnaire || {},
        claimToken: rawToken,
        claimTokenHash: tokenHash,
        claimTokenExpires: expiresAt,
        qrCodeData,
        audit: {
            createdBy: req.user?.id
        }
    });

    res.status(201).json({
        success: true,
        message: 'Unclaimed Patient record created successfully. Provide the claim token or QR code to the mother/guardian.',
        claimToken: rawToken,
        qrCodeData,
        claimExpires: expiresAt,
        patient
    });
});

// ============================================================================
// STAFF ACTION: GENERATE NEW CLAIM TOKEN FOR PATIENT
// ============================================================================
// POST /api/v1/patient/:id/claim-token
exports.generatePatientClaimToken = catchAsyncErrors(async (req, res, next) => {
    const patient = await Patient.findById(req.params.id);

    if (!patient) {
        return next(new ErrorHandler(`Patient not found with ID: ${req.params.id}`, 404));
    }

    if (patient.user) {
        return next(new ErrorHandler('Record has already been claimed and linked to a User account.', 400));
    }

    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Patient');

    patient.claimToken = rawToken;
    patient.claimTokenHash = tokenHash;
    patient.claimTokenExpires = expiresAt;
    patient.qrCodeData = qrCodeData;
    if (patient.audit) {
        patient.audit.updatedBy = req.user?.id;
    }
    await patient.save();

    res.status(200).json({
        success: true,
        message: 'New claim token and QR code generated successfully',
        claimToken: rawToken,
        qrCodeData,
        claimExpires: expiresAt
    });
});

// ============================================================================
// STAFF DASHBOARD: PATIENT MANAGEMENT BOARD
// ============================================================================
// GET /api/v1/staff/patients/dashboard
exports.getStaffPatientDashboard = catchAsyncErrors(async (req, res, next) => {
    const {
        search,
        patientType,
        claimStatus, // 'unclaimed' | 'claimed'
        sort = '-createdAt',
        page = 1,
        limit = 12
    } = req.query;

    const query = { isDeleted: false };

    if (patientType) query.patientType = patientType;

    if (claimStatus === 'unclaimed') {
        query.user = null;
    } else if (claimStatus === 'claimed') {
        query.user = { $ne: null };
    }

    if (search) {
        query.$or = [
            { name: { $regex: search, $options: 'i' } },
            { motherName: { $regex: search, $options: 'i' } },
            { phone: { $regex: search, $options: 'i' } },
            { 'home_address.brgy': { $regex: search, $options: 'i' } }
        ];
    }

    const pageNumber = Math.max(1, parseInt(page, 10));
    const pageSize = Math.max(1, parseInt(limit, 10));
    const skip = (pageNumber - 1) * pageSize;

    const [rawPatients, total] = await Promise.all([
        Patient.find(query)
            .populate('user', 'name username phone role')
            .populate('staff', 'name username')
            .populate({
                path: 'requested',
                select: 'date volumeRequested status diagnosis doctor'
            })
            .sort(sort)
            .skip(skip)
            .limit(pageSize),
        Patient.countDocuments(query)
    ]);

    // Format for Staff Patient Board
    const patients = rawPatients.map(p => {
        const isClaimed = Boolean(p.user);

        return {
            id: p._id,
            // 1. Patient Name & Claim Status Badge
            patientName: p.name,
            claimStatus: isClaimed ? 'Claimed / Linked' : 'Unclaimed',
            isClaimed,
            userAccount: isClaimed ? {
                id: p.user._id,
                username: p.user.username,
                phone: p.user.phone
            } : null,

            // 2. Core Clinical Information
            patientType: p.patientType, // Inpatient / Outpatient
            age: p.age ? `${p.age} days old` : 'N/A',
            aog: p.aog ? `${p.aog} weeks` : 'N/A',
            admissionDate: p.admissionDate,

            // 3. Maternal Linkage
            motherName: p.motherName,
            contactNumber: p.phone,

            // 4. Address Breakdown
            home_address: {
                street: p.home_address?.street || '',
                brgy: p.home_address?.brgy || '',
                city: p.home_address?.city || '',
                fullAddress: `${p.home_address?.street || ''}, Brgy. ${p.home_address?.brgy || ''}, ${p.home_address?.city || ''}`
            },

            // 5. Requested Milk Records & Registering Staff ID
            requestedMilkCount: p.requested?.length || 0,
            requestedMilkRecords: p.requested || [],
            registeringStaff: p.staff ? {
                id: p.staff._id,
                name: p.staff.name ? `${p.staff.name.first} ${p.staff.name.last}`.trim() : p.staff.username
            } : null,

            // Intake Questionnaire details
            intakeQuestionnaire: p.intakeQuestionnaire || null,
            createdAt: p.createdAt,

            // Permitted Staff Actions
            actionsAllowed: [
                'EDIT_PATIENT',
                'REVIEW_REQUESTS',
                'ADD_REQUEST',
                'SOFT_DELETE',
                !isClaimed ? 'GENERATE_CLAIM_TOKEN' : null
            ].filter(Boolean)
        };
    });

    // Summary counts for dashboard badges
    const [unclaimedCount, claimedCount, inpatientsCount, outpatientsCount] = await Promise.all([
        Patient.countDocuments({ isDeleted: false, user: null }),
        Patient.countDocuments({ isDeleted: false, user: { $ne: null } }),
        Patient.countDocuments({ isDeleted: false, patientType: 'Inpatient' }),
        Patient.countDocuments({ isDeleted: false, patientType: 'Outpatient' })
    ]);

    res.status(200).json({
        success: true,
        summary: {
            total,
            unclaimedCount,
            claimedCount,
            inpatientsCount,
            outpatientsCount
        },
        page: pageNumber,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
        patients
    });
});
