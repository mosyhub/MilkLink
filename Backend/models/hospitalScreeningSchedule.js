const mongoose = require('mongoose');
const softDeletePlugin = require('./plugins/softDelete');

const hospitalScreeningScheduleSchema = new mongoose.Schema({
  dayOfWeek: {
    type: Number, // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    min: 0,
    max: 6,
    required: true,
  },
  dayName: {
    type: String,
    required: true,
  },
  timeSlots: [
    {
      slotTime: { type: String, required: true }, // e.g., '09:00 AM - 10:00 AM'
      capacity: { type: Number, default: 4, min: 1 },
      isActive: { type: Boolean, default: true },
    }
  ],
  isActive: {
    type: Boolean,
    default: true,
  },
  specialDates: [
    {
      date: Date, // Specific holiday or closed date
      isClosed: { type: Boolean, default: true },
      reason: String,
    }
  ],
  audit: {
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    updatedAt: { type: Date, default: Date.now },
  }
});

hospitalScreeningScheduleSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('HospitalScreeningSchedule', hospitalScreeningScheduleSchema);
