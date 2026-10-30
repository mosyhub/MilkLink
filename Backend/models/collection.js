const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const collectionSchema = new mongoose.Schema({
    collectionType: {
        type: String,
        enum: ['Public', 'Private'],
        default: 'Public',
        required: [true, 'Must specify collection type']
    },
    collectionDate: {
        type: Date,
        required: true
    },
    user: [
        {
            type: ObjectId,
            required: [true, 'Admin user is needed to complete the collection'],
            ref: 'User'
        }
    ],
    status: {
        type: String,
        enum: ['Pending', 'Collected', 'Stored', 'Dispensed'],
        default: 'Pending'
    },
    pubDetails: {
        type: ObjectId,
        ref: 'Letting'
    },
    privDetails: {
        type: ObjectId,
        ref: 'Schedule'
    },
    notes: {
        type: String 
    }
});
collectionSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Collection', collectionSchema);