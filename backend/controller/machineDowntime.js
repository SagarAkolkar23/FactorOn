import MachineDowntime from "../model/downtimeSchema.js";
import cloudinary from "../config/cloudinary.js";
import { notifySupervisors } from "../middleware/notificationService.js";
import Machine from "../model/machineSchema.js";
import fs from "fs-extra";

export const startDowntime = async (req, res, next) => {
  console.log("🟡 [START DOWNTIME] Request received");

  try {
    const { machineId, startTime, reason } = req.body;

    console.log("➡️ Payload:", {
      machineId,
      startTime,
      reason,
      hasPhoto: !!req.file,
      user: req.user?.id,
    });

    if (
      !machineId ||
      !startTime ||
      !reason?.categoryCode ||
      !reason?.subReasonCode
    ) {
      console.log("❌ Validation failed: missing fields");
      return res.status(400).json({
        success: false,
        message: "Required fields missing",
      });
    }

    const machine = await Machine.findById(machineId);
    if (!machine) {
      console.log(`❌ Machine not found: ${machineId}`);
      return res.status(404).json({
        success: false,
        message: "Machine not found",
      });
    }

    console.log(`✅ Machine found: ${machine.machineId}`);

    const activeDowntime = await MachineDowntime.findOne({
      machine: machineId,
      isActive: true,
    });

    if (activeDowntime) {
      console.log(
        `⚠️ Active downtime already exists for machine ${machine.machineId}`
      );
      return res.status(409).json({
        success: false,
        message: "Machine already in downtime",
      });
    }

    let uploadedPhoto;

    if (req.file) {
      console.log(`📸 Uploading photo to Cloudinary (${req.file.size} bytes)`);

      try {
        const result = await cloudinary.uploader.upload(req.file.path, {
          folder: "machine-downtime",
          resource_type: "image",
        });

        uploadedPhoto = {
          url: result.secure_url,
          publicId: result.public_id,
        };

        console.log("☁️ Cloudinary upload success:", uploadedPhoto.publicId);
      } catch (uploadError) {
        console.error("❌ Cloudinary upload failed:", uploadError);
        // Clean up temp file even if upload fails
        try {
          await fs.remove(req.file.path);
        } catch (cleanupError) {
          console.error("⚠️ Failed to remove temp file:", cleanupError);
        }
        return res.status(500).json({
          success: false,
          message: "Failed to upload image",
        });
      }

      // Clean up temp file after successful upload
      try {
        await fs.remove(req.file.path);
        console.log("🧹 Temp file removed");
      } catch (cleanupError) {
        console.error("⚠️ Failed to remove temp file:", cleanupError);
        // Continue execution even if cleanup fails
      }
    }

    const downtime = await MachineDowntime.create({
      machine: machineId,
      startTime: new Date(startTime),
      reason,
      photo: uploadedPhoto,
      createdBy: req.user.id,
    });

    console.log(`📝 Downtime created: ${downtime._id}`);

    machine.status = "OFF";
    await machine.save();

    console.log(`🔴 Machine ${machine.machineId} status set to OFF`);

    await notifySupervisors({
      title: "🚨 Downtime Started",
      body: `Machine ${machine.machineId} is down (${reason.categoryCode})`,
      data: {
        downtimeId: downtime._id.toString(),
        machineId: machine._id.toString(),
        status: "OFF",
      },
    });

    console.log("🔔 Supervisor notification sent (START)");

    res.status(201).json({
      success: true,
      downtime,
    });
  } catch (error) {
    console.error("🔥 START DOWNTIME ERROR:", error);
    next(error);
  }
};

export const stopDowntime = async (req, res, next) => {
  console.log("🟡 [STOP DOWNTIME] Request received");

  try {
    const { id } = req.params;
    const { endTime } = req.body;

    console.log("➡️ Payload:", { downtimeId: id, endTime });

    const downtime = await MachineDowntime.findById(id).populate(
      "machine",
      "machineId status"
    );

    if (!downtime || !downtime.isActive) {
      console.log("❌ Active downtime not found:", id);
      return res.status(404).json({
        success: false,
        message: "Active downtime not found",
      });
    }

    downtime.endTime = new Date(endTime);
    downtime.isActive = false;
    await downtime.save();

    console.log(`⏹️ Downtime stopped: ${downtime._id}`);

    const machine = await Machine.findById(downtime.machine._id);
    if (!machine) {
      console.log("❌ Machine not found after downtime stop");
      return res.status(404).json({
        success: false,
        message: "Machine not found",
      });
    }
    machine.status = "RUN";
    await machine.save();

    console.log(`🟢 Machine ${machine.machineId} status set to RUN`);

    await notifySupervisors({
      title: "✅ Downtime Resolved",
      body: `Machine ${machine.machineId} is back online`,
      data: {
        downtimeId: downtime._id.toString(),
        machineId: machine._id.toString(),
        status: "RUN",
      },
    });

    console.log("🔔 Supervisor notification sent (STOP)");

    res.status(200).json({
      success: true,
      downtime,
    });
  } catch (error) {
    console.error("🔥 STOP DOWNTIME ERROR:", error);
    next(error);
  }
};

export const getDowntimes = async (req, res, next) => {
  console.log("🟡 [GET DOWNTIMES] Request received");

  try {
    const downtimes = await MachineDowntime.find()
      .populate("machine", "machineId name")
      .sort({ createdAt: -1 });

    console.log(`📊 Downtimes fetched: ${downtimes.length}`);

    res.status(200).json({
      success: true,
      downtimes,
    });
  } catch (error) {
    console.error("🔥 GET DOWNTIMES ERROR:", error);
    next(error);
  }
};


// GET /downtime/active/:machineId
export const getActiveDowntimeByMachine = async (req, res, next) => {
  try {
    const { machineId } = req.params;

    const downtime = await MachineDowntime.findOne({
      machine: machineId,
      isActive: true,
    });

    res.json({
      success: true,
      downtime,
    });
  } catch (error) {
    console.error("🔥 GET ACTIVE DOWNTIME ERROR:", error);
    next(error);
  }
};
