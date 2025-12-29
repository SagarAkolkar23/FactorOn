import MachineDowntime from "../model/downtimeSchema.js";
import Machine from "../model/machineSchema.js";

// Get dashboard statistics for supervisor
export const getDashboardStats = async (req, res, next) => {
  try {
    // Get total machines
    const totalMachines = await Machine.countDocuments();

    // Get active downtimes count
    const activeDowntimesCount = await MachineDowntime.countDocuments({
      isActive: true,
    });

    // Get total downtimes today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayDowntimes = await MachineDowntime.countDocuments({
      createdAt: { $gte: today },
    });

    // Get machines by status
    const machinesByStatus = await Machine.aggregate([
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);

    const statusMap = {
      RUN: 0,
      IDLE: 0,
      OFF: 0,
    };

    machinesByStatus.forEach((item) => {
      statusMap[item._id] = item.count;
    });

    // Get recent downtimes (last 10)
    const recentDowntimes = await MachineDowntime.find()
      .populate("machine", "machineId name type status")
      .populate("createdBy", "email")
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();

    // Get active downtimes with details
    const activeDowntimes = await MachineDowntime.find({ isActive: true })
      .populate("machine", "machineId name type status")
      .populate("createdBy", "email")
      .sort({ startTime: -1 })
      .lean();

    // Calculate total downtime duration today
    const downtimesToday = await MachineDowntime.find({
      createdAt: { $gte: today },
      isActive: false,
    }).lean();

    let totalDowntimeMinutes = 0;
    downtimesToday.forEach((dt) => {
      if (dt.startTime && dt.endTime) {
        const duration = new Date(dt.endTime) - new Date(dt.startTime);
        totalDowntimeMinutes += Math.floor(duration / (1000 * 60));
      }
    });

    res.status(200).json({
      success: true,
      stats: {
        totalMachines,
        activeDowntimes: activeDowntimesCount,
        todayDowntimes,
        machinesByStatus: statusMap,
        totalDowntimeMinutesToday: totalDowntimeMinutes,
      },
      activeDowntimes,
      recentDowntimes,
    });
  } catch (error) {
    console.error("🔥 GET DASHBOARD STATS ERROR:", error);
    next(error);
  }
};

// Get all downtimes with filters
export const getAllDowntimes = async (req, res, next) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      machineId, 
      isActive, 
      startDate, 
      endDate 
    } = req.query;

    const query = {};

    // Filter by machine
    if (machineId) {
      query.machine = machineId;
    }

    // Filter by active status
    if (isActive !== undefined) {
      query.isActive = isActive === "true";
    }

    // Filter by date range
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate);
      }
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const downtimes = await MachineDowntime.find(query)
      .populate("machine", "machineId name type status")
      .populate("createdBy", "email")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await MachineDowntime.countDocuments(query);

    res.status(200).json({
      success: true,
      downtimes,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error("🔥 GET ALL DOWNTIMES ERROR:", error);
    next(error);
  }
};

// Get downtime statistics by machine
export const getDowntimeStatsByMachine = async (req, res, next) => {
  try {
    const stats = await MachineDowntime.aggregate([
      {
        $match: { isActive: false }, // Only completed downtimes
      },
      {
        $group: {
          _id: "$machine",
          totalDowntimes: { $sum: 1 },
          totalDuration: {
            $sum: {
              $subtract: ["$endTime", "$startTime"],
            },
          },
          avgDuration: {
            $avg: {
              $subtract: ["$endTime", "$startTime"],
            },
          },
        },
      },
      {
        $lookup: {
          from: "machines",
          localField: "_id",
          foreignField: "_id",
          as: "machineInfo",
        },
      },
      {
        $unwind: "$machineInfo",
      },
      {
        $project: {
          machineId: "$machineInfo.machineId",
          machineName: "$machineInfo.name",
          machineType: "$machineInfo.type",
          totalDowntimes: 1,
          totalDurationMinutes: {
            $divide: ["$totalDuration", 1000 * 60],
          },
          avgDurationMinutes: {
            $divide: ["$avgDuration", 1000 * 60],
          },
        },
      },
      {
        $sort: { totalDowntimes: -1 },
      },
    ]);

    res.status(200).json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error("🔥 GET DOWNTIME STATS BY MACHINE ERROR:", error);
    next(error);
  }
};

