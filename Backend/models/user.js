const mongoose = require('mongoose');
const validator = require('validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const softDeletePlugin = require('./plugins/softDelete');
const { validatePasswordPolicy } = require('../utils/passwordPolicy');

const userSchema = new mongoose.Schema({
    name: {
        last: {
            type: String,
            required: [true, 'Please enter last name'],
            trim: true,
            maxlength: [20, 'Last name cannot exceed 20 characters']
        },
        first: {
            type: String,
            required: [true, 'Please enter first name'],
            trim: true,
            maxlength: [20, 'First name cannot exceed 20 characters']
        },
        middle: {
            type: String,
            trim: true,
            maxlength: [20, 'Middle name cannot exceed 20 characters']
        }
    },
    username: {
        type: String,
        required: [true, 'Please enter username'],
        trim: true,
        lowercase: true,
        minlength: [4, 'Username must be at least 4 characters'],
        maxlength: [30, 'Username cannot exceed 30 characters'],
        match: [/^[a-zA-Z0-9_.-]+$/, 'Username can only contain alphanumeric characters, underscores, dots, or hyphens']
    },
    email: {
        type: String,
        trim: true,
        lowercase: true,
        validate: {
            validator: function (v) {
                if (!v || v.trim() === '') return true;
                return validator.isEmail(v);
            },
            message: 'Please enter a valid email address'
        }
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
        validate: {
            validator: function (v) {
                if (!v) return false;
                if (/^\$2[abxy]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(v)) return true;
                const { isValid } = validatePasswordPolicy(v);
                return isValid;
            },
            message: 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.'
        },
        select: false
    },
    phone: {
        type: String,
        required: [true, 'Please enter your phone'],
        trim: true,
        minlength: [11, 'Phone number is invalid'],
        maxlength: [15, 'Phone number is invalid']
    },
    avatar: {
        public_id: {
            type: String,
        },
        url: {
            type: String,
        }
    },
    role: {
        type: String,
        enum: {
            values: ['User', 'Staff', 'Admin', 'SuperAdmin'],
        },
        default: 'User'
    },
    accountStatus: {
        type: String,
        enum: ['Temporary', 'Verified', 'Suspended'],
        default: 'Temporary',
        index: true,
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    resetPasswordToken: { type: String, select: false },
    resetPasswordExpire: { type: Date, select: false }
}, {
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Unique email/username, but only among non-deleted users,
// and only if email is a non-empty string so multiple null/undefined/missing emails don't conflict.
userSchema.index(
    { email: 1 },
    {
        unique: true,
        partialFilterExpression: { isDeleted: false, email: { $type: 'string', $gt: '' } }
    }
);
userSchema.index(
    { username: 1 },
    {
        unique: true,
        partialFilterExpression: { isDeleted: false, username: { $type: 'string' } }
    }
);

// Full name virtual
userSchema.virtual('fullName').get(function () {
    const { first, middle, last } = this.name || {};
    return [first, middle, last].filter(Boolean).join(' ');
});

// Encrypting password before saving user
userSchema.pre('save', async function () {
    if (!this.isModified('password')) {
        return;
    }

    this.password = await bcrypt.hash(this.password, 10);
});

// Never leak sensitive fields in API responses
userSchema.methods.toJSON = function () {
    const obj = this.toObject();
    delete obj.password;
    delete obj.resetPasswordToken;
    delete obj.resetPasswordExpire;
    delete obj.__v;
    return obj;
};

// Compare user password
userSchema.methods.comparePassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// Return JWT token
userSchema.methods.getJwtToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_TIME
    });
};

// Generate Access Token (short-lived)
userSchema.methods.getAccessToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_SECRET, {
        expiresIn: '15m',
    });
};

// Generate Refresh Token (long-lived)
userSchema.methods.getRefreshToken = function () {
    return jwt.sign({ id: this._id, role: this.role }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: '7d',
    });
};

// Generate password reset token
userSchema.methods.getResetPasswordToken = function () {
    const resetToken = crypto.randomBytes(5).toString('hex');

    this.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    this.resetPasswordExpire = Date.now() + 30 * 60 * 1000;

    return resetToken;
};

userSchema.plugin(softDeletePlugin);
module.exports = mongoose.model('User', userSchema);
