const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const scheduleSchema = mongoose.Schema({
    dates: {
        type: Date,
        required: true
    },
    address: {
        type: String,
        required: true
    },
    donorDetails: {
        donorId: {
            type: ObjectId,
            required: true,
            ref: 'Donor'
        },
        bags: [   
            {
                type: ObjectId,
                ref: 'Bags',
                required: true
            }
        ]
    },
    totalVolume: {
        type: Number,
        default: 0 
    },
    status: {
        type: String,
        enum: ['Pending', 'Approved', 'Completed'],
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
scheduleSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Schedule', scheduleSchema);