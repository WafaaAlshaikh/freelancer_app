import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getSubscriptionStats,
  getAllPlansAdmin,
  createPlan,
  updatePlan,
  deletePlan,
  getAllCoupons,
  createCoupon,
  updateCoupon,
  deleteCoupon,
} from "../controllers/adminSubscriptionController.js";

const router = express.Router();

router.use(protect, authorizeRoles("admin"));

router.get("/stats", getSubscriptionStats);

router.get("/plans", getAllPlansAdmin);
router.post("/plans", createPlan);
router.put("/plans/:id", updatePlan);
router.delete("/plans/:id", deletePlan);

router.get("/coupons", getAllCoupons);
router.post("/coupons", createCoupon);
router.put("/coupons/:id", updateCoupon);
router.delete("/coupons/:id", deleteCoupon);

export default router;
