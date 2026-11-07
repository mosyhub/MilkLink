const Donor = require('../models/donor')
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const User = require('../models/user');
const Bag = require('../models/bags');
const { generateClaimCredentials } = require('../utils/qrHelper');

exports.allDonors = catchAsyncErrors(async (req, res, next) => {
    const { search, brgy, type } = req.query;
    const query = {};

    if (search) {
        const regex = { $regex: search, $options: 'i' };
        const matchingUsers = await User.find({
            $or: [{ 'name.first': regex }, { 'name.middle': regex }, { 'name.last': regex }]
        }).select('_id');

        query.$or = [
            { 'name.first': regex },
            { 'name.middle': regex },
            { 'name.last': regex },
            { user: { $in: matchingUsers.map(u => u._id) } }
        ];
    }
    // Step 2: Apply other filters on Donor
    if (brgy) {
        query["home_address.brgy"] = brgy;
    }
    if (type) {
        query["donorType"] = type;
    }

    // Optional: Add pagination (e.g., limit results and skip for page number)
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.pageSize) || 12; // Adjust page size as needed
    const skip = (page - 1) * pageSize;

    try {

        // Find donors based on the query object
        const donors = await Donor.find(query)
            .populate('donations.milkLettingEvent', 'activity actDetails venue')
            .populate('donations.schedule')
            .populate('user')
            .sort({ 'user.name.first': 1 })

        const totalDonors = await Donor.countDocuments(query);
        const totalPages = Math.ceil(totalDonors / pageSize);

        res.status(200).json({
            success: true,
            totalDonors,
            totalPages,
            pageSize,
            donors
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }

})

exports.getDonorDetails = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findById(req.params.id)
        .populate('donations.milkLettingEvent', 'activity actDetails venue attendance')
        .populate('donations.schedule')
        .populate('user');

    if (!donor) {
        return next(new ErrorHandler(`donor is not found with this id: ${req.params.id}`));
    }

    for (const donation of donor.donations) {
        const mle = donation.milkLettingEvent;

        if (!mle || !Array.isArray(mle.attendance)) continue;

        let totalVolume = 0;


        if (mle?.attendance) {
            const myAttendance = mle.attendance.find(att => att.donor._id.toString() === donor._id.toString())
            if (myAttendance) {
                // Use only necessary donor fields to avoid circular reference
                myAttendance.donor = {
                    _id: donor._id,
                    name: donor.name, // or any fields you need
                };

                myAttendance.bags = await Bag.find({ _id: { $in: myAttendance.bags } });
                myAttendance.additionalBags = await Bag.find({ _id: { $in: myAttendance.additionalBags } });
                const totalBags = myAttendance.bags.reduce((acc, bag) => acc + bag.volume, 0)
                const totalAdditionalBags = myAttendance.additionalBags.reduce((acc, bag) => acc + bag.volume, 0);
                totalVolume = totalBags + totalAdditionalBags;
                mle.attendance = [myAttendance];
            } else {
                mle.attendance = [];
            }

        }

        // Add totalVolume directly to the donation object
        donation.totalVolume = totalVolume;
    }
    res.status(200).json({
        success: true,
        donor,
    });

})

// Get Logged-in Donor Profile => /api/v1/donor/me
exports.getMyDonorProfile = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findOne({ user: req.user.id })
        .populate('donations.milkLettingEvent', 'activity actDetails venue attendance')
        .populate('donations.schedule')
        .populate('user');

    if (!donor) {
        return res.status(200).json({
            success: true,
            hasDonorProfile: false,
            donor: null
        });
    }

    for (const donation of donor.donations) {
        const mle = donation.milkLettingEvent;
        if (!mle || !Array.isArray(mle.attendance)) continue;

        let totalVolume = 0;
        if (mle?.attendance) {
            const myAttendance = mle.attendance.find(att => att.donor._id.toString() === donor._id.toString());
            if (myAttendance) {
                myAttendance.donor = {
                    _id: donor._id,
                    name: donor.name,
                };
                myAttendance.bags = await Bag.find({ _id: { $in: myAttendance.bags } });
                myAttendance.additionalBags = await Bag.find({ _id: { $in: myAttendance.additionalBags } });
                const totalBags = myAttendance.bags.reduce((acc, bag) => acc + bag.volume, 0);
                const totalAdditionalBags = myAttendance.additionalBags.reduce((acc, bag) => acc + bag.volume, 0);
                totalVolume = totalBags + totalAdditionalBags;
                mle.attendance = [myAttendance];
            } else {
                mle.attendance = [];
            }
        }
        donation.totalVolume = totalVolume;
    }

    res.status(200).json({
        success: true,
        hasDonorProfile: true,
        donor,
    });
});

