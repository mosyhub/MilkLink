const mongoose = require("mongoose");
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const donorSchema = new mongoose.Schema({
  donorId: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
    index: true,
  },
  user: {
    type: ObjectId,
    ref: "User",
    default: null,
  },
  staff: {
    type: ObjectId,
    ref: "User",
    default: null,
  },
  name: {
    first: { type: String, trim: true, default: "" },
    middle: { type: String, trim: true, default: "" },
    last: { type: String, trim: true, default: "" },
  },
  home_address: {
    street: {
      type: String,
      required: [true, "Enter Street"],
    },
    brgy: {
      type: String,
      required: [true, "Enter Baranggay"],
    },
    city: {
      type: String,
      required: [true, "Enter City"],
    },
  },
  birthday: {
    type: Date,
    required: [true, "Please enter birthday of the donor"],
  },
  office_address: {
    type: String,
  },
  contact_number: {
    type: String,
  },
  occupation: {
    type: String,
  },
  donorType: {
    type: String,
    enum: ["Community", "Private", "Employee", "Network Office/Agency"],
    required: [true, "Please enter type of donor"],
  },
  eligibility: {
    type: String,
    enum: [
      'Pending Review',
      'For Laboratory Verification',
      'For Medical Assessment',
      'Eligible',
      'Temporarily Deferred',
      'Not Eligible'
    ],
    default: 'Pending Review',
  },
  claimToken: {
    type: String,
    select: false,
    index: true,
  },
  claimTokenHash: {
    type: String,
    select: false,
    index: true,
  },
  claimTokenExpires: {
    type: Date,
    select: false,
  },
  qrCodeData: {
    type: String,
    default: null,
  },
  audit: {
    createdBy: { type: ObjectId, ref: "User" },
    updatedBy: { type: ObjectId, ref: "User" },
  },
  submissionID: {
    type: String,
  },
  lastSubmissionDate: {
    type: Date,
  },
  verified: {
    type: Boolean,
    default: false,
  },
  dateTested: {
    type: Date,
  },
  children: [
    {
      name: { type: String },
      dateOfBirth: {
        type: Date,
      },
      age: {
        value: {
          type: Number,
          required: [true, "Please enter age of the donor"],
        },
        unit: {
          enum: ["years", "months", "weeks", "days"],
          type: String,
          required: true,
        },
      },
      birth_weight: {
        type: String,
      },
      aog: {
        type: String,
      },
    },
  ],
  donations: [
    {
      donationType: {
        type: String,
        enum: ["Public", "Private"],
        default: "Public",
      },
      schedule: {
        type: ObjectId,
        ref: "Schedule",
      },
      milkLettingEvent: {
        type: ObjectId,
        ref: "Letting",
      },
      totalVolume: {
        type: Number,
      },
      numberOfBags: {
        type: Number,
        default: 1,
      },
      collectionDate: {
        type: Date,
        default: Date.now,
      },
      batchReference: {
        type: String,
      },
      status: {
        type: String,
        enum: [
          'Collected',
          'For Inspection',
          'For Processing',
          'Pasteurized',
          'Quality-Control Review',
          'Available for Dispensing',
          'Dispensed',
          'On Hold',
          'Rejected',
          'Expired'
        ],
        default: 'Collected',
      },
      recordedBy: {
        type: ObjectId,
        ref: "User",
      },
      notes: {
        type: String,
      },
    },
  ],
  screening: {
    questionnaire: {
      type: Map,
      of: String,
      default: {},
    },
    laboratory: {
      cbc: { type: String, default: null },
      hiv: { type: String, default: null },
      hbsag: { type: String, default: null },
      antiHcv: { type: String, default: null },
      labDateTested: { type: Date, default: null },
      documents: [
        {
          category: {
            type: String,
            enum: ['CBC', 'HIV', 'HBsAg', 'Anti-HCV', 'Other'],
            required: true,
          },
          url: { type: String, required: true },
          public_id: { type: String },
          fileName: { type: String },
          fileType: { type: String },
          uploadedAt: { type: Date, default: Date.now },
          verified: { type: Boolean, default: false },
          ocrExtractedText: { type: String, default: null },
          ocrExtractedData: { type: mongoose.Schema.Types.Mixed, default: null },
        }
      ],
    },
    consentSigned: { type: Boolean, default: false },
    consentDate: { type: Date, default: null },
    consentVersion: { type: String, default: '1.0' },
    signatureUrl: { type: String, default: null },
    reviewNotes: { type: String, default: '' },
    reviewedBy: { type: ObjectId, ref: 'User' },
    reviewedAt: { type: Date, default: null },
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Enforce unique 1-to-1 linkage for claimed donors (ignoring unclaimed null users)
donorSchema.index(
  { user: 1 },
  {
    unique: true,
    partialFilterExpression: { isDeleted: false, user: { $type: 'objectId' } }
  }
);

donorSchema.plugin(softDeletePlugin);

donorSchema.virtual('fullName').get(function () {
  const n = this.name || {};
  return [n.first, n.middle, n.last].filter(Boolean).join(' ').trim();
});

// Claim Status Virtual
donorSchema.virtual('claimStatus').get(function () {
  return this.user ? 'Claimed / Linked' : 'Unclaimed';
});

donorSchema.virtual('age').get(function () {
  if (!this.birthday) return 'N/A';
  const now = new Date();
  const birth = new Date(this.birthday);

  const diffMs = now - birth;
  const years = now.getFullYear() - birth.getFullYear();
  const months = now.getMonth() - birth.getMonth() + (years * 12);
  const weeks = Math.floor(diffMs / (1000 * 60 * 60 * 24 * 7));
  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (years >= 1) {
    return `${years} year${years > 1 ? 's' : ''} old`;
  } else if (months >= 1) {
    return `${months} month${months > 1 ? 's' : ''} old`;
  } else if (weeks >= 1) {
    return `${weeks} week${weeks > 1 ? 's' : ''} old`;
  } else {
    return `${days} day${days > 1 ? 's' : ''} old`;
  }
});

donorSchema.set('toObject', { virtuals: true });
donorSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model("Donor", donorSchema);
