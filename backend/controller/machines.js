import Machine from "../model/machineSchema.js";

export const addMachine = async (req, res, next) => {
  try {
    const { machineId, name, type, status, details, maintenance } = req.body;

    if (!machineId || !name || !type) {
      return res.status(400).json({
        success: false,
        message: "machineId, name and type are required",
      });
    }

    const exists = await Machine.findOne({ machineId });
    if (exists) {
      return res.status(409).json({
        success: false,
        message: "Machine already exists",
      });
    }

    const machine = await Machine.create({
      machineId,
      name,
      type,
      status,
      details,

      maintenance: maintenance?.lastMaintenance
        ? {
            lastMaintenance: new Date(maintenance.lastMaintenance),
            notes: maintenance.notes,
          }
        : undefined,

      createdBy: req.user.id,
    });

    res.status(201).json({
      success: true,
      machine,
    });
  } catch (error) {
    next(error);
  }
};

export const getMachines = async (req, res, next) => {
  try {
    const machines = await Machine.find().sort({ createdAt: -1 }).lean();

    res.status(200).json({
      success: true,
      machines,
    });
  } catch (error) {
    next(error);
  }
};

export const updateMachine = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { maintenance, ...rest } = req.body;

    const updateData = { ...rest };

    if (maintenance?.lastMaintenance) {
      updateData.maintenance = {
        lastMaintenance: new Date(maintenance.lastMaintenance),
        notes: maintenance.notes,
      };
    }

    const machine = await Machine.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!machine) {
      return res.status(404).json({
        success: false,
        message: "Machine not found",
      });
    }

    res.status(200).json({
      success: true,
      machine,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteMachine = async (req, res, next) => {
  try {
    const { id } = req.params;

    const machine = await Machine.findByIdAndDelete(id);

    if (!machine) {
      return res.status(404).json({
        success: false,
        message: "Machine not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Machine deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};
