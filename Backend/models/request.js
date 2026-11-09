const mongoose = require("mongoose");
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const historyEntrySchema = new mongoose.Schema({
  action: {
    type: String,
    required: true,
  },
  actor: {
    type: ObjectId,
    ref: "User",
  },
  actorName: {
    type: String,
    default: "Staff / Admin",
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
  notes: {
    type: String,
    default: "",
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
  },
}, { _id: false });

const requestSchema = new mongoose.Schema({
  requestNumber: {
    type: String,
    trim: true,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  patient: {
    type: ObjectId,
    ref: "Patient",
  },
  recipientName: {
    type: String,
    trim: true,
  },
  relationToRecipient: {
    type: String,
    enum: ["Mother / Guardian", "Father", "Healthcare Provider", "Relative / Foster", "Mother", "Guardian", "Father / Relative", "Other"],
    default: "Mother / Guardian",
  },
  volumeRequested: {
    volume: {
      type: Number,
      required: [true, "Please enter Volume Requested"],
    },
    days: {
      type: Number,
      default: 7,
    },
  },
  approvedVolume: {
    type: Number,
  },
  reason: {
    type: String,
    trim: true,
  },
  hospital: {
    type: String,
    default: "Pasig-Pateros District Hospital",
  },
  department: {
    type: String,
  },
  doctor: {
    type: String,
    default: "Attending Staff",
  },
  additionalRemarks: {
    type: String,
    trim: true,
  },
  notes: {
    type: String,
    default: "",
  },
  requestedBy: {
    type: ObjectId,
    ref: "User",
  },
  status: {
    type: String,
    enum: ["Pending", "Under Review", "Approved", "Fulfilled", "Rejected", "Cancelled", "Reserved", "Done", "Canceled"],
    default: "Pending",
  },
  rejectionReason: {
    type: String,
    trim: true,
  },
  cancellationReason: {
    type: String,
    trim: true,
  },
  clinicalReview: {
    reviewedBy: {
      type: ObjectId,
      ref: "User",
    },
    reviewerName: {
      type: String,
    },
    reviewDate: {
      type: Date,
    },
    assessmentNotes: {
      type: String,
      trim: true,
    },
    decision: {
      type: String,
      enum: ["Eligible", "Not Eligible"],
    },
  },
  fulfillmentDetails: {
    fulfilledAt: {
      type: Date,
    },
    fulfilledBy: {
      type: ObjectId,
      ref: "User",
    },
    staffName: {
      type: String,
    },
    receiverName: {
      type: String,
      trim: true,
    },
  },
  allocatedBatches: [
    {
      invId: {
        type: ObjectId,
        ref: "Inventory",
      },
      batch: String,
      pool: String,
      bottleType: Number,
      bottlesAllocated: Number,
      volDischarge: Number,
      expiryDate: Date,
    }
  ],
  milklink: {
    ebm: [
      {
        invId: {
          type: ObjectId,
          ref: "Inventory",
        },
        bottleType: Number,
        batch: Number,
        pool: Number,
        bottle: {
          start: Number,
          end: Number,
        },
        volDischarge: Number,
      },
    ],
    transport: String,
    dispenseAt: Date,
    approvedBy: {
      type: ObjectId,
      ref: "User",
    },
    disapprovedBy: {
      type: ObjectId,
      ref: "User",
    },
  },
  history: [historyEntrySchema],
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
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

requestSchema.pre("save", async function () {
  if (!this.requestNumber) {
    const count = await this.constructor.countDocuments();
    const pad = String(count + 1).padStart(5, '0');
    this.requestNumber = `REQ-${new Date().getFullYear()}-${pad}`;
  }
});

requestSchema.index({ status: 1 });
requestSchema.index({ createdAt: -1 });
requestSchema.index({ requestedBy: 1 });
requestSchema.index({ requestNumber: 1 });

requestSchema.plugin(softDeletePlugin);
module.exports = mongoose.model("Request", requestSchema);
