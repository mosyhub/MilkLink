const User = require('../models/user');
const AuditLog = require('../models/auditLog');
const Schedule = require('../models/schedule');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const mongoose = require('mongoose');

// GET /api/v1/admin/accounts
exports.getAccounts = catchAsyncErrors(async (req, res, next) => {
    const { role, status, search, page = 1, limit = 20 } = req.query;

    const query = {
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    };

    if (role) {
        if (role === 'Other') {
            query.role = 'User';
        } else {
            query.role = role;
        }
    }

    if (status && status !== 'All') {
        if (status === 'Active') {
            // Existing users in database created before the 'status' field was introduced
            // have status: undefined or null, or 'Active'
            query.$or = [
                { status: 'Active' },
                { status: { $exists: false } },
                { status: null }
            ];
        } else {
            query.status = status;
        }
    }

    if (search && search.trim() !== '') {
        const regex = new RegExp(search.trim(), 'i');
        const searchCondition = [
            { 'name.first': regex },
            { 'name.last': regex },
            { username: regex },
            { email: regex }
        ];

        if (query.$or) {
            query.$and = [
                { $or: query.$or },
                { $or: searchCondition }
            ];
            delete query.$or;
        } else {
            query.$or = searchCondition;
        }
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const limitNum = parseInt(limit, 10);

    const [accounts, total] = await Promise.all([
        User.find(query)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum)
            .select('-password -resetPasswordToken -resetPasswordExpire'),
        User.countDocuments(query)
    ]);

    res.status(200).json({
        success: true,
        accounts,
        total,
        page: parseInt(page, 10),
        pages: Math.ceil(total / limitNum) || 1
    });
});

// GET /api/v1/admin/account/:id
exports.getAccountById = catchAsyncErrors(async (req, res, next) => {
    const user = await User.findOne({
        _id: req.params.id,
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    }).select('-password -resetPasswordToken -resetPasswordExpire');

    if (!user) {
        return next(new ErrorHandler('Account not found', 404));
    }

    const auditHistory = await AuditLog.find({
        targetType: 'User',
        targetId: user._id
    })
        .sort({ timestamp: -1 })
        .limit(20);

    const userObj = user.toJSON ? user.toJSON() : user.toObject();
    userObj.auditHistory = auditHistory;

    res.status(200).json({
        success: true,
        account: userObj
    });
});

// POST /api/v1/admin/accounts
exports.createAccount = catchAsyncErrors(async (req, res, next) => {
    const { firstName, lastName, middleName, email, username, phone, role, password } = req.body;

    if (!role || !['Staff', 'Admin'].includes(role)) {
        return next(new ErrorHandler('Role must be Staff or Admin', 400));
    }

    if (!username || !email || !password || !firstName || !lastName || !phone) {
        return next(new ErrorHandler('Please provide all required fields', 400));
    }

    const existingUser = await User.findOne({
        isDeleted: { $ne: true },
        $or: [
            { username: username.toLowerCase().trim() },
            { email: email.toLowerCase().trim() }
        ]
    });

    if (existingUser) {
        if (existingUser.username === username.toLowerCase().trim()) {
            return next(new ErrorHandler('Username is already taken', 400));
        }
        if (existingUser.email === email.toLowerCase().trim()) {
            return next(new ErrorHandler('Email is already registered', 400));
        }
    }

    const newUser = await User.create({
        name: {
            first: firstName.trim(),
            last: lastName.trim(),
            middle: middleName ? middleName.trim() : undefined
        },
        username: username.toLowerCase().trim(),
        email: email.toLowerCase().trim(),
        phone: phone.trim(),
        role,
        password,
        status: 'Active',
        accountStatus: 'Temporary',
        mustChangePassword: true
    });

    await AuditLog.create({
        action: 'CREATE_ACCOUNT',
        user: req.user._id,
        userName: req.user.fullName || req.user.username || 'Admin',
        targetType: 'User',
        targetId: newUser._id,
        reason: 'Account created by admin',
        details: { role, username: newUser.username }
    });

    const userObj = newUser.toJSON ? newUser.toJSON() : newUser.toObject();

    res.status(201).json({
        success: true,
        account: userObj
    });
});

// PUT /api/v1/admin/account/:id/role
exports.updateAccountRole = catchAsyncErrors(async (req, res, next) => {
    const bodyKeys = Object.keys(req.body);
    if (bodyKeys.length !== 1 || !bodyKeys.includes('role')) {
        return next(new ErrorHandler('Only the role field can be updated', 400));
    }

    const { role } = req.body;
    if (!['Staff', 'Admin'].includes(role)) {
        return next(new ErrorHandler('Role must be Staff or Admin', 400));
    }

    if (req.user._id.toString() === req.params.id) {
        return next(new ErrorHandler('You cannot change your own role', 403));
    }

    const targetUser = await User.findOne({
        _id: req.params.id,
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    });

    if (!targetUser) {
        return next(new ErrorHandler('Account not found', 404));
    }

    if (targetUser.role === 'Admin' && role !== 'Admin') {
        const activeAdminCount = await User.countDocuments({
            role: 'Admin',
            status: 'Active',
            isDeleted: { $ne: true }
        });

        if (activeAdminCount <= 1) {
            return next(new ErrorHandler('Cannot demote the last active Admin account', 400));
        }
    }

    const oldRole = targetUser.role;
    targetUser.role = role;
    await targetUser.save();

    await AuditLog.create({
        action: 'CHANGE_ROLE',
        user: req.user._id,
        userName: req.user.fullName || req.user.username || 'Admin',
        targetType: 'User',
        targetId: targetUser._id,
        reason: `Role changed from ${oldRole} to ${role}`,
        details: { oldRole, newRole: role }
    });

    res.status(200).json({
        success: true,
        account: targetUser
    });
});

