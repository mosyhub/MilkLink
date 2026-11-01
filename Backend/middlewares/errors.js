const ErrorHandler = require('../utils/errorHandler');

module.exports = (err, req, res, next) => {
    // If response was already sent, delegate to default express error handler
    if (res.headersSent) {
        return next(err);
    }

    err.statusCode = err.statusCode || 500;

    let error = { ...err };
    error.message = err.message || 'Internal Server Error';

    // Wrong Mongoose Object ID Error
    if (err.name === 'CastError') {
        const message = `Resource Not Found. Invalid: ${err.path}`;
        error = new ErrorHandler(message, 400);
    }

    // Handling Mongoose Validation Error
    if (err.name === 'ValidationError') {
        const message = Object.values(err.errors).map(value => value.message).join(', ');
        error = new ErrorHandler(message, 400);
    }

    // Handling Mongoose duplicate key errors
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue || {})[0] || 'Field';
        const message = `${field.charAt(0).toUpperCase() + field.slice(1)} is already in use`;
        error = new ErrorHandler(message, 400);
    }

    // Handling wrong JWT error
    if (err.name === 'JsonWebTokenError') {
        const message = 'JSON Web Token is invalid. Try again!!!';
        error = new ErrorHandler(message, 400);
    }

    // Handling expired JWT error
    if (err.name === 'TokenExpiredError') {
        const message = 'JSON Web Token is expired. Try again!!!';
        error = new ErrorHandler(message, 400);
    }

    const statusCode = error.statusCode || err.statusCode || 500;
    const message = error.message || err.message || 'Internal Server Error';

    if (process.env.NODE_ENV === 'DEVELOPMENT') {
        return res.status(statusCode).json({
            success: false,
            message: message,
            errMessage: message,
            error: err,
            stack: err.stack
        });
    }

    return res.status(statusCode).json({
        success: false,
        message: message
    });
};
