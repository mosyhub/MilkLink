const mongoose = require('mongoose');
const User = require('../models/user');
const Donor = require('../models/donor');
const Patient = require('../models/patient');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const sendToken = require('../utils/jwtToken');
const sendEmail = require('../utils/sendEmail');
const crypto = require('crypto');
const cloudinary = require('cloudinary');
const validator = require('validator');
const { validatePasswordPolicy } = require('../utils/passwordPolicy');


// Register a user => /api/v1/register
exports.registerUser = catchAsyncErrors(async (req, res, next) => {
    const { firstName, lastName, middleName, username, email, phoneNumber, phone, role, pass, password } = req.body;

    const userPassword = password || pass;
    const userPhone = phoneNumber || phone;
    const cleanUsername = username ? username.trim().toLowerCase() : '';
    const cleanEmail = (email && email.trim() !== '') ? email.trim().toLowerCase() : undefined;

    // Validate required fields
    if (!firstName || !firstName.trim()) {
        return next(new ErrorHandler('Please enter first name', 400));
    }
    if (!lastName || !lastName.trim()) {
        return next(new ErrorHandler('Please enter last name', 400));
    }
    if (!cleanUsername) {
        return next(new ErrorHandler('Please enter a username', 400));
    }
    if (cleanUsername.length < 4 || cleanUsername.length > 30) {
        return next(new ErrorHandler('Username must be between 4 and 30 characters', 400));
    }
    if (!/^[a-zA-Z0-9_.-]+$/.test(cleanUsername)) {
        return next(new ErrorHandler('Username can only contain alphanumeric characters, underscores, dots, or hyphens', 400));
    }
    if (!userPhone || !userPhone.trim()) {
        return next(new ErrorHandler('Please enter a valid phone number', 400));
    }

    // Enforce secure password policy
    const passwordCheck = validatePasswordPolicy(userPassword);
    if (!passwordCheck.isValid) {
        return next(new ErrorHandler(passwordCheck.message, 400));
    }

    // Check if username already exists
    const existingUsername = await User.findOne({ username: cleanUsername, isDeleted: false });
    if (existingUsername) {
        return next(new ErrorHandler('Username is already taken. Please choose another.', 400));
    }

    // Check if optional email is provided and already taken
    if (cleanEmail) {
        if (!validator.isEmail(cleanEmail)) {
            return next(new ErrorHandler('Please enter a valid email address', 400));
        }
        const existingEmail = await User.findOne({ email: cleanEmail, isDeleted: false });
        if (existingEmail) {
            return next(new ErrorHandler('Email is already registered. Please use another or log in.', 400));
        }
    }

    const userData = {
        name: {
            first: firstName.trim(),
            middle: (middleName && middleName.trim()) || "",
            last: lastName.trim(),
        },
        username: cleanUsername,
        password: userPassword,
        phone: userPhone.trim(),
        role: role || 'User',
        accountStatus: (role && ['Staff', 'Admin', 'SuperAdmin'].includes(role)) ? 'Verified' : 'Temporary',
    };

    if (cleanEmail) {
        userData.email = cleanEmail;
    }
    if (req.body.employeeID) {
        userData.employeeID = req.body.employeeID;
    }

    const user = await User.create(userData);

    sendToken(user, 201, req, res);
})


// Login User => /api/v1/login
exports.loginUser = catchAsyncErrors(async (req, res, next) => {
    const { email, username, identifier, employeeID, password } = req.body;
    const { emp } = req.query;
    let user;

    if (emp) {
        if (!employeeID || !password) {
            return res.status(400).json({ success: false, message: "Please enter employeeID and password" });
        }

        user = await User.findOne({ employeeID }).select('+password');

        if (!user) {
            return res.status(401).json({ success: false, message: "Invalid employeeID or password" });
        }
    } else {
        const loginIdentifier = (identifier || username || email || '').trim();
        if (!loginIdentifier || !password) {
            return res.status(400).json({ success: false, message: "Please enter your username/email and password" });
        }

        const cleanIdentifier = loginIdentifier.toLowerCase();
        user = await User.findOne({
            $or: [
                { username: cleanIdentifier },
                { email: cleanIdentifier }
            ],
            isDeleted: false
        }).select('+password');

        if (!user) {
            return res.status(401).json({ success: false, message: "Invalid username/email or password" });
        }
    }

    // Check if password matches
    const isPasswordMatched = await user.comparePassword(password);
    if (!isPasswordMatched) {
        if (emp) {
            return res.status(401).json({ success: false, message: "Invalid employee id or password" });
        }
        return res.status(401).json({ success: false, message: "Invalid username/email or password" });
    }

    sendToken(user, 200, req, res);
})

