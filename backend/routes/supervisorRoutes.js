import express from "express";
import authenticate from "../middleware/authenticate.js";
import roleGuard from "../middleware/roleGuard.js";
import {
  getDashboardStats,
  getAllDowntimes,
  getDowntimeStatsByMachine,
  downloadDowntimeReport,
} from "../controller/supervisorController.js";

const router = express.Router();

// All routes require authentication and supervisor role
router.use(authenticate);
router.use(roleGuard(["supervisor"]));

router.get("/dashboard/stats", getDashboardStats);

router.get("/downtimes", getAllDowntimes);

router.get("/downtimes/stats-by-machine", getDowntimeStatsByMachine);

router.get("/downtimes/report", downloadDowntimeReport);

export default router;

