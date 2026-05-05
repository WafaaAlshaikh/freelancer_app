// routes/dashboardRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardOverview,
  getProjectsSummary,
} from "../controllers/dashboardController.js";

const router = express.Router();

router.use(protect);

router.get(
  "/overview",
  authorizeRoles("client", "admin"),
  getDashboardOverview,
);
router.get(
  "/projects-summary",
  authorizeRoles("client", "admin"),
  getProjectsSummary,
);

export default router;