exports.updateDonor = catchAsyncErrors(async (req, res, next) => {
    console.log("Update Donor: ", req.body)
    const donor = await Donor.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        donor
    })

})

exports.deleteDonor = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findById(req.params.id);

    if (!donor) {
        return next(new ErrorHandler(`Donor is not found with this id: ${req.params.id}`))
    }

    await donor.deleteOne();

    res.status(200).json({
        success: true,
        message: "Donor Deleted"
    })
})

exports.getNewSubmissions = catchAsyncErrors(async (req, res, next) => {
    try {
        const donors = await Donor.find({ verified: false })
            .populate({
                path: 'user',
                select: 'name'
            });
        if (!donors || donors.length === 0) {
            return res.status(201).json({
                success: false,
                message: "No new submissions found."
            });
        }
        res.status(200).json({
            success: true,
            message: "New submissions found.",
            donors
        })


    } catch (error) {
        res.status(500).json({
            success: false,
            message: "An error occurred while fetching submissions.",
            error: error.message,
        });
    }
})

exports.softDeleteDonor = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const donor = await Donor.softDeleteById(cleanId);

    if (!donor) {
        return next(new ErrorHandler(`Donor not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Donor successfully archived',
        donor,
    });
});

exports.restoreDonor = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const donor = await Donor.restoreById(cleanId);

    if (!donor) {
        return next(new ErrorHandler(`Archived donor not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Donor successfully restored',
        donor,
    });
});

exports.archivedDonors = catchAsyncErrors(async (req, res) => {
    const donors = await Donor.findOnlyDeleted()
        .populate('user', 'name email phone username')
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: donors.length,
        donors,
    });
});

exports.staffCreateDonor = catchAsyncErrors(async (req, res, next) => {
    const {
        name,
        home_address,
        birthday,
        contact_number,
        occupation,
        office_address,
        donorType,
        screening,
        children
    } = req.body;

    const address = home_address || {
        street: req.body.street || '',
        brgy: req.body.brgy || '',
        city: req.body.city || 'Pasig City'
    };

    if (!address.street || !address.brgy || !address.city) {
        return next(new ErrorHandler('Street, Barangay, and City are required', 400));
    }

    if (!birthday) {
        return next(new ErrorHandler('Donor birthday is required', 400));
    }

    if (!contact_number) {
        return next(new ErrorHandler('Contact number is required', 400));
    }

    // Parse name (object or plain string)
    let parsedName = { first: '', middle: '', last: '' };
    if (name && typeof name === 'object') {
        parsedName = {
            first: (name.first || '').trim(),
            middle: (name.middle || '').trim(),
            last: (name.last || '').trim()
        };
    } else if (typeof name === 'string' && name.trim()) {
        const parts = name.trim().split(/\s+/);
        parsedName = {
            first: parts[0] || '',
            middle: parts.length > 2 ? parts.slice(1, -1).join(' ') : '',
            last: parts.length > 1 ? parts[parts.length - 1] : ''
        };
    }

    if (!parsedName.first || !parsedName.last) {
        return next(new ErrorHandler('Donor first name and last name are required', 400));
    }

    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Donor');

    const donor = await Donor.create({
        user: null,
        staff: req.user?.id,
        name: parsedName,
        home_address: address,
        birthday: new Date(birthday),
        contact_number: contact_number.trim(),
        occupation: occupation || '',
        office_address: office_address || '',
        donorType: donorType || 'Community',
        eligibility: 'Pending Review',
        screening: screening || {},
        children: children || [],
        claimToken: rawToken,
        claimTokenHash: tokenHash,
        claimTokenExpires: expiresAt,
        qrCodeData,
        verified: false,
        audit: { createdBy: req.user?.id }
    });

    res.status(201).json({
        success: true,
        message: 'Unclaimed Donor record created successfully. Provide the claim token or QR code to the donor.',
        claimToken: rawToken,
        qrCodeData,
        claimExpires: expiresAt,
        donor
    });
});

