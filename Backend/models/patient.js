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
    // Structured Patient Intake Questionnaire
    intakeQuestionnaire: {
        patientDetails: {
            birthWeightGrams: { type: Number },
            currentWeightGrams: { type: Number },
            gestationalAgeWeeks: { type: Number },
            clinicalDiagnosis: { type: String, default: '' },
            attendingPhysician: { type: String, default: '' },
            hospitalOrWard: { type: String, default: 'NICU' },
        },
        motherInfo: {
            motherAge: { type: Number },
            gravida: { type: Number },
            para: { type: Number },
            obstetricHistory: { type: String, default: '' },
            maternalMedicalHistory: { type: String, default: '' },
        },
        feedingHistory: {
            feedingMethod: {
                type: String,
                enum: ['OGT/NGT', 'Cup Feeding', 'Bottle Feeding', 'Direct Breastfeeding', 'NPO', 'Other'],
                default: 'OGT/NGT',
            },
            lactationDifficulties: { type: String, default: 'Insufficient milk supply / maternal separation' },
            currentMilkTolerance: { type: String, default: 'Tolerating well' },
            dailyCaloricRequirement: { type: String, default: '' },
        },
        medicalInfo: {
            isPremature: { type: Boolean, default: false },
            isLowBirthWeight: { type: Boolean, default: false },
            hasNecrotizingEnterocolitisRisk: { type: Boolean, default: false },
            knownAllergies: [{ type: String }],
            clinicalContraindications: [{ type: String }],
        },
        milkRequestNeeds: {
            initialVolumeRequestedMl: { type: Number, default: 0 },
            estimatedDaysNeeded: { type: Number, default: 3 },
            urgencyLevel: {
                type: String,
                enum: ['Routine', 'Urgent', 'Critical / Emergency'],
                default: 'Routine',
            },
            priorityTier: {
                type: String,
                enum: ['Tier 1 (VLBW / Premature / NICU)', 'Tier 2 (Surgical / Pathological)', 'Tier 3 (Maternal Illness / Absence)', 'Tier 4 (Temporary Supplementation)'],
                default: 'Tier 1 (VLBW / Premature / NICU)',
            },
        },
    },
    // Flow B: Single-use Claim Token & QR Code Footprint
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