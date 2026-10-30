const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete')
const articleSchema = mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    content: {
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
articleSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Article', articleSchema);  