exports.generateDonorClaimToken = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findById(req.params.id);

    if (!donor) {
        return next(new ErrorHandler(`Donor not found with ID: ${req.params.id}`, 404));
    }

    if (donor.user) {
        return next(new ErrorHandler('Record has already been claimed and linked to a User account.', 400));
    }

    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Donor');

    donor.claimToken = rawToken;
    donor.claimTokenHash = tokenHash;
    donor.claimTokenExpires = expiresAt;
    donor.qrCodeData = qrCodeData;
    if (donor.audit) {
        donor.audit.updatedBy = req.user?.id;
    }
    await donor.save();

    res.status(200).json({
        success: true,
        message: 'New claim token and QR code generated successfully',
        claimToken: rawToken,
        qrCodeData,
        claimExpires: expiresAt
    });
});

exports.updateDonorScreeningStatus = catchAsyncErrors(async (req, res, next) => {
    const { eligibility, reviewNotes, labResults } = req.body;

    const allowedStatuses = [
        'Pending Review',
        'For Laboratory Verification',
        'For Medical Assessment',
        'Eligible',
        'Temporarily Deferred',
        'Not Eligible'
    ];

    if (!allowedStatuses.includes(eligibility)) {
        return next(new ErrorHandler(`Invalid status. Must be one of: ${allowedStatuses.join(', ')}`, 400));
    }

    const donor = await Donor.findById(req.params.id);
    if (!donor) {
        return next(new ErrorHandler(`Donor not found with ID: ${req.params.id}`, 404));
    }

    donor.eligibility = eligibility;
    donor.verified = eligibility === 'Eligible';

    if (!donor.screening) {
        donor.screening = {};
    }

    if (reviewNotes !== undefined) {
        donor.screening.reviewNotes = reviewNotes;
    }

    if (labResults && typeof labResults === 'object') {
        donor.screening.laboratory = {
            ...donor.screening.laboratory,
            ...labResults,
            labDateTested: new Date()
        };
    }

    donor.screening.reviewedBy = req.user?.id;
    donor.screening.reviewedAt = new Date();
    if (donor.audit) {
        donor.audit.updatedBy = req.user?.id;
    }

    await donor.save();

    res.status(200).json({
        success: true,
        message: `Donor screening status updated to '${eligibility}'`,
        donor
    });
});

exports.getStaffDonorDashboard = catchAsyncErrors(async (req, res, next) => {
    const {
        search,
        brgy,
        donorType,
        eligibility,
        claimStatus, // 'unclaimed' | 'claimed'
        sort = '-createdAt',
        page = 1,
        limit = 12
    } = req.query;

    const query = { isDeleted: false };

    // Filters
    if (brgy) query['home_address.brgy'] = brgy;
    if (donorType) query.donorType = donorType;
    if (eligibility) query.eligibility = eligibility;

    if (claimStatus === 'unclaimed') {
        query.user = null;
    } else if (claimStatus === 'claimed') {
        query.user = { $ne: null };
    }

    const pageNumber = Math.max(1, parseInt(page, 10));
    const pageSize = Math.max(1, parseInt(limit, 10));
    const skip = (pageNumber - 1) * pageSize;

    const [rawDonors, total] = await Promise.all([
        Donor.find(query)
            .populate('user', 'name username phone role')
            .populate('staff', 'name username')
            .sort(sort)
            .skip(skip)
            .limit(pageSize),
        Donor.countDocuments(query)
    ]);

    const donors = rawDonors.map(d => {
        const isClaimed = Boolean(d.user);
        const resolvedFullName =
            (isClaimed && d.user?.fullName) ||
            d.fullName ||
            `Donor #${d._id.toString().slice(-6)}`;

        return {
            id: d._id,
            fullName: resolvedFullName,
            name: d.name,
            claimStatus: isClaimed ? 'Claimed / Linked' : 'Unclaimed',
            isClaimed,
            userAccount: isClaimed ? {
                id: d.user._id,
                username: d.user.username,
                phone: d.user.phone
            } : null,

            // 2. Clinical Data
            donorType: d.donorType,
            contactNumber: d.contact_number || d.user?.phone || 'N/A',
            birthday: d.birthday,
            age: d.age,

            // 3. Address Breakdown
            home_address: {
                street: d.home_address?.street || '',
                brgy: d.home_address?.brgy || '',
                city: d.home_address?.city || '',
                fullAddress: `${d.home_address?.street || ''}, Brgy. ${d.home_address?.brgy || ''}, ${d.home_address?.city || ''}`
            },

            // 4. Registration Date & Screening Status
            createdAt: d.createdAt,
            eligibility: d.eligibility,
            verified: d.verified,

            // 5. Screening Information & Responsible Staff Member
            screening: d.screening || null,
            responsibleStaff: d.staff ? {
                id: d.staff._id,
                name: d.staff.name ? `${d.staff.name.first} ${d.staff.name.last}`.trim() : d.staff.username
            } : null,

            // Actions Allowed
            actionsAllowed: [
                'EDIT_DONOR',
                'UPDATE_SCREENING_STATUS',
                'SOFT_DELETE',
                !isClaimed ? 'GENERATE_CLAIM_TOKEN' : null
            ].filter(Boolean)
        };
    });

    // Summary counts for dashboard badges
    const [unclaimedCount, claimedCount, eligibleCount, pendingCount] = await Promise.all([
        Donor.countDocuments({ isDeleted: false, user: null }),
        Donor.countDocuments({ isDeleted: false, user: { $ne: null } }),
        Donor.countDocuments({ isDeleted: false, eligibility: 'Eligible' }),
        Donor.countDocuments({ isDeleted: false, eligibility: 'Pending Review' })
    ]);

    res.status(200).json({
        success: true,
        summary: {
            total,
            unclaimedCount,
            claimedCount,
            eligibleCount,
            pendingCount
        },
        page: pageNumber,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
        donors
    });
});

