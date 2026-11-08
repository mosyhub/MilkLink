const mongoose = require("mongoose");
const { ObjectId } = mongoose.Schema.Types;
const softDeletePlugin = require('./plugins/softDelete');

const inventorySchema = new mongoose.Schema({
  fridge: {
    type: ObjectId,
    ref: "Fridge",
    required: [true, "A fridge must be associated with this inventory item"],
  },
  inventoryDate: {
    type: Date,
    default: Date.now,
  },
  user: {
    type: ObjectId,
    ref: "User",
  },
  status: {
    type: String,
    enum: ["Unavailable", "Pending", "Available", "Reserved", "Depleted"],
    default: "Available",
    required: true,
  },
  // Unified fields for simple entry & batch representation
  donorName: {
    type: String,
    default: '',
    trim: true,
  },
  donorNames: [
    {
      type: String,
      trim: true,
    }
  ],
  volume: {
    type: Number,
    default: 0, // integer in ml
  },
  expiration: {
    type: Date,
  },
  batchNumber: {
    type: Number,
  },
  poolNumber: {
    type: Number,
  },
  bottleType: {
    type: Number, // e.g. 100, 200 ml
  },
  availableBottles: {
    type: Number,
    default: 0,
  },
  isPasteurized: {
    type: Boolean,
    default: false,
  },
  isRequested: {
    type: Boolean,
    default: false,
  },
  sourceEntries: [
    {
      type: ObjectId,
      ref: 'Inventory',
    }
  ],
  reasonForChange: {
    type: String,
    default: '',
  },

  // Legacy & subdocument details for compatibility
  pasteurizedDetails: {
    pasteurizationDate: {
      type: Date,
    },
    batch: {
      type: Number,
    },
    pool: {
      type: Number,
    },
    bottles: [
      {
        bottleNumber: {
          type: Number,
        }, 
        status: {
          type: String,
          enum: ["Available", "Reserved", "Dispensed"],
          default: "Available",
        },
      },
    ],
    bottleType: {
      type: Number,
    },
    batchVolume: {
      type: Number,
    },
    expiration: {
      type: Date,
    },
    donors: [
      {
        type: ObjectId,
        ref: "Donor",
      },
    ],
  },
  unpasteurizedDetails: {
    collectionId: {
      type: ObjectId,
      ref: "Collection",
    },
    expressDateStart: {
      type: Date,
    },
    expressDateEnd: {
      type: Date,
    },
    expiration: {
      type: Date,
    },
  },
});

// Sync top-level fields with nested details before saving
inventorySchema.pre("save", function () {
  if (this.unpasteurizedDetails) {
    if (!this.expiration && this.unpasteurizedDetails.expiration) {
      this.expiration = this.unpasteurizedDetails.expiration;
    }
  }
  if (this.pasteurizedDetails) {
    if (!this.expiration && this.pasteurizedDetails.expiration) {
      this.expiration = this.pasteurizedDetails.expiration;
    }
    if (!this.batchNumber && this.pasteurizedDetails.batch) {
      this.batchNumber = this.pasteurizedDetails.batch;
    }
    if (!this.poolNumber && this.pasteurizedDetails.pool) {
      this.poolNumber = this.pasteurizedDetails.pool;
    }
    if (!this.bottleType && this.pasteurizedDetails.bottleType) {
      this.bottleType = this.pasteurizedDetails.bottleType;
    }
    if (this.availableBottles === 0 && Array.isArray(this.pasteurizedDetails.bottles)) {
      this.availableBottles = this.pasteurizedDetails.bottles.filter(b => b.status === 'Available').length;
    }
  }
});

inventorySchema.plugin(softDeletePlugin);
module.exports = mongoose.model("Inventory", inventorySchema);
