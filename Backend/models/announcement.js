const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types; // Destructure ObjectId for references
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
        author: {
            type: ObjectId,
            ref: 'User',
            required: [true, 'Author/Staff reference is required'],
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        tags: [{ type: String, trim: true }]
    },
    {
        timestamps: true,
    }
);

// Soft delete
announcementSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Announcement', announcementSchema);
