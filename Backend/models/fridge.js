const mongoose = require('mongoose');
const {ObjectId} = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const fridgeSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please enter name of refrigerator']
    },
    fridgeType: {
        type: String,
        enum: ['Unpasteurized', 'Pasteurized'],
        default: 'Unpasteurized'
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
});
fridgeSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Fridge', fridgeSchema);