// Forgot Password => /api/v1/password/forgot
exports.forgotPassword = catchAsyncErrors(async (req, res, next) => {

    const user = await User.findOne({ email: req.body.email });

    if (!user) {
        return next(new ErrorHandler('User not found with this email', 404));
    }

    // Get Reset Token
    const resetToken = user.getResetPasswordToken();

    await user.save({ validateBeforeSave: false });

    // Create reset password url
    const resetUrl = `${process.env.FRONTEND_URL}/password/reset/${resetToken}`;

    const message = `Your password reset token is as follow:\n\n${resetUrl}\n\nIf you have not requested email, then ignore it.`

    try {

        await sendEmail({
            email: user.email,
            subject: 'Reset Password',
            message
        });

        res.status(200).json({
            success: true,
            message: `Email sent to: ${user.email}`
        })

    } catch (error) {
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;

        await user.save({ validateBeforeSave: false });

        return next(new ErrorHandler(error.message, 500));
    }
})

// Reset Password => /api/v1/password/reset/:token
exports.resetPassword = catchAsyncErrors(async (req, res, next) => {

    // Hash URL token
    const resetPasswordToken = crypto.createHash('sha256').update(req.params.token).digest('hex');

    const user = await User.findOne({
        resetPasswordToken,
        resetPasswordExpire: { $gt: Date.now() }
    })

    if (!user) {
        return next(new ErrorHandler('Password reset token is invalid or has been expired', 400));
    }

    if (req.body.password !== req.body.confirmPassword) {
        return next(new ErrorHandler('Password does not match', 400));
    }

    // Enforce secure password policy on reset
    const resetPasswordCheck = validatePasswordPolicy(req.body.password);
    if (!resetPasswordCheck.isValid) {
        return next(new ErrorHandler(resetPasswordCheck.message, 400));
    }

    // Setup new Password
    user.password = req.body.password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save();

    sendToken(user, 200, req, res);

})

// Get current login user details => /api/v1/me
exports.getUserProfile = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findById(req.user.id);
    if (!user) {
        return next(new ErrorHandler('User not found', 404));
    }

    // Determine separate status dimensions:
    // 1. Account status: Active (from User)
    // 2. Donor registration status: None, Registered, In Screening, Completed
    // 3. Donor eligibility status: None, Pending Review, For Laboratory Verification, For Medical Assessment, Eligible, Temporarily Deferred, Not Eligible
    // 4. Milk request status: Has pending/active milk requests or none
    const donor = await Donor.findOne({ user: user._id, isDeleted: false });
    const Request = mongoose.models.Request || require('../models/request');
    const latestMilkRequest = await Request.findOne({ requestedBy: user._id, isDeleted: false }).sort({ createdAt: -1 });

    const donorRegistrationStatus = donor ? (donor.verified ? 'Completed' : 'Registered') : 'Unregistered';
    const donorEligibilityStatus = donor ? donor.eligibility : 'Not Screened';
    const milkRequestStatus = latestMilkRequest ? latestMilkRequest.status : 'None';

    res.status(200).json({
        success: true,
        user,
        accountStatus: user.accountStatus || 'Temporary',
        donorRegistrationStatus,
        donorEligibilityStatus,
        isDonorEligible: donor ? (donor.eligibility === 'Eligible') : false,
        donorProfile: donor ? {
            id: donor._id,
            donorId: donor.donorId,
            eligibility: donor.eligibility,
            verified: donor.verified,
            donorType: donor.donorType,
            qrCodeData: donor.qrCodeData,
        } : null,
        milkRequestStatus,
        hasActiveMilkRequest: latestMilkRequest ? ['Pending', 'Reserved'].includes(latestMilkRequest.status) : false,
    });
});

