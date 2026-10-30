const mongoose = require('mongoose');
const {ObjectId} = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const patientSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please enter name of the patient']
    },
    home_address: {
        street: {
            type: String,
            required: [true, 'Enter Street']
        },
        brgy: {
            type: String,
            required: [true, 'Enter Baranggay']
        },
        city: {
            type: String,
            required: [true, 'Enter City']
        }
    },
    phone: {
        type: String,
        required: [true, 'Please enter contact number of the patient']
    },
    motherName: {
        type: String,
        required: [true, 'Please enter the name of the mother of patient']
    },
    patientType: {
        type: String,
        enum: ['Inpatient', 'Outpatient'],
        default: 'Inpatient',
    },
    age: {
        type: String,
        // required: [true, 'Please enter age of the patient']
    },
    aog: {
        type: String,
        // required: [true, 'Please enter the age of gestation of the patient']
    },
    admissionDate: {
        type: Date,
        // required: [true, 'Please enter the admission date of the patient']
    },
    staff: {
        type: ObjectId,
        required: [true, 'Staff ID required'],
        ref: 'User'
    },
    requested: [
        {
            type: ObjectId,
            required: true,
            ref: 'Request'
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    },
});

patientSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Patient', patientSchema);