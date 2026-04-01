// backend/src/routes/skillTestRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getAvailableTests,
  getTest,
  startTest,
  submitTest,
  getUserTestResults,
  getUserTestStats,
  createTest,
} from "../controllers/skillTestController.js";

const router = express.Router();

// جميع المسارات تتطلب توثيق ودور freelancer
router.use(protect);
router.use(authorizeRoles("freelancer"));

router.get("/available", getAvailableTests);
router.get("/results", getUserTestResults);
router.get("/stats", getUserTestStats);
router.get("/:testId", getTest);
router.post("/:testId/start", startTest);
router.post("/submit/:userTestId", submitTest);

// مسار للمشرفين فقط
router.post("/create", authorizeRoles("admin"), createTest);

export default router;