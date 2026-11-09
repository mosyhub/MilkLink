const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;

const auditLogSchema = new mongoose.Schema({
    action: {
        type: String,
        required: true,
        enum: [
            'CREATE_FRIDGE',
            'UPDATE_FRIDGE',
            'DELETE_FRIDGE',
            'ARCHIVE_FRIDGE',
            'RESTORE_FRIDGE',
            'CREATE_ENTRY',
            'UPDATE_ENTRY',
            'DELETE_ENTRY',
            'ARCHIVE_ENTRY',
            'RESTORE_ENTRY',
            'PASTEURIZE',
            'FULFILL_REQUEST',
            'UPDATE_COLLECTION',
            'ARCHIVE_COLLECTION',
            'RESTORE_COLLECTION',
            'REVERSE_PICKUP',
            'CREATE_ACCOUNT',
            'DEACTIVATE_ACCOUNT',
            'REACTIVATE_ACCOUNT',
            'DELETE_ACCOUNT',
            'CHANGE_ROLE',
            'REVIEW_REQUEST',
            'APPROVE_REQUEST',
            'REJECT_REQUEST',
            'CANCEL_REQUEST',
            'CREATE_REQUEST',
            'UPDATE_REQUEST',
            'ARCHIVE_REQUEST',
            'RESTORE_REQUEST',
            'DELETE_REQUEST'
        ]
    },
    user: {
        type: ObjectId,
        ref: 'User'
    },
    userName: {
        type: String,
        default: 'Staff / Admin'
    },
    targetType: {
        type: String,
        enum: ['Fridge', 'Inventory', 'Collection', 'Request', 'Schedule', 'User']
    },
    targetId: {
        type: ObjectId
    },
    beforeVolume: {
        type: Number,
        default: 0
    },
    afterVolume: {
        type: Number,
        default: 0
    },
    volumeChanged: {
        type: Number,
        default: 0
    },
    reason: {
        type: String,
        default: ''
    },
    details: {
        type: mongoose.Schema.Types.Mixed
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('AuditLog', auditLogSchema);

