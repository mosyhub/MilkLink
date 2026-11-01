const User = require('../models/user');
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

    res.status(200).json({
        success: true,
        user
    })
})

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

// Update user profile => /api/v1/me/update
exports.updateProfile = catchAsyncErrors(async (req, res, next) => {

    const newUserData = {
        name: req.body.name,
        email: req.body.email
    }

    // Update avatar
    // if(req.body.avatar !== '') {
    //     const user = await User.findById(req.user.id);

    //     const image_id = user.avatar.public_id;
    //     const res = await cloudinary.v2.uploader.destroy;

    //     const result = await cloudinary.v2.uploader.upload(req.body.avatar, {
    //         folder: 'avatar',
    //         width: 150,
    //         crop: "scale"
    //     });

    //     newUserData.avatar = {
    //         public_id: result.public_id,
    //         url: result.url
    //     }

    // }

    const user = await User.findByIdAndUpdate(req.user.id, newUserData, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        user,
        success: true
    })

})

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
    const user = await User.find({_id: id});
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