// PUT /api/v1/admin/account/:id/deactivate
exports.deactivateAccount = catchAsyncErrors(async (req, res, next) => {
    if (req.user._id.toString() === req.params.id) {
        return next(new ErrorHandler('You cannot deactivate your own account', 403));
    }

    const targetUser = await User.findOne({
        _id: req.params.id,
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    });

    if (!targetUser) {
        return next(new ErrorHandler('Account not found', 404));
    }

    if (targetUser.role === 'Admin' && targetUser.status === 'Active') {
        const activeAdminCount = await User.countDocuments({
            role: 'Admin',
            status: 'Active',
            isDeleted: { $ne: true }
        });

        if (activeAdminCount <= 1) {
            return next(new ErrorHandler('Cannot deactivate the last active Admin account', 400));
        }
    }

    const { reason } = req.body;
    targetUser.status = 'Deactivated';
    targetUser.deactivationReason = reason || '';
    targetUser.deactivatedAt = new Date();
    targetUser.deactivatedBy = req.user._id;
    await targetUser.save();

    await AuditLog.create({
        action: 'DEACTIVATE_ACCOUNT',
        user: req.user._id,
        userName: req.user.fullName || req.user.username || 'Admin',
        targetType: 'User',
        targetId: targetUser._id,
        reason: reason || 'Deactivated by admin'
    });

    res.status(200).json({
        success: true,
        message: 'Account deactivated'
    });
});

// PUT /api/v1/admin/account/:id/reactivate
exports.reactivateAccount = catchAsyncErrors(async (req, res, next) => {
    const targetUser = await User.findOne({
        _id: req.params.id,
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    });

    if (!targetUser) {
        return next(new ErrorHandler('Account not found', 404));
    }

    targetUser.status = 'Active';
    targetUser.deactivationReason = undefined;
    targetUser.deactivatedAt = undefined;
    targetUser.deactivatedBy = undefined;
    await targetUser.save();

    await AuditLog.create({
        action: 'REACTIVATE_ACCOUNT',
        user: req.user._id,
        userName: req.user.fullName || req.user.username || 'Admin',
        targetType: 'User',
        targetId: targetUser._id,
        reason: 'Account reactivated by admin'
    });

    res.status(200).json({
        success: true,
        message: 'Account reactivated'
    });
});

// DELETE /api/v1/admin/account/:id
exports.deleteAccount = catchAsyncErrors(async (req, res, next) => {
    if (req.user._id.toString() === req.params.id) {
        return next(new ErrorHandler('You cannot delete your own account', 403));
    }

    const targetUser = await User.findOne({
        _id: req.params.id,
        role: { $ne: 'SuperAdmin' },
        isDeleted: { $ne: true }
    });

    if (!targetUser) {
        return next(new ErrorHandler('Account not found', 404));
    }

    if (targetUser.role === 'Admin') {
        const activeAdminCount = await User.countDocuments({
            role: 'Admin',
            status: 'Active',
            isDeleted: { $ne: true }
        });

        if (activeAdminCount <= 1) {
            return next(new ErrorHandler('Cannot delete the last active Admin account', 400));
        }
    }

    // Activity check: linked schedules or activity logs
    const [hasSchedules, hasActivityLogs] = await Promise.all([
        Schedule.findOne({
            $or: [
                { approvedBy: targetUser._id },
                { 'donorDetails.donorId': targetUser._id }
            ],
            isDeleted: { $ne: true }
        }),
        AuditLog.findOne({
            user: targetUser._id,
            action: {
                $nin: ['CREATE_ACCOUNT', 'DEACTIVATE_ACCOUNT', 'REACTIVATE_ACCOUNT', 'CHANGE_ROLE']
            }
        })
    ]);

    if (hasSchedules || hasActivityLogs) {
        return res.status(409).json({
            success: false,
            message: 'This account has activity records. Deactivate it instead.',
            suggest: 'deactivate'
        });
    }

    targetUser.isDeleted = true;
    targetUser.deletedAt = new Date();
    await targetUser.save();

    await AuditLog.create({
        action: 'DELETE_ACCOUNT',
        user: req.user._id,
        userName: req.user.fullName || req.user.username || 'Admin',
        targetType: 'User',
        targetId: targetUser._id,
        reason: 'Account permanently deleted'
    });

    res.status(200).json({
        success: true,
        message: 'Account deleted'
    });
});

