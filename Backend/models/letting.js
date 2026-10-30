const mongoose = require('mongoose');
const validator = require('validator');
const {ObjectId} = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const lettingSchema = mongoose.Schema({
    activity: {
        type: String,
        required: true
    },
    venue: {
        type: String,
        required: true
    },
    description: {
        type: String,
        
    },
    actDetails: {
        date: {
            type: Date,
            required: true
        },
        
    },
    status: {
        type: String,
        enum: ['Not-Due', 'On-Going', 'Done'],
        default: 'Not-Due'
    },
    attendance: [
        {
            donor: {
                type: ObjectId,
                ref: 'Donor',
                required: true
            },
            donorType: {
                type: String,
                enum: ['New Donor', 'Old Donor'],
                default: 'New Donor'
            },
            bags: [
                {
                    type: ObjectId,
                    ref: 'Bags',
                    required: true
                }
            ],
            additionalBags: [
                {
                    type: ObjectId,
                    ref: 'Bags'
                }
            ],
            lastDonation: {
                type: Date
            }
        },
    ],
    totalVolume: {
        type: Number,
        default: 0
    },
    
    admin: {
        type: ObjectId,
        required: true,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});
lettingSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Letting', lettingSchema);