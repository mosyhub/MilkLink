const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const scheduleSchema = mongoose.Schema({
    kind: {
        type: String,
        enum: ['Event', 'Pickup'],
        default: 'Event'
    },
    title: { type: String, trim: true },
    date: { type: Date },
    dates: { type: Date },
    startDate: { type: Date },
    endDate: { type: Date },
    dateRange: { type: String, trim: true },
    startTime: { type: String, trim: true },
    endTime: { type: String, trim: true },
    time: { type: String, trim: true },
    location: { type: String, trim: true },
    address: { type: String, trim: true },
    description: { type: String, trim: true },
    donorName: { type: String, trim: true },
    pickupAddress: { type: String, trim: true },
    contactNumber: { type: String, trim: true },
    pickupStatus: {
        type: String,
        enum: ['Pending', 'Scheduled', 'Picked Up', 'Cancelled'],
        default: 'Pending'
    },
    donorDetails: {
        donorId: {
            type: ObjectId,
            ref: 'Donor'
        },
        bags: [   
            {
                type: ObjectId,
                ref: 'Bags',
            }
        ]
    },
    totalVolume: {
        type: Number,
        default: 0 
    },
    status: {
        type: String,
        enum: ['Pending', 'Scheduled', 'Approved', 'Completed', 'Cancelled'],
        default: 'Pending'
    },
    approvedBy: {
        type: ObjectId,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Pre-save hook to ensure legacy compatibility between dates/startDate and address/location/pickupAddress
scheduleSchema.pre('save', function () {
    if (!this.dates) {
        this.dates = this.startDate || this.date || new Date();
    }
    if (!this.date) {
        this.date = this.dates || this.startDate || new Date();
    }
    if (!this.address) {
        this.address = this.pickupAddress || this.location || 'N/A';
    }
    if (!this.location) {
        this.location = this.address || this.pickupAddress || 'N/A';
    }
    if (!this.pickupAddress) {
        this.pickupAddress = this.address || this.location || 'N/A';
    }
    if (!this.time && this.startTime && this.endTime) {
        this.time = `${this.startTime} - ${this.endTime}`;
    }
    if (this.kind === 'Event' && !this.status) {
        this.status = 'Pending';
    }
});

scheduleSchema.plugin(softDeletePlugin);
module.exports = mongoose.model('Schedule', scheduleSchema);
