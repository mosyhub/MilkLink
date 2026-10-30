const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const equipmentSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please enter the name of the equipment'],
        trim: true
    },
    equipType: {
        type: String,
        enum: ['Reusable', 'Consumable'],
        required: [true, 'Type of equipment is required']
    },
    quantity: {
        type: Number,
        required: [true, 'Please enter the quantity of the equipment'],
        min: [1, 'Quantity must be at least 1']
    },
    condition: {
        type: String,
        enum: ['New', 'Need Maintenance', 'Out of Service'],
        default: 'New',
        required: [true, 'Please specify the condition of the equipment']
    },
    location: {
        type: String,
        required: [true, 'Please specify the location of the equipment']
    },
    mainDate: {
        type: Date,
        default: null
    },
    usageLogs: [
        {
            usedBy: {
                type: ObjectId,
                ref: 'User',
            },
            dateUsed: {
                type: Date,
            },
            remarks: {
                type: String,
                trim: true
            }
        }
    ],
    invBy: {
        type: ObjectId,
        required: [true, 'TCHMB ADMIN ID required'],
        ref: 'User'
    },
    images: [
        {
            public_id: {
                type: String,
            },
            url: {
                type: String,
            },
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});
equipmentSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Equipment', equipmentSchema);
