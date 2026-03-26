// routes/milestoneRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  updateMilestoneProgress,
  addReminder,
  completeReminder,
  getCalendar
} from "../controllers/milestoneController.js";

const router = express.Router();

router.use(protect);

router.put("/progress", updateMilestoneProgress);
router.post("/reminder", addReminder);
router.put("/reminder/:contractId/:reminderId", completeReminder);
router.get("/calendar", getCalendar);

export default router;

