// routes/dashboardRoutes.js  — أضف هاد الملف للـ backend
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardOverview,
  getProjectsSummary,
} from "../controllers/dashboardController.js";

const router = express.Router();

router.use(protect, authorizeRoles("client"));
router.get("/overview", getDashboardOverview);
router.get("/projects-summary", getProjectsSummary);

export default router;