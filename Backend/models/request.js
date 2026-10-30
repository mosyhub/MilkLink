const mongoose = require("mongoose");
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete')
const requestSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: [true, "Please enter date"],
  },
  patient: {
    type: ObjectId,
    required: [true, "Please enter the patient"],
    ref: "Patient",
  },
  department: {
    type: String,
  },
  hospital: {
    type: String,
    default: "Taguig-Pateros District Hospital",
  },
  diagnosis: {
    type: String,
    required: [true, "Please enter diagnosis of the patient"],
  },
  reason: {
    type: String,
    required: [true, "Please enter reason for Byteurized EBM"],
  },
  doctor: {
    type: String,
    required: [true, "Please enter prescribing doctor"],
  },
  requestedBy: {
    type: ObjectId,
    required: [true, "Staff ID required"],
    ref: "User",
  },
  status: {
    type: String,
    enum: ["Pending", "Reserved", "Done", "Canceled"],
    default: "Pending",
  },
  comment: {
    type: String,
    default: "",
  },
  volumeRequested: {
    volume: {
      type: Number,
      required: [true, "Please enter Volume Requested"],
    },
    days: {
      type: Number,
      required: [true, "Please enter Volume Requested"],
    },
  },
  outcome: {
    type: String,
  },
  type: {
    type: String,
    enum: ["Inpatient", "Outpatient"],
  },
  tchmb: {
    ebm: [
      {
        invId: {
          type: ObjectId,
          ref: "Inventory",
          required: true
        },
        bottleType: Number,
        batch: Number,
        pool: Number,
        bottle: {
          start: Number,
          end: Number,
        },
        volDischarge: {
          type: Number,
        },
      },
    ],
    transport: {
      type: String,
    },
    dispenseAt: {
      type: Date,
    },
    approvedBy: {
      type: ObjectId,
      ref: "User",
    },
    disapprovedBy: {
      type: ObjectId,
      ref: "User",
    }
  },

  images: [
    {
      public_id: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

requestSchema.plugin(softDeletePlugin)
module.exports = mongoose.model("Request", requestSchema);
