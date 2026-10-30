const mongoose = require("mongoose");
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const donorSchema = new mongoose.Schema({
  user: {
    type: ObjectId,
    ref: "User",
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

  },
  submissionID: {
    type: String,
  },
  lastSubmissionDate: {
    type: Date,
  },
  dateTested: {
    type: Date,
  },
  verified: {
    type: Boolean,
    default: false,
  },
  dateTested: {
    type: Date
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
          required: [true, "Please enter age of the donor"]
        },
        unit: {
          enum: ["years", "months", "weeks", "days"],
          type: String,
          required: true
        }
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
        required: true,
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
        type: Number
      }
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});
donorSchema.plugin(softDeletePlugin)

donorSchema.virtual('age').get(function () {
  const now = new Date();
  const birth = new Date(this.birthday);

  const diffMs = now - birth;
  const ageDate = new Date(diffMs);

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
})
donorSchema.set('toObject', {virtuals: true});
donorSchema.set('toJSON', {virtuals: true});
module.exports = mongoose.model("Donor", donorSchema);
