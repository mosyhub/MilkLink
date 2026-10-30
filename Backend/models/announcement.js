const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete')
const announcementSchema = mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    images: [
        {
            public_id: {
                type: String,
            },
            url: {
                type: String,
            }
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});
announcementSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Announcement', announcementSchema);  