const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const consentSchema = new mongoose.Schema({
  donor: {
    type: ObjectId,
    ref: 'Donor',
    required: true,
    index: true,
  },
  user: {
    type: ObjectId,
    ref: 'User',
    default: null,
  },
  consentVersion: {
    type: String,
    required: true,
    default: '1.0',
  },
  consentText: {
    type: String,
    required: true,
  },
  acknowledged: {
    type: Boolean,
    required: [true, 'Consent acknowledgment is mandatory'],
  },
  signatureDataUrl: {
    type: String,
    required: [true, 'Signature data is required'],
  },
  signerName: {
    type: String,
    required: [true, 'Signer name is required'],
    trim: true,
  },
  signedAt: {
    type: Date,
    default: Date.now,
  },
  ipAddress: {
    type: String,
    default: null,
  },
  userAgent: {
    type: String,
    default: null,
  },
  status: {
    type: String,
    enum: ['Active', 'Superseded', 'Revoked'],
    default: 'Active',
  },
  renewedAt: {
    type: Date,
    default: null,
  },
  audit: {
    recordedBy: { type: ObjectId, ref: 'User' },
    verifiedByStaff: { type: ObjectId, ref: 'User' },
    verifiedAt: { type: Date, default: null },
  },
}, {
  timestamps: true,
});

consentSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('DonorConsent', consentSchema);
