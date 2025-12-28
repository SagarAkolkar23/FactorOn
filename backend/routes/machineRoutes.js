import express from "express";
import authenticate from "../middleware/authenticate.js";
import roleGuard from "../middleware/roleGuard.js";

import {
  addMachine,
  getMachines,
  updateMachine,
  deleteMachine,
} from "../controller/machines.js";

const router = express.Router();

router.post("/add", authenticate, roleGuard(["operator"]), addMachine);

router.put("/update/:id", authenticate, roleGuard(["operator"]), updateMachine);

router.delete("/delete/:id", authenticate, roleGuard(["operator"]), deleteMachine);

router.get("/get", authenticate, getMachines);

export default router;
