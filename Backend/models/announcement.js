const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete');

const announcementSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Announcement title is required'],
            trim: true,
        },

        description: {
            type: String,
            required: [true, 'Announcement description is required'],
        },

        images: [
            {
                public_id: {
                    type: String,
                },
                url: {
                    type: String,
                },
            },
        ],
    },
    {
        timestamps: true,
    }
);

// Soft delete
announcementSchema.plugin(softDeletePlugin);

module.exports = mongoose.model(
    'Announcement',
    announcementSchema
);
