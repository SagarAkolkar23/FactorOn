import express from "express";
import authenticate from "../middleware/authenticate.js";
import roleGuard from "../middleware/roleGuard.js";
import upload from "../middleware/multer.js";

import {
  startDowntime,
  stopDowntime,
  getDowntimes,
  getActiveDowntimeByMachine,
} from "../controller/machineDowntime.js";
import { getMachines } from "../controller/machines.js";

const router = express.Router();

router.post(
  "/start",
  authenticate,
  roleGuard(["operator"]),
  upload.single("photo"),
  startDowntime
);

router.put("/stop/:id", authenticate, roleGuard(["operator"]), stopDowntime);

router.get(
  "/get",
  authenticate,
  roleGuard(["supervisor", "operator"]),
  getDowntimes
);

router.get(
  "/active/:machineId",
  authenticate,
  roleGuard(["operator", "supervisor"]),
  getActiveDowntimeByMachine
);

export default router;
