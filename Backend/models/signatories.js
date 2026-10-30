const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete')
const signatoriesSchema = mongoose.Schema({
    preparedBy: {
        name: {
            type: String,
            required: true
        },
        position: {
            type: String,
            required: true
        }
    },
    checkedBy: {
        name: {
            type: String,
            required: true
        },
        position: {
            type: String,
            required: true
        }
    },
    notedBy: {
       name: {
            type: String,
            required: true
        },
        position: {
            type: String,
            required: true
        }
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});
signatoriesSchema.plugin(softDeletePlugin)
module.exports = mongoose.model('Signatories', signatoriesSchema);  