// Helper: Generate Sequential Pasig Human Milk Bank Donor ID (e.g. DEDE1-2026-0001)
const generatePasigDonorId = async () => {
    const year = new Date().getFullYear();
    const prefix = `DEDE1-${year}-`;
    const lastDonor = await Donor.findOne({ donorId: new RegExp(`^${prefix}`) })
        .sort({ donorId: -1 })
        .select('donorId');

    let sequence = 1;
    if (lastDonor && lastDonor.donorId) {
        const parts = lastDonor.donorId.split('-');
        const lastSeq = parseInt(parts[parts.length - 1], 10);
        if (!isNaN(lastSeq)) {
            sequence = lastSeq + 1;
        }
    }
    return `${prefix}${String(sequence).padStart(4, '0')}`;
};

// First-Time Donor Registration (DEDE1 simplified workflow) => /api/v1/donor/register
exports.registerFirstTimeDonor = catchAsyncErrors(async (req, res, next) => {
    const {
        firstName,
        middleName,
        lastName,
        birthday,
        street,
        brgy,
        city = "Pasig City",
        contactNumber,
        occupation,
        donorType = "Community",
        childName,
        childBirthday,
        birthWeight,
        breastfeedingInfo,
        questionnaireAnswers
    } = req.body;

    if (!firstName || !lastName) {
        return next(new ErrorHandler("Please provide donor's first and last name", 400));
    }
    if (!birthday) {
        return next(new ErrorHandler("Please enter birthday of the donor", 400));
    }
    if (!street || !brgy) {
        return next(new ErrorHandler("Please provide complete address (street and barangay)", 400));
    }
    if (!contactNumber) {
        return next(new ErrorHandler("Please provide a contact number", 400));
    }

    // Check duplicate donor record (same first name, last name, and birthday or contact number)
    const normalizedFirst = firstName.trim().toLowerCase();
    const normalizedLast = lastName.trim().toLowerCase();
    const birthDate = new Date(birthday);

    const existingDonor = await Donor.findOne({
        isDeleted: false,
        'name.first': { $regex: new RegExp(`^${normalizedFirst}$`, 'i') },
        'name.last': { $regex: new RegExp(`^${normalizedLast}$`, 'i') },
        $or: [
            { birthday: birthDate },
            { contact_number: contactNumber.trim() }
        ]
    });

    if (existingDonor) {
        return res.status(409).json({
            success: false,
            isDuplicate: true,
            message: "A donor record already exists with this name and birthday/contact number.",
            existingDonorId: existingDonor.donorId,
            donor: {
                id: existingDonor._id,
                donorId: existingDonor.donorId,
                name: existingDonor.name,
                eligibility: existingDonor.eligibility
            }
        });
    }

    const newDonorId = await generatePasigDonorId();
    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Donor');

    const childrenData = [];
    if (childName && childBirthday) {
        const cBirth = new Date(childBirthday);
        const ageInMonths = Math.max(0, Math.floor((new Date() - cBirth) / (1000 * 60 * 60 * 24 * 30.4375)));
        childrenData.push({
            name: childName.trim(),
            dateOfBirth: cBirth,
            birth_weight: birthWeight || "",
            age: {
                value: ageInMonths || 1,
                unit: "months"
            }
        });
    }

    const donorData = {
        donorId: newDonorId,
        user: req.user ? req.user._id : null,
        staff: req.user && ['SuperAdmin', 'Admin', 'Staff'].includes(req.user.role) ? req.user._id : null,
        name: {
            first: firstName.trim(),
            middle: (middleName && middleName.trim()) || "",
            last: lastName.trim()
        },
        birthday: birthDate,
        home_address: {
            street: street.trim(),
            brgy: brgy.trim(),
            city: city.trim()
        },
        contact_number: contactNumber.trim(),
        occupation: occupation ? occupation.trim() : "",
        donorType,
        eligibility: 'Pending Review',
        claimToken: rawToken,
        claimTokenHash: tokenHash,
        claimTokenExpires: expiresAt,
        qrCodeData,
        children: childrenData,
        audit: {
            createdBy: req.user ? req.user._id : null,
            updatedBy: req.user ? req.user._id : null
        }
    };

    if (questionnaireAnswers && typeof questionnaireAnswers === 'object') {
        donorData.screening = {
            questionnaire: questionnaireAnswers,
            reviewNotes: breastfeedingInfo ? `Breastfeeding notes: ${breastfeedingInfo}` : ''
        };
    }

    const donor = await Donor.create(donorData);

    res.status(201).json({
        success: true,
        message: "First-time donor registered successfully under Pasig City Human Milk Bank DEDE1 workflow.",
        donorId: donor.donorId,
        qrCodeData: donor.qrCodeData,
        claimToken: rawToken,
        donor,
        nextSteps: [
            "Complete your electronic consent and health questionnaire.",
            "Upload laboratory screening documents (CBC, HIV, HBsAg, Anti-HCV).",
            "Wait for medical assessment and eligibility confirmation by milk bank staff.",
            "Schedule milk collection or home pickup once eligible."
        ]
    });
});

