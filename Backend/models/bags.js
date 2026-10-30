const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const bagSchema = new mongoose.Schema({
    collectionType: {
        type: String,
        enum: ['Public','Private'],
        required: true
    },
    expressDate: {
        type: Date,
        default: Date.now,
    },
    donor: {
        type: ObjectId,
        ref: 'Donor',
        required: [true, 'User is needed to complete inventory'],
    },
    status: {
        type: String,
        enum: ['Expressed','Scheduled','Collected','Pasteurized'],
        default: 'Expressed',
        required: true
    },
    volume: {
        type: Number,
        required: true,
        min: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

bagSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Bags', bagSchema);