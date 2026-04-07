// ===== backend/src/routes/advancedSearchRoutes.js =====
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  advancedProjectSearch,
  saveSearchFilter,
  getSavedFilters,
  deleteSavedFilter,
  createProjectAlert,
  getUserAlerts,
  deleteAlert,
  toggleAlert,
} from "../controllers/advancedSearchController.js";

const router = express.Router();

router.use(protect);

router.get("/projects", advancedProjectSearch);

router.post("/filters", saveSearchFilter);
router.get("/filters", getSavedFilters);
router.delete("/filters/:filterId", deleteSavedFilter);

router.post("/alerts", createProjectAlert);
router.get("/alerts", getUserAlerts);
router.delete("/alerts/:alertId", deleteAlert);
router.patch("/alerts/:alertId/toggle", toggleAlert);

export default router;