// Link an existing staff-created donor record to currently logged-in user => /api/v1/user/link-donor
exports.linkExistingDonorToAccount = catchAsyncErrors(async (req, res, next) => {
    const { claimToken, qrData } = req.body;
    const rawTokenInput = (claimToken || qrData || '').trim();

    if (!rawTokenInput) {
        return next(new ErrorHandler('Claim token or scannable QR data is required', 400));
    }

    let searchToken = rawTokenInput;
    if (searchToken.startsWith('{') && searchToken.endsWith('}')) {
        try {
            const parsed = JSON.parse(searchToken);
            if (parsed.token) searchToken = parsed.token;
        } catch (_) {}
    }

    const tokenHash = crypto.createHash('sha256').update(searchToken).digest('hex');

    // Find donor record
    const donor = await Donor.findOne({
        $or: [
            { claimTokenHash: tokenHash },
            { claimToken: searchToken },
            { donorId: searchToken.toUpperCase() }
        ],
        isDeleted: false
    }).select('+claimTokenHash +claimTokenExpires');

    if (!donor) {
        return next(new ErrorHandler('No matching staff-created donor record found with this token/ID', 404));
    }

    if (donor.user && donor.user.toString() !== req.user._id.toString()) {
        return next(new ErrorHandler('This donor record has already been linked to another user account', 409));
    }

    // Check expiration if token has an expiration
    if (donor.claimTokenExpires && donor.claimTokenExpires < new Date()) {
        return next(new ErrorHandler('This claim token has expired. Please ask milk bank staff for a refreshed code.', 400));
    }

    // Check if current user already has a linked donor record
    const existingLinkedDonor = await Donor.findOne({ user: req.user._id, isDeleted: false });
    if (existingLinkedDonor && existingLinkedDonor._id.toString() !== donor._id.toString()) {
        return next(new ErrorHandler(
            `Your account is already linked to donor record ${existingLinkedDonor.donorId || existingLinkedDonor._id}. An account cannot be linked to conflicting donor records.`,
            409
        ));
    }

    // Link donor to current authenticated user
    donor.user = req.user._id;
    donor.claimToken = undefined;
    donor.claimTokenHash = undefined;
    donor.claimTokenExpires = undefined;
    donor.qrCodeData = null;
    if (donor.audit) {
        donor.audit.updatedBy = req.user._id;
    }
    await donor.save();

    // Update user account status to Verified
    await User.findByIdAndUpdate(req.user._id, { accountStatus: 'Verified' });

    res.status(200).json({
        success: true,
        message: `Donor record (${donor.donorId || 'Linked'}) successfully linked to your account.`,
        donor: {
            id: donor._id,
            donorId: donor.donorId,
            name: donor.name,
            eligibility: donor.eligibility,
            verified: donor.verified,
        }
    });
});

// Update / Change password => /api/v1/password/update
exports.updatePassword = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findById(req.user.id).select('+password');

    // Check previous user password
    const isMatched = await user.comparePassword(req.body.oldPassword);

    if (!isMatched) {
        return next(new ErrorHandler('Old password is incorrect', 400));
    }

    // Enforce secure password policy on update
    const updatePasswordCheck = validatePasswordPolicy(req.body.password);
    if (!updatePasswordCheck.isValid) {
        return next(new ErrorHandler(updatePasswordCheck.message, 400));
    }

    user.password = req.body.password;
    await user.save();

    sendToken(user, 200, req, res);

})

