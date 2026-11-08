const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const patientSchema = new mongoose.Schema({
    // Authenticated User Linkage (Flow A or claimed in Flow B)
    user: {
        type: ObjectId,
        ref: 'User',
        default: null,
        index: true,
    },
    name: {
        type: String,
        required: [true, 'Please enter name of the patient'],
        trim: true,
    },
    home_address: {
        street: {
            type: String,
            required: [true, 'Enter Street'],
        },
        brgy: {
            type: String,
            required: [true, 'Enter Baranggay'],
        },
        city: {
            type: String,
            required: [true, 'Enter City'],
        },
    },
    phone: {
        type: String,
        required: [true, 'Please enter contact number of the patient'],
        trim: true,
    },
    motherName: {
        type: String,
        required: [true, 'Please enter the name of the mother of patient'],
        trim: true,
    },
    patientType: {
        type: String,
        enum: ['Inpatient', 'Outpatient'],
        default: 'Inpatient',
    },
    age: {
        type: String,
    },
    aog: {
        type: String,
    },
    admissionDate: {
        type: Date,
    },
    staff: {
        type: ObjectId,
        required: [true, 'Staff ID required'],
        ref: 'User',
    },
    requested: [
        {
            type: ObjectId,
            required: true,
            ref: 'Request',
        },
    ],
    claimToken: {
        type: String,
        select: false,
        index: true,
    },
    claimTokenHash: {
        type: String,
        select: false,
        index: true,
    },
    claimTokenExpires: {
        type: Date,
        select: false,
    },
    qrCodeData: {
        type: String,
        default: null,
    },
    // Audit Trail
    audit: {
        createdBy: { type: ObjectId, ref: 'User' },
        updatedBy: { type: ObjectId, ref: 'User' },
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
}, {
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
});

// Claim Status Virtual
patientSchema.virtual('claimStatus').get(function () {
    return this.user ? 'Claimed / Linked' : 'Unclaimed';
});

patientSchema.plugin(softDeletePlugin);
module.exports = mongoose.model('Patient', patientSchema);