const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;

const notificationSchema = new mongoose.Schema({
    user: { 
        type: ObjectId, 
        ref: 'User', 
        required: true,
        unique: true
    },
    expoTokens: [
        {
            type: String,
            required: true
        }
    ],
    notifications: [
        {
            title: { type: String, required: true },
            body: { type: String, required: true },
            seen: { type: Boolean, default: false },
            notifiedAt: { type: Date, default: Date.now },
        }
    ],
    createdAt: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
