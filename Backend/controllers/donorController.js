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