// Returning Donor Search & Identification (No login required) => /api/v1/donor/search-returning
exports.searchReturningDonor = catchAsyncErrors(async (req, res, next) => {
    const { query } = req.query;
    if (!query || !query.trim()) {
        return next(new ErrorHandler("Please provide donor ID, contact number, or donor name", 400));
    }

    const cleanQuery = query.trim();
    const regex = new RegExp(cleanQuery, 'i');

    const donors = await Donor.find({
        isDeleted: false,
        $or: [
            { donorId: cleanQuery.toUpperCase() },
            { contact_number: cleanQuery },
            { 'name.first': regex },
            { 'name.last': regex },
            { submissionID: cleanQuery }
        ]
    })
    .select('donorId name birthday contact_number home_address donorType eligibility verified donations user createdAt')
    .limit(10);

    res.status(200).json({
        success: true,
        count: donors.length,
        donors
    });
});

// Staff Record Donation for Returning Donor without Requiring Donor Login => /api/v1/donor/:id/record-donation
exports.recordReturningDonation = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    const {
        donationType = "Public",
        milkLettingEvent,
        schedule,
        totalVolume,
        numberOfBags = 1,
        collectionDate,
        batchReference,
        notes
    } = req.body;

    const donor = await Donor.findOne({
        _id: id,
        isDeleted: false
    });

    if (!donor) {
        return next(new ErrorHandler(`Donor record not found with ID: ${id}`, 404));
    }

    // Check whether donor eligibility and reassessment remain valid
    if (donor.eligibility !== 'Eligible') {
        return next(new ErrorHandler(
            `Cannot record donation. Donor eligibility status is "${donor.eligibility}". Authorized medical re-screening or status approval is required before accepting new milk.`,
            400
        ));
    }

    // Check if screening is older than 6 months (reassessment check)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    if (donor.screening?.reviewedAt && donor.screening.reviewedAt < sixMonthsAgo) {
        donor.eligibility = 'For Medical Assessment';
        donor.verified = false;
        await donor.save();
        return next(new ErrorHandler(
            'Donor medical screening was conducted over 6 months ago. Re-assessment is required before collecting new milk.',
            400
        ));
    }

    if (!totalVolume || isNaN(totalVolume) || Number(totalVolume) <= 0) {
        return next(new ErrorHandler("Please enter valid milk volume in milliliters", 400));
    }

    const newDonation = {
        donationType,
        totalVolume: Number(totalVolume),
        numberOfBags: Number(numberOfBags) || 1,
        collectionDate: collectionDate ? new Date(collectionDate) : new Date(),
        batchReference: batchReference || `BATCH-${Date.now().toString().slice(-6)}`,
        status: 'Collected',
        recordedBy: req.user ? req.user._id : null,
        notes: notes || ""
    };

    if (milkLettingEvent) newDonation.milkLettingEvent = milkLettingEvent;
    if (schedule) newDonation.schedule = schedule;

    donor.donations.push(newDonation);
    if (donor.audit) {
        donor.audit.updatedBy = req.user ? req.user._id : null;
    }
    await donor.save();

    res.status(201).json({
        success: true,
        message: "New donation record saved successfully under donor profile.",
        donorId: donor.donorId,
        donation: newDonation,
        totalDonationsCount: donor.donations.length
    });
});

