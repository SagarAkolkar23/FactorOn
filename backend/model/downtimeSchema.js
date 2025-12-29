import mongoose from "mongoose";

const machineDowntimeSchema = new mongoose.Schema(
  {
    machine: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Machine",
      required: true,
    },

    startTime: {
      type: Date,
      required: true,
    },
    endTime: {
      type: Date,
    },

    reason: {
      categoryCode: {
        type: String, 
        required: true,
      },
      subReasonCode: {
        type: String, 
        required: true,
      },
    },

    photo: {
      url: String,
      publicId: String,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);

export default mongoose.model("MachineDowntime", machineDowntimeSchema);
