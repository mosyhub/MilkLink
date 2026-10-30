const mongoose = require('mongoose');
const validator = require('validator');
const {ObjectId} = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const eventSchema = mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    eventDetails: {
        start: {
            type: Date,
            required: true
        },
        end: {
            type: Date,
            required: true
        }
        
    },
    eventStatus: {
        type: String,
        enum: ['Not-Due', 'On-Going', 'Done'],
        default: 'Not-Due',
        required: true
    },
    eventType: {
        type: String,
        enum: ['Grand Milk Letting', 'Regular Milk Letting', 'Other'],
        default: 'Other',
        required: true
    },
    user: {
        type: ObjectId,
        required: true,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})
eventSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Event', eventSchema)