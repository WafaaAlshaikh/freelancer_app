// backend/src/routes/adminAnalyticsRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getTopPerformers,
  getPredictiveAnalytics,
  getActiveInsights,
  resolveInsight,
  getAuditLogs,
  getAdvancedStats,
  getUserSatisfaction,
} from "../controllers/adminAnalyticsController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("admin"));

router.get("/top-performers", getTopPerformers);
router.get("/predictive", getPredictiveAnalytics);
router.get("/insights", getActiveInsights);
router.post("/insights/:insightId/resolve", resolveInsight);
router.get("/audit-logs", getAuditLogs);
router.get("/advanced-stats", getAdvancedStats);
router.get("/satisfaction", getUserSatisfaction);

export default router;