// ===== backend/src/routes/financialRoutes.js =====
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  getFinancialStats,
  generateFinancialReport,
  requestWithdrawalV2,
  getAdvancedFinancialAnalytics,
} from "../controllers/financialController.js";

const router = express.Router();

router.use(protect);

router.get("/stats", getFinancialStats);
router.get("/report", generateFinancialReport);
router.post("/withdraw", requestWithdrawalV2);
router.get("/analytics", getAdvancedFinancialAnalytics);

export default router;