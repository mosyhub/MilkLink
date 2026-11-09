const catchAsyncErrors = require('./catchAsyncErrors');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const ErrorHandler = require('../utils/errorHandler');

// Check if user is authenticated
exports.isAuthenticatedUser = catchAsyncErrors(async (req, res, next) => {
    let token;

    if (req.headers.authorization?.startsWith('Bearer ')) {
        token = req.headers.authorization.split(' ')[1];
    } else if (req.cookies?.accessToken) {
        token = req.cookies.accessToken;
    }

    if (!token) {
        return next(new ErrorHandler('Please login to access this resource', 401));
    }

    let decoded;

    try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        return next(new ErrorHandler('Invalid or expired token', 401));
    }

    const user = await User.findById(decoded.id);

    if (!user) {
        return next(new ErrorHandler('User no longer exists', 401));
    }

    if (user.status === 'Deactivated') {
        return next(new ErrorHandler('This account is deactivated. Contact an administrator.', 403));
    }

    req.user = user;

    // Fire-and-forget lastLogin update — don't await to avoid latency
    User.findByIdAndUpdate(decoded.id, { lastLogin: new Date() }).catch(() => { });

    return next();
});

// Check user roles
exports.authorizeRoles = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new ErrorHandler('Please login first', 401));
        }

        if (!roles.includes(req.user.role)) {
            return next(
                new ErrorHandler(
                    `Role (${req.user.role}) is not allowed to access this resource`,
                    403
                )
            );
        }

        return next();
    };
};

// Optional authentication - populates req.user if valid token exists, doesn't throw if not
exports.optionalAuth = catchAsyncErrors(async (req, res, next) => {
    let token;

    if (req.headers.authorization?.startsWith('Bearer ')) {
        token = req.headers.authorization.split(' ')[1];
    } else if (req.cookies?.accessToken) {
        token = req.cookies.accessToken;
    }

    if (!token) {
        return next();
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id);
        if (user && user.status !== 'Deactivated') {
            req.user = user;
        }
    } catch (_) { }

    return next();
});