// ============================================================================
// PENDING ONLINE REGISTRATIONS FOR STAFF MODULE
// GET /api/v1/staff/pending-registrations
// ============================================================================
exports.getPendingOnlineRegistrations = catchAsyncErrors(async (req, res, next) => {
    const { search, page = 1, pageSize = 20 } = req.query;
    const ScreeningAppointment = require('../models/screeningAppointment');

    const pageNum = Math.max(1, parseInt(page, 10));
    const limitNum = Math.max(1, parseInt(pageSize, 10));
    const skip = (pageNum - 1) * limitNum;

    const userQuery = {
        role: 'User',
        isDeleted: false,
    };

    if (search && search.trim()) {
        const regex = { $regex: search.trim(), $options: 'i' };
        userQuery.$or = [
            { 'name.first': regex },
            { 'name.last': regex },
            { username: regex },
            { phone: regex },
            { email: regex },
        ];
    }

    const [users, total] = await Promise.all([
        User.find(userQuery)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum),
        User.countDocuments(userQuery)
    ]);

    const userIds = users.map(u => u._id);

    // Look up associated donors and screening appointments
    const [linkedDonors, appointments] = await Promise.all([
        Donor.find({ user: { $in: userIds }, isDeleted: false }),
        ScreeningAppointment.find({ user: { $in: userIds }, isDeleted: false }).sort({ appointmentDate: -1 })
    ]);

    const donorByUser = {};
    linkedDonors.forEach(d => {
        if (d.user) donorByUser[d.user.toString()] = d;
    });

    const appointmentByUser = {};
    appointments.forEach(a => {
        const uId = a.user.toString();
        if (!appointmentByUser[uId]) {
            appointmentByUser[uId] = a; // latest appointment
        }
    });

    const registrations = users.map(u => {
        const d = donorByUser[u._id.toString()];
        const apt = appointmentByUser[u._id.toString()];

        return {
            id: u._id,
            name: u.name,
            fullName: u.fullName || `${u.name?.first || ''} ${u.name?.last || ''}`.trim(),
            username: u.username,
            phone: u.phone,
            email: u.email || 'N/A',
            accountStatus: u.accountStatus || (d ? 'Verified' : 'Temporary'),
            createdAt: u.createdAt,
            screeningAppointment: apt ? {
                id: apt._id,
                appointmentId: apt.appointmentId,
                date: apt.appointmentDate,
                timeSlot: apt.timeSlot,
                status: apt.status,
                screeningCompleted: apt.screeningCompleted,
            } : null,
            linkedDonor: d ? {
                id: d._id,
                donorId: d.donorId,
                donorType: d.donorType,
                eligibility: d.eligibility,
                verified: d.verified,
                createdAt: d.createdAt,
            } : null,
            isLinkedToDonor: Boolean(d),
        };
    });

    const pendingCount = registrations.filter(r => !r.isLinkedToDonor).length;
    const verifiedCount = registrations.filter(r => r.isLinkedToDonor).length;

    res.status(200).json({
        success: true,
        summary: {
            total,
            pendingCount,
            verifiedCount,
        },
        page: pageNum,
        pageSize: limitNum,
        totalPages: Math.ceil(total / limitNum),
        registrations,
    });
});