exports.updateProfile = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findById(req.user.id).select('+password');
    if (!user) return next(new ErrorHandler('User not found', 404));

    const { username, email, avatar, newPassword, oldPassword } = req.body;

    // 1. Username
    if (username !== undefined) {
        const cleanUsername = String(username).trim().toLowerCase();
        if (cleanUsername && cleanUsername !== user.username) {
            if (cleanUsername.length < 4 || cleanUsername.length > 30) {
                return next(new ErrorHandler('Username must be between 4 and 30 characters', 400));
            }
            if (!/^[a-zA-Z0-9_.-]+$/.test(cleanUsername)) {
                return next(new ErrorHandler('Username can only contain letters, numbers, underscores, dots, or hyphens', 400));
            }
            const taken = await User.findOne({ username: cleanUsername, _id: { $ne: user._id }, isDeleted: false });
            if (taken) return next(new ErrorHandler('Username is already taken. Please choose another.', 400));
            user.username = cleanUsername;
        }
    }

    // 2. Email (empty string clears it)
    if (email !== undefined) {
        const cleanEmail = String(email).trim().toLowerCase();
        if (!cleanEmail) {
            user.email = undefined;
        } else if (cleanEmail !== user.email) {
            if (!validator.isEmail(cleanEmail)) {
                return next(new ErrorHandler('Please enter a valid email address', 400));
            }
            const used = await User.findOne({ email: cleanEmail, _id: { $ne: user._id }, isDeleted: false });
            if (used) return next(new ErrorHandler('Email address is already in use by another account.', 400));
            user.email = cleanEmail;
        }
    }

    // 3. Avatar: '' or null removes it; a data URL replaces it
    if (avatar !== undefined) {
        if (avatar === null || avatar === '') {
            user.avatar = undefined;
        } else if (typeof avatar === 'string' && avatar.startsWith('data:image/')) {
            if (!/^data:image\/(jpeg|jpg|png|webp);base64,/.test(avatar)) {
                return next(new ErrorHandler('Unsupported image type. Use JPG, PNG or WEBP.', 400));
            }
            if (avatar.length > 1_500_000) { // roughly 1.1 MB of image data
                return next(new ErrorHandler('Image is too large. Please choose a smaller photo.', 413));
            }
            user.avatar = { public_id: 'mobile_avatar', url: avatar };
        }
        // An http(s) URL means "unchanged", so ignore it
    }

    // 4. Password
    if (newPassword) {
        if (!oldPassword) {
            return next(new ErrorHandler('Current password is required to change your password', 400));
        }
        if (!(await user.comparePassword(oldPassword))) {
            return next(new ErrorHandler('Current password is incorrect', 400));
        }
        const { isValid, message } = validatePasswordPolicy(newPassword);
        if (!isValid) return next(new ErrorHandler(message, 400));
        user.password = newPassword;
    }

    await user.save();

    res.status(200).json({ success: true, message: 'Profile updated successfully', user });
});

// Logout User => /api/v1/logout
exports.logout = catchAsyncErrors(async (req, res, next) => {

    res.clearCookie('token', {
        httpOnly: true,
        secure: false, // true in production if using HTTPS
        sameSite: 'Strict'
    });

    res.status(200).json({
        success: true,
        message: 'Logout User'
    })
})


// SUPER ADMIN ROUTES
// Get all users => /api/v1/super/users
exports.allUsers = catchAsyncErrors(async (req, res, next) => {
    const { search, sortBy, order = "asc", role } = req.query;
    const id = req.user.id || null;
    const user = await User.find({ _id: id });
    // Create a query object to hold the search criteria
    const query = {};
    if (search) {
        query.$or = [
            { firstName: { $regex: search, $options: "i" } },  // Search in first name
            { lastName: { $regex: search, $options: "i" } }    // Search in last name
        ];

        // If the search input is a valid number, add an employeeID search
        if (!isNaN(search)) {
            query.$or.push({ employeeID: Number(search) });
        }
    }

    if (role) {
        query.role = role;
    }
    else {
        if (user.role === "Admin") {
            query.role = { $nin: ["SuperAdmin", "Admin", "User"] };
        }
        else {
            query.role = { $nin: ["SuperAdmin", "User"] };
        }

    }
    // Ensure sorting field is allowed; default to "employeeID"
    const allowedSortFields = ["employeeID", "firstName", "lastName"];
    const sortField = allowedSortFields.includes(sortBy) ? sortBy : "employeeID";

    // Convert order to a valid MongoDB sorting value (1 for ascending, -1 for descending)
    const sortOrder = order === "desc" ? -1 : 1;

    try {
        // Aggregation pipeline
        const aggregationPipeline = [{ $match: query }];

        // Convert `employeeID` to a number for proper sorting if sorting by `employeeID`
        if (sortField === "employeeID") {
            aggregationPipeline.push({
                $addFields: {
                    employeeIDNum: {
                        $convert: {
                            input: "$employeeID",
                            to: "long",
                            onError: null, // Avoid crashing if conversion fails
                            onNull: null
                        }
                    }
                }
            });
        }


        // Sorting (defaults to employeeID if no valid field is given)
        aggregationPipeline.push({
            $sort: { [sortField === "employeeID" ? "employeeIDNum" : sortField]: sortOrder }
        });



        // Fetch users
        let users = await User.aggregate(aggregationPipeline);

        // Ensure employeeID is always at least 3 digits
        users = users.map(user => ({
            ...user,
            employeeID: user.employeeID.toString().padStart(3, "0")
        }));


        res.status(200).json({
            success: true,

            users
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }

})

// Get specific user details => /api/v1/super/user/:id
exports.getUserDetails = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        return next(new ErrorHandler(`User is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        user
    })
})

// Update user profile => /api/v1/super/update/:id
exports.updateUser = catchAsyncErrors(async (req, res, next) => {

    const newUserData = {
        name: req.body.name,
        email: req.body.email,
        role: req.body.role
    }

    const user = await User.findByIdAndUpdate(req.params.id, newUserData, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        user
    })

})

// Delete User => /api/v1/super/user/:id
exports.deleteUser = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        return next(new ErrorHandler(`User is not found with this id: ${req.params.id}`))
    }

    // Remove avatar from cloudinary
    // const image_id = user.avatar.public_id;
    // await cloudinary.v2.uploader.destroy(image_id);

    await user.deleteOne();

    res.status(200).json({
        success: true
    })
})


// ADMIN ROUTES
// Get all staff => /api/v1/admin/users
exports.allStaffs = catchAsyncErrors(async (req, res, next) => {
    const users = await User.find({ role: 'Staff' });

    const count = await User.countDocuments({ role: 'Staff' });

    res.status(200).json({
        success: true,
        count,
        users
    })
})

// Get specific staff details => /api/v1/admin/user/:id
exports.getStaffDetails = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findOne({ _id: req.params.id, role: 'Staff' });

    if (!user) {
        return next(new ErrorHandler(`Staff is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        user
    })
})

