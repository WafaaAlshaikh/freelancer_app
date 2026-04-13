// backend/src/routes/subscriptionRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import CouponService from "../services/CouponService.js";
import {
  getPlans,
  getUserSubscription,
  createCheckoutSession,
  cancelSubscription,
  createSubscriptionPaymentIntent,
  confirmSubscriptionPayment,
  createSubscriptionCheckoutSession,
  manualConfirmSubscriptionPayment,
  confirmCheckoutSession,
} from "../controllers/subscriptionController.js";

const router = express.Router();

router.get("/plans", protect, getPlans);
router.get("/me", protect, getUserSubscription);
router.post("/checkout", protect, createCheckoutSession);
router.post("/cancel", protect, cancelSubscription);

router.post("/payment-intent", protect, createSubscriptionPaymentIntent);
router.post("/confirm-payment", protect, confirmSubscriptionPayment);
router.post("/checkout-session", protect, createSubscriptionCheckoutSession);
router.post("/manual-confirm", protect, manualConfirmSubscriptionPayment);
router.post("/confirm-checkout", protect, confirmCheckoutSession);

router.post("/validate-coupon", protect, async (req, res) => {
  try {
    const { code, planSlug, scope } = req.body;
    const context = scope === "contract" ? "contract" : "subscription";
    const result = await CouponService.validateCoupon(code, planSlug, context);
    res.json(result);
  } catch (error) {
    console.error("Error validating coupon:", error);
    res.status(500).json({ valid: false, message: "Server error" });
  }
});
export default router;
