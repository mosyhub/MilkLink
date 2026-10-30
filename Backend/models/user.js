const mongoose = require('mongoose');
const validator = require('validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const softDeletePlugin = require('./plugins/softDelete')
const userSchema = new mongoose.Schema({
    name: {
        last: {
            type: String,
            required: [true, 'Please enter last name']
        },
        first: {
            type: String,
            required: [true, 'Please enter first name']
        },
        middle: {
            type: String,
            
        }
    },
    email: {
        type: String,
        // required: [true, 'Please enter your email'],
        // unique: true,
        // validate: [validator.isEmail, 'Please enter valid email address']
    },
    employeeID: {
        type: Number,
        unique: true,
        sparse: true,
        default: undefined,
    },
    password: {
        type: String,
        required: [true, 'Please enter your password'],
        // minlength: [6, 'Your password must be longer than 6 characters'],
        select: false
    },
    phone: {
        type: String,
        required: [true, 'Please enter your phone'],
        // minlength: [11, 'Phone number is invalid'],
    },
    avatar: {
        public_id: {
            type: String,
            // required: true
        },
        url: {
            type: String,
            // required: true
        }
    },
    role: {
        type: String,
        enum: ['User', 'Staff', 'Admin', 'SuperAdmin'],
        default: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    resetPasswordToken: String,
    resetPasswordExpire: Date
});

// Encrypting password before saving user
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) {
        next()
    }

    this.password = await bcrypt.hash(this.password, 10);
});

// Compare user password
userSchema.methods.comparePassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password)
}

// Return JWT token
userSchema.methods.getJwtToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_TIME
    });
}
// Generate Access Token (short-lived)
userSchema.methods.getAccessToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_SECRET, {
        expiresIn: '15m', // short-lived token
    });
};

// Generate Refresh Token (long-lived)
userSchema.methods.getRefreshToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: '7d', // longer-lived token
    });
};

// Generate password reset token
userSchema.methods.getResetPasswordToken = function () {
    // Generate token 
    const resetToken = crypto.randomBytes(5).toString('hex');

    // Hash and set to resetPasswordToken
    this.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    // Set token expire time 
    this.resetPasswordExpire = Date.now() + 30 * 60 * 1000;

    return resetToken;
}

userSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('User', userSchema);