// Update staff profile => /api/v1/admin/update/:id
exports.updateStaff = catchAsyncErrors(async (req, res, next) => {
    const staff = await User.findOne({ _id: req.params.id, role: 'Staff' });

    if (!staff) {
        return next(new ErrorHandler(`Staff is not found with this id: ${req.params.id}`))
    }

    const newUserData = {
        name: req.body.name,
        email: req.body.email,
        role: req.body.role
    }

    const user = await User.findByIdAndUpdate(req.params.id, newUserData, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        user
    })

})

// Delete staff => /api/v1/admin/user/:id
exports.deleteStaff = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findOne({ _id: req.params.id, role: 'Staff' });

    if (!user) {
        return next(new ErrorHandler(`Staff is not found with this id: ${req.params.id}`))
    }

    // Remove avatar from cloudinary
    // const image_id = user.avatar.public_id;
    // await cloudinary.v2.uploader.destroy(image_id);

    await user.deleteOne();

    res.status(200).json({
        success: true
    })
})

/*
 * Legacy direct self-registration flow intentionally remains unavailable.
 * Donor and patient accounts must be created through claimExistingRecord.
 */
exports.selfRegister = catchAsyncErrors(async (req, res, next) => {
    const {
        username,
        password,
        phone,
        phoneNumber,
        name,
        firstName,
        middleName,
        lastName,
        profileType, // 'Donor' or 'Patient'
        home_address,
        // Donor Profile specifics:
        birthday,
        donorType,
        occupation,
        // Patient Profile specifics:
        patientName,
        motherName,
        patientType,
        age,
        aog
    } = req.body;

    const userPhone = (phone || phoneNumber || '').trim();
    const cleanUsername = (username || '').trim().toLowerCase();
    const first = (name?.first || firstName || '').trim();
    const middle = (name?.middle || middleName || '').trim();
    const last = (name?.last || lastName || '').trim();

    // 1. Validation
    if (!cleanUsername) return next(new ErrorHandler('Username is required', 400));
    if (!first || !last) return next(new ErrorHandler('First and last names are required', 400));
    if (!userPhone) return next(new ErrorHandler('Phone number is required', 400));

    if (!['Donor', 'Patient'].includes(profileType)) {
        return next(new ErrorHandler("Profile type must be either 'Donor' or 'Patient'", 400));
    }

    const passwordValidation = validatePasswordPolicy(password);
    if (!passwordValidation.isValid) {
        return next(new ErrorHandler(passwordValidation.message, 400));
    }

    // Check duplicate username
    const existingUser = await User.findOne({ username: cleanUsername, isDeleted: false });
    if (existingUser) {
        return next(new ErrorHandler('Username is already taken. Please choose another.', 400));
    }

    // Address verification
    const address = home_address || {
        street: req.body.street || '',
        brgy: req.body.brgy || '',
        city: req.body.city || 'Pasig City'
    };

    if (!address.street || !address.brgy || !address.city) {
        return next(new ErrorHandler('Complete address (street, barangay, city) is required', 400));
    }

    // 2. Mongoose Transaction for Atomic Multi-Document Mutation
    let session = null;
    let newUser = null;
    let createdProfile = null;

    try {
        session = await mongoose.startSession();
        session.startTransaction();

        // Step 1: Create the User instance first
        newUser = new User({
            username: cleanUsername,
            password, // Password hashing handled in user pre('save') middleware
            phone: userPhone,
            name: {
                first,
                middle,
                last
            },
            role: 'User'
        });

        await newUser.save({ session });

        // Step 2: Instantly create corresponding Donor or Patient record injecting User._id
        if (profileType === 'Donor') {
            if (!birthday) {
                throw new Error('Birthday is required for Donor registration');
            }

            const donor = new Donor({
                user: newUser._id,
                home_address: address,
                birthday: new Date(birthday),
                donorType: donorType || 'Community',
                contact_number: userPhone,
                occupation: occupation || '',
                eligibility: 'Pending Review',
                verified: false,
                audit: {
                    createdBy: newUser._id
                }
            });

            await donor.save({ session });
            createdProfile = donor;

        } else if (profileType === 'Patient') {
            const patient = new Patient({
                user: newUser._id,
                name: (patientName || `${first} (Child/Infant)`).trim(),
                motherName: (motherName || `${first} ${last}`).trim(),
                phone: userPhone,
                home_address: address,
                patientType: patientType || 'Outpatient',
                age: age || '',
                aog: aog || '',
                admissionDate: new Date(),
                staff: newUser._id, // Initial self-registered reference
                requested: [],
                audit: {
                    createdBy: newUser._id
                }
            });

            await patient.save({ session });
            createdProfile = patient;
        }

        // Commit transaction
        await session.commitTransaction();
    } catch (err) {
        if (session && session.inTransaction()) {
            try {
                await session.abortTransaction();
            } catch (_) { }
        }
        return next(new ErrorHandler(`Self-registration failed: ${err.message}`, 400));
    } finally {
        if (session) {
            try {
                session.endSession();
            } catch (_) { }
        }
    }

    // 3. Return authenticated JWT token + profile
    return sendToken(newUser, 201, req, res, {
        message: `${profileType} account self-registered successfully`,
        profileType,
        profile: createdProfile
    });
});