// ============================================================================
// STAFF: LINK TEMPORARY USER ACCOUNT TO AN EXISTING DONOR RECORD
// POST /api/v1/staff/user/:userId/link-donor
// ============================================================================
exports.staffLinkUserToDonor = catchAsyncErrors(async (req, res, next) => {
    const { userId } = req.params;
    const { donorId } = req.body;

    if (!donorId) {
        return next(new ErrorHandler('Target donor ID is required', 400));
    }

    const user = await User.findById(userId);
    if (!user || user.isDeleted) {
        return next(new ErrorHandler('User not found', 404));
    }

    // Verify user doesn't already have a linked donor
    const existingUserDonor = await Donor.findOne({ user: user._id, isDeleted: false });
    if (existingUserDonor && existingUserDonor._id.toString() !== donorId) {
        return next(new ErrorHandler(
            `User is already linked to donor profile ${existingUserDonor.donorId || existingUserDonor._id}. Multiple donor profiles cannot be linked to the same user.`,
            409
        ));
    }

    const donor = await Donor.findById(donorId);
    if (!donor || donor.isDeleted) {
        return next(new ErrorHandler('Donor record not found', 404));
    }

    if (donor.user && donor.user.toString() !== user._id.toString()) {
        return next(new ErrorHandler('This donor record has already been claimed by another user account.', 409));
    }

    donor.user = user._id;
    donor.claimToken = undefined;
    donor.claimTokenHash = undefined;
    donor.claimTokenExpires = undefined;
    donor.qrCodeData = null;
    if (donor.audit) {
        donor.audit.updatedBy = req.user._id;
    }
    await donor.save();

    user.accountStatus = 'Verified';
    await user.save();

    res.status(200).json({
        success: true,
        message: `Successfully linked temporary account of ${user.fullName} to donor record ${donor.donorId || donor._id}.`,
        donor: {
            id: donor._id,
            donorId: donor.donorId,
            name: donor.name,
            eligibility: donor.eligibility,
            verified: donor.verified,
        }
    });
});

// ============================================================================
// STAFF: CREATE NEW DONOR PROFILE FOR A VERIFIED TEMPORARY USER
// POST /api/v1/staff/user/:userId/create-donor
// ============================================================================
exports.staffCreateDonorForUser = catchAsyncErrors(async (req, res, next) => {
    const { userId } = req.params;
    const {
        birthday,
        street,
        brgy,
        city = "Pasig City",
        donorType = "Community",
        occupation = "",
        eligibility = "Pending Review",
    } = req.body;

    const user = await User.findById(userId);
    if (!user || user.isDeleted) {
        return next(new ErrorHandler('User not found', 404));
    }

    // Check if user already has a linked donor record
    const existingDonor = await Donor.findOne({ user: user._id, isDeleted: false });
    if (existingDonor) {
        return next(new ErrorHandler(
            `User already has an active donor profile (${existingDonor.donorId || existingDonor._id}). Cannot create duplicate profiles.`,
            409
        ));
    }

    if (!birthday) {
        return next(new ErrorHandler('Please provide donor date of birth', 400));
    }
    if (!street || !brgy) {
        return next(new ErrorHandler('Please provide complete home address (street & barangay)', 400));
    }

    const newDonorId = await generatePasigDonorId();

    const donor = await Donor.create({
        donorId: newDonorId,
        user: user._id,
        staff: req.user._id,
        name: {
            first: user.name.first,
            middle: user.name.middle || "",
            last: user.name.last,
        },
        birthday: new Date(birthday),
        home_address: {
            street: street.trim(),
            brgy: brgy.trim(),
            city: city.trim(),
        },
        contact_number: user.phone,
        donorType,
        occupation: occupation.trim(),
        eligibility,
        verified: eligibility === 'Eligible',
        audit: {
            createdBy: req.user._id,
            updatedBy: req.user._id,
        }
    });

    user.accountStatus = 'Verified';
    await user.save();

    res.status(201).json({
        success: true,
        message: `Donor profile ${donor.donorId} created and linked to ${user.fullName}.`,
        donor,
    });
});
