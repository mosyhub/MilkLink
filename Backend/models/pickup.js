const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const pickupRequestSchema = new mongoose.Schema({
  pickupId: {
    type: String,
    unique: true,
    sparse: true,
  },
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
  barangay: {
    type: String,
    required: [true, 'Please select your barangay in Pasig City'],
  },
  pickupAddress: {
    type: String,
    required: [true, 'Please provide exact pickup street address'],
  },
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  preferredDate: {
    type: Date,
    required: [true, 'Please choose a preferred collection date'],
  },
  preferredTimeSlot: {
    type: String,
    enum: ['Morning (8:00 AM - 11:30 AM)', 'Afternoon (1:00 PM - 4:30 PM)'],
    required: true,
  },
  estimatedBags: {
    type: Number,
    default: 1,
  },
  estimatedVolumeMl: {
    type: Number,
    default: null,
  },
  contactNumber: {
    type: String,
    required: true,
  },
  donorNotes: {
    type: String,
    default: '',
  },
  assignedOutpost: {
    outpostId: { type: String, default: 'OUTPOST-1' },
    outpostName: {
      type: String,
      default: 'Pasig City Central Milk Bank Station - PCGH'
    },
    serviceArea: { type: String, default: 'Pasig City Health Zone 1' },
    assignedStaff: { type: ObjectId, ref: 'User', default: null },
    assignedAt: { type: Date, default: null },
  },
  status: {
    type: String,
    enum: [
      'Pending',
      'Assigned',
      'On the Way',
      'Arrived',
      'Collected',
      'Rescheduled',
      'Cancelled'
    ],
    default: 'Pending',
    index: true,
  },
  statusHistory: [
    {
      status: { type: String, required: true },
      timestamp: { type: Date, default: Date.now },
      updatedBy: { type: ObjectId, ref: 'User' },
      comment: { type: String, default: '' },
    }
  ],
  collectedDonationRecord: {
    bagsCollected: { type: Number, default: 0 },
    volumeCollectedMl: { type: Number, default: 0 },
    collectedAt: { type: Date, default: null },
    batchReference: { type: String, default: null },
  },
  audit: {
    createdBy: { type: ObjectId, ref: 'User' },
    updatedBy: { type: ObjectId, ref: 'User' },
  }
}, {
  timestamps: true,
});

pickupRequestSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('PickupRequest', pickupRequestSchema);
