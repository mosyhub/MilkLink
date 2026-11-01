
const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete');

const articleSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Article title is required'],
            trim: true,
        },

        description: {
            type: String,
            required: [true, 'Article description is required'],
        },

        content: {
            type: String,
            required: [true, 'Article content is required'],
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

articleSchema.plugin(softDeletePlugin);

module.exports = mongoose.model(
    'Article',
    articleSchema
);
