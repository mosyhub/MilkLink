const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const screeningAppointmentSchema = new mongoose.Schema({
  appointmentId: {
    type: String,
    unique: true,
    sparse: true,
    index: true,
  },
  user: {
    type: ObjectId,
    ref: 'User',
    required: [true, 'User reference is required'],
    index: true,
  },
  donor: {
    type: ObjectId,
    ref: 'Donor',
    default: null,
    index: true,
  },
  purpose: {
    type: String,
    enum: [
      'First-Time Donor Screening',
      'Donor Re-assessment',
      'Laboratory Verification Follow-up',
      'Medical Evaluation'
    ],
    default: 'First-Time Donor Screening',
  },
  appointmentDate: {
    type: Date,
    required: [true, 'Please select an appointment date'],
    index: true,
  },
  timeSlot: {
    type: String,
    required: [true, 'Please select an appointment time slot'],
    trim: true,
  },
  hospital: {
    name: {
      type: String,
      default: 'Pasig City Human Milk Bank / Pasig-Pateros District Hospital',
    },
    room: {
      type: String,
      default: 'Room 204, Milk Bank Screening Clinic',
    },
    contactPhone: {
      type: String,
      default: '(02) 8643-0000 loc 204',
    },
  },
  status: {
    type: String,
    enum: [
      'Pending Confirmation',
      'Confirmed',
      'Rescheduled',
      'Cancelled by User',
      'Rejected by Staff',
      'Attended',
      'Completed',
      'No Show'
    ],
    default: 'Pending Confirmation',
    index: true,
  },
  attendanceRecorded: {
    type: Boolean,
    default: false,
  },
  attendanceRecordedAt: {
    type: Date,
    default: null,
  },
  screeningCompleted: {
    type: Boolean,
    default: false,
  },
  screeningCompletedAt: {
    type: Date,
    default: null,
  },
  assignedStaff: {
    type: ObjectId,
    ref: 'User',
    default: null,
  },
  statusReason: {
    type: String,
    default: '',
    trim: true,
  },
  donorNotes: {
    type: String,
    default: '',
    trim: true,
  },
  staffReviewNotes: {
    type: String,
    default: '',
    trim: true,
  },
  eligibilityDecisionRecommendation: {
    type: String,
    enum: [
      'Pending Decision',
      'Recommend Eligible',
      'Recommend Laboratory Follow-up',
      'Recommend Temporary Deferral',
      'Recommend Permanent Deferral'
    ],
    default: 'Pending Decision',
  },
  rescheduledHistory: [
    {
      previousDate: Date,
      previousTimeSlot: String,
      rescheduledBy: { type: ObjectId, ref: 'User' },
      reason: String,
      rescheduledAt: { type: Date, default: Date.now },
    }
  ],
  audit: {
    createdBy: { type: ObjectId, ref: 'User' },
    updatedBy: { type: ObjectId, ref: 'User' },
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

screeningAppointmentSchema.plugin(softDeletePlugin);

// Format formatted time / date virtual
screeningAppointmentSchema.virtual('formattedDateTime').get(function () {
  if (!this.appointmentDate) return '';
  const d = new Date(this.appointmentDate);
  return `${d.toISOString().split('T')[0]} (${this.timeSlot})`;
});

screeningAppointmentSchema.set('toObject', { virtuals: true });
screeningAppointmentSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('ScreeningAppointment', screeningAppointmentSchema);