// ============================================================================
// VERIFY CLAIM TOKEN / QR CODE => POST /api/v1/verify-claim
// ============================================================================
exports.verifyClaimToken = catchAsyncErrors(async (req, res, next) => {
    let rawInput = req.body.claimToken || req.body.token || req.body.qrData || '';
    if (typeof rawInput !== 'string' || !rawInput.trim()) {
        return next(new ErrorHandler('Claim token or scannable QR data is required', 400));
    }

    rawInput = rawInput.trim();

    // Check if the input is a JSON string from a scanned MilkLink QR code
    let parsedToken = rawInput;
    if (rawInput.startsWith('{') && rawInput.endsWith('}')) {
        try {
            const parsed = JSON.parse(rawInput);
            if (parsed.token) {
                parsedToken = parsed.token;
            }
        } catch (_) {
            parsedToken = rawInput;
        }
    }

    const cleanToken = parsedToken.trim().toUpperCase();
    const tokenHash = crypto.createHash('sha256').update(cleanToken).digest('hex');

    // Check Donor collection first
    let donor = await Donor.findOne({
        $or: [
            { claimTokenHash: tokenHash },
            { claimToken: cleanToken }
        ],
        isDeleted: false
    }).select('+claimTokenHash +claimTokenExpires');

    if (donor) {
        if (donor.user) {
            return next(new ErrorHandler('This Donor profile has already been claimed and linked to an account.', 409));
        }
        if (donor.claimTokenExpires && donor.claimTokenExpires < new Date()) {
            return next(new ErrorHandler('This claim token/QR code has expired. Please contact Milk Bank staff.', 400));
        }

        const donorFullName = donor.name?.first
            ? [donor.name.first, donor.name.middle, donor.name.last].filter(Boolean).join(' ').trim()
            : (donor.children && donor.children.length > 0 ? `Mother of ${donor.children[0].name}` : 'Human Milk Donor');

        return res.status(200).json({
            success: true,
            valid: true,
            profileType: 'Donor',
            claimToken: cleanToken,
            details: {
                fullName: donorFullName,
                contactPhone: donor.contact_number || '',
                donorCategory: donor.donorType || 'Community',
                addressSnippet: `${donor.home_address?.brgy || ''}, ${donor.home_address?.city || 'Pasig City'}`,
                screeningStatus: donor.eligibility || 'Pending Review',
                registrationDate: donor.createdAt
            }
        });
    }

    // Check Patient collection
    let patient = await Patient.findOne({
        $or: [
            { claimTokenHash: tokenHash },
            { claimToken: cleanToken }
        ],
        isDeleted: false
    }).select('+claimTokenHash +claimTokenExpires');

    if (patient) {
        if (patient.user) {
            return next(new ErrorHandler('This Recipient profile has already been claimed and linked to an account.', 409));
        }
        if (patient.claimTokenExpires && patient.claimTokenExpires < new Date()) {
            return next(new ErrorHandler('This claim token/QR code has expired. Please contact Milk Bank staff.', 400));
        }

        return res.status(200).json({
            success: true,
            valid: true,
            profileType: 'Patient',
            claimToken: cleanToken,
            details: {
                fullName: patient.name,
                motherName: patient.motherName || '',
                contactPhone: patient.phone || '',
                patientType: patient.patientType || 'Inpatient',
                addressSnippet: `${patient.home_address?.brgy || ''}, ${patient.home_address?.city || 'Pasig City'}`,
                admissionDate: patient.admissionDate,
                registrationDate: patient.createdAt
            }
        });
    }

    return next(new ErrorHandler('Invalid claim token or QR code. Record not found or already verified.', 400));
});

