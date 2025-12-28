import mongoose from "mongoose";

const machineSchema = new mongoose.Schema(
  {
    machineId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    type: {
      type: String,
      required: true,
      trim: true,
    },

    status: {
      type: String,
      enum: ["RUN", "IDLE", "OFF"],
      default: "RUN",
    },

    details: {
      type: Object,
      default: {},
    },

    maintenance: {
      lastMaintenance: {
        type: Date,
      },
      notes: {
        type: String,
        trim: true,
      },
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);

const Machine =
  mongoose.models.Machine || mongoose.model("Machine", machineSchema);

export default Machine;