// Download complete downtime report as CSV
export const downloadDowntimeReport = async (req, res, next) => {
  try {
    const { 
      machineId, 
      isActive, 
      startDate, 
      endDate 
    } = req.query;

    const query = {};

    // Filter by machine
    if (machineId) {
      query.machine = machineId;
    }

    // Filter by active status
    if (isActive !== undefined) {
      query.isActive = isActive === "true";
    }

    // Filter by date range
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate);
      }
    }

    // Get all downtimes (no pagination for report)
    const downtimes = await MachineDowntime.find(query)
      .populate("machine", "machineId name type status")
      .populate("createdBy", "email")
      .sort({ createdAt: -1 })
      .lean();

    // Generate CSV content
    const csvHeaders = [
      "Downtime ID",
      "Machine ID",
      "Machine Name",
      "Machine Type",
      "Status",
      "Start Time",
      "End Time",
      "Duration (Minutes)",
      "Duration (Formatted)",
      "Category Code",
      "Sub Reason Code",
      "Created By",
      "Created At",
      "Photo URL",
    ];

    const csvRows = downtimes.map((dt) => {
      const startTime = new Date(dt.startTime).toISOString();
      const endTime = dt.endTime ? new Date(dt.endTime).toISOString() : "N/A";
      const createdAt = dt.createdAt ? new Date(dt.createdAt).toISOString() : "N/A";
      
      let durationMinutes = "N/A";
      let durationFormatted = "N/A";
      
      if (dt.startTime && dt.endTime) {
        const durationMs = new Date(dt.endTime) - new Date(dt.startTime);
        durationMinutes = Math.floor(durationMs / (1000 * 60));
        const hours = Math.floor(durationMinutes / 60);
        const minutes = durationMinutes % 60;
        durationFormatted = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
      } else if (dt.startTime && dt.isActive) {
        const durationMs = Date.now() - new Date(dt.startTime);
        durationMinutes = Math.floor(durationMs / (1000 * 60));
        const hours = Math.floor(durationMinutes / 60);
        const minutes = durationMinutes % 60;
        durationFormatted = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
      }

      return [
        dt._id.toString(),
        dt.machine?.machineId || "N/A",
        dt.machine?.name || "N/A",
        dt.machine?.type || "N/A",
        dt.isActive ? "Active" : "Completed",
        startTime,
        endTime,
        durationMinutes,
        durationFormatted,
        dt.reason?.categoryCode || "N/A",
        dt.reason?.subReasonCode || "N/A",
        dt.createdBy?.email || "N/A",
        createdAt,
        dt.photo?.url || "N/A",
      ];
    });

    // Escape CSV values (handle commas and quotes)
    const escapeCsvValue = (value) => {
      if (value === null || value === undefined) return "";
      const stringValue = String(value);
      if (stringValue.includes(",") || stringValue.includes('"') || stringValue.includes("\n")) {
        return `"${stringValue.replace(/"/g, '""')}"`;
      }
      return stringValue;
    };

    // Build CSV content
    const csvContent = [
      csvHeaders.map(escapeCsvValue).join(","),
      ...csvRows.map((row) => row.map(escapeCsvValue).join(",")),
    ].join("\n");

    // Generate filename with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, -5);
    const filename = `downtime-report-${timestamp}.csv`;

    // Set headers for CSV download
    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.setHeader("Content-Length", Buffer.byteLength(csvContent, "utf8"));

    res.status(200).send(csvContent);
  } catch (error) {
    console.error("🔥 DOWNLOAD DOWNTIME REPORT ERROR:", error);
    next(error);
  }
};