// ============================================================================
// FLOW B - STEP 2: CLAIM & BIND EXISTING RECORD => POST /api/v1/claim-record
// ============================================================================
exports.claimExistingRecord = catchAsyncErrors(async (req, res, next) => {
    let {
        claimToken,
        token,
        qrData,
        username,
        password,
        email,
        phone,
        firstName,
        lastName,
        profileType
    } = req.body;

    let rawTokenInput = claimToken || token || qrData || '';
    if (typeof rawTokenInput !== 'string' || !rawTokenInput.trim()) {
        return next(new ErrorHandler('Claim token or scannable QR data is required', 400));
    }

    rawTokenInput = rawTokenInput.trim();
    if (rawTokenInput.startsWith('{') && rawTokenInput.endsWith('}')) {
        try {
            const parsed = JSON.parse(rawTokenInput);
            if (parsed.token) rawTokenInput = parsed.token;
        } catch (_) { }
    }

    const cleanUsername = (username || '').trim().toLowerCase();
    if (!cleanUsername) {
        return next(new ErrorHandler('Please provide a unique username', 400));
    }

    const passwordValidation = validatePasswordPolicy(password);
    if (!passwordValidation.isValid) {
        return next(new ErrorHandler(passwordValidation.message, 400));
    }

    // Verify username availability
    const userExists = await User.findOne({ username: cleanUsername, isDeleted: false });
    if (userExists) {
        return next(new ErrorHandler('Username is already taken. Please choose another.', 400));
    }

    // If optional email is provided, verify uniqueness
    const cleanEmail = email && typeof email === 'string' && email.trim() ? email.trim().toLowerCase() : null;
    if (cleanEmail) {
        const emailExists = await User.findOne({ email: cleanEmail, isDeleted: false });
        if (emailExists) {
            return next(new ErrorHandler('Email address is already in use by another account.', 400));
        }
    }

    const rawToken = rawTokenInput.trim().toUpperCase();
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    // Search for unclaimed record matching hash and not expired
    let unclaimedRecord = null;
    let resolvedType = null;

    if (!profileType || profileType === 'Donor') {
        unclaimedRecord = await Donor.findOne({
            $or: [
                { claimTokenHash: tokenHash },
                { claimToken: rawToken }
            ],
            claimTokenExpires: { $gt: new Date() },
            user: null,
            isDeleted: false
        }).select('+claimTokenHash +claimTokenExpires');

        if (unclaimedRecord) resolvedType = 'Donor';
    }

    if (!unclaimedRecord && (!profileType || profileType === 'Patient')) {
        unclaimedRecord = await Patient.findOne({
            $or: [
                { claimTokenHash: tokenHash },
                { claimToken: rawToken }
            ],
            claimTokenExpires: { $gt: new Date() },
            user: null,
            isDeleted: false
        }).select('+claimTokenHash +claimTokenExpires');

        if (unclaimedRecord) resolvedType = 'Patient';
    }

    if (!unclaimedRecord) {
        return next(new ErrorHandler(
            'Invalid or expired claim token. Record was either already claimed, does not exist, or token has expired.',
            400
        ));
    }

    if (unclaimedRecord.user) {
        return next(new ErrorHandler('This record has already been claimed and linked to an account.', 409));
    }

    // Atomic transaction for account creation and record binding
    let session = null;
    let newUser = null;

    try {
        session = await mongoose.startSession();
        session.startTransaction();

        const contactPhone = phone || unclaimedRecord.phone || unclaimedRecord.contact_number || '09000000000';

        let userFirst = firstName ? firstName.trim() : '';
        let userLast = lastName ? lastName.trim() : '';
        let userMiddle = '';

        if (!userFirst || !userLast) {
            if (resolvedType === 'Donor') {
                userFirst = unclaimedRecord.name?.first || 'Donor';
                userMiddle = unclaimedRecord.name?.middle || '';
                userLast = unclaimedRecord.name?.last || 'Member';
            } else {
                userFirst = unclaimedRecord.motherName ? unclaimedRecord.motherName.split(' ')[0] : 'Mother';
                userLast = unclaimedRecord.name ? unclaimedRecord.name.split(' ').pop() : 'Patient';
            }
        }

        newUser = new User({
            username: cleanUsername,
            password,
            email: cleanEmail,
            phone: contactPhone,
            name: {
                first: userFirst,
                middle: userMiddle,
                last: userLast
            },
            role: 'User'
        });

        await newUser.save({ session });

        // Bind profile's user reference property to the new User._id
        unclaimedRecord.user = newUser._id;
        unclaimedRecord.claimToken = undefined;
        unclaimedRecord.claimTokenHash = undefined;
        unclaimedRecord.claimTokenExpires = undefined;
        unclaimedRecord.qrCodeData = null;

        if (unclaimedRecord.audit) {
            unclaimedRecord.audit.updatedBy = newUser._id;
        }

        await unclaimedRecord.save({ session });

        await session.commitTransaction();
    } catch (err) {
        if (session && session.inTransaction()) {
            try {
                await session.abortTransaction();
            } catch (_) { }
        }

        // If transactions aren't supported on standalone Mongo (e.g. local dev without replica set)
        if (err.message && (err.message.includes('replica set') || err.message.includes('Transaction numbers'))) {
            try {
                const contactPhone = phone || unclaimedRecord.phone || unclaimedRecord.contact_number || '09000000000';
                let userFirst = firstName ? firstName.trim() : '';
                let userLast = lastName ? lastName.trim() : '';
                let userMiddle = '';

                if (!userFirst || !userLast) {
                    if (resolvedType === 'Donor') {
                        userFirst = unclaimedRecord.name?.first || 'Donor';
                        userMiddle = unclaimedRecord.name?.middle || '';
                        userLast = unclaimedRecord.name?.last || 'Member';
                    } else {
                        userFirst = unclaimedRecord.motherName ? unclaimedRecord.motherName.split(' ')[0] : 'Mother';
                        userLast = unclaimedRecord.name ? unclaimedRecord.name.split(' ').pop() : 'Patient';
                    }
                }

                newUser = new User({
                    username: cleanUsername,
                    password,
                    email: cleanEmail,
                    phone: contactPhone,
                    name: {
                        first: userFirst,
                        middle: userMiddle,
                        last: userLast
                    },
                    role: 'User'
                });

                await newUser.save();

                unclaimedRecord.user = newUser._id;
                unclaimedRecord.claimToken = undefined;
                unclaimedRecord.claimTokenHash = undefined;
                unclaimedRecord.claimTokenExpires = undefined;
                unclaimedRecord.qrCodeData = null;

                if (unclaimedRecord.audit) {
                    unclaimedRecord.audit.updatedBy = newUser._id;
                }

                await unclaimedRecord.save();
            } catch (fallbackErr) {
                return next(new ErrorHandler(`Account binding failed: ${fallbackErr.message}`, 500));
            }
        } else {
            return next(new ErrorHandler(`Account binding failed: ${err.message}`, 500));
        }
    } finally {
        if (session) {
            try {
                session.endSession();
            } catch (_) { }
        }
    }

    return sendToken(newUser, 201, req, res, {
        message: `Existing ${resolvedType} profile claimed and linked successfully!`,
        profileType: resolvedType,
        profile: unclaimedRecord
    });
});
