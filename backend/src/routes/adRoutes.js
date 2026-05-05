import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getActiveAds,
  trackAdClick,
  getMyCampaigns,
  createCampaign,
  activateCampaign,
  pauseCampaign,
  getAdAnalytics,
  getAdvertiserStats,
  createPaymentSession,
  payWithWallet,
  recordManualPayment,
  getPaymentStatus,
  getAdRevenueStats,
  adminGetAllCampaigns,
  adminGetCampaignDetails,
  adminUpdateCampaign,
  adminChangeCampaignStatus,
  adminDeleteCampaign,
  adminGetAdAnalytics,
  adminGetPaymentTransactions,
} from "../controllers/adController.js";

const router = express.Router();

router.get("/active", getActiveAds);
router.post("/:campaignId/click", trackAdClick);

router.use(protect);
router.get("/my-campaigns", authorizeRoles("client", "admin"), getMyCampaigns);
router.post("/campaigns", authorizeRoles("client", "admin"), createCampaign);
router.put(
  "/:campaignId/activate",
  authorizeRoles("client", "admin"),
  activateCampaign,
);
router.put(
  "/:campaignId/pause",
  authorizeRoles("client", "admin"),
  pauseCampaign,
);
router.get("/analytics", authorizeRoles("client", "admin"), getAdAnalytics);
router.get("/my-stats", authorizeRoles("client", "admin"), getAdvertiserStats);

router.get("/admin/all", authorizeRoles("admin"), async (req, res) => {
  const campaigns = await AdCampaign.findAll({ include: ["advertiser"] });
  res.json({ success: true, campaigns });
});

router.post(
  "/:campaignId/create-payment",
  protect,
  authorizeRoles("client", "admin"),
  createPaymentSession,
);
router.post(
  "/:campaignId/pay-with-wallet",
  protect,
  authorizeRoles("client", "admin"),
  payWithWallet,
);
router.get("/:campaignId/payment-status", protect, getPaymentStatus);

router.get(
  "/admin/revenue-stats",
  protect,
  authorizeRoles("admin"),
  getAdRevenueStats,
);
router.post(
  "/admin/:campaignId/record-payment",
  protect,
  authorizeRoles("admin"),
  recordManualPayment,
);

router.post(
  "/webhook/stripe",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
      await AdPaymentService.handleWebhook(event);
      res.json({ received: true });
    } catch (err) {
      console.error("Webhook error:", err);
      res.status(400).send(`Webhook Error: ${err.message}`);
    }
  },
);

router.get(
  "/admin/campaigns",
  protect,
  authorizeRoles("admin"),
  adminGetAllCampaigns,
);

router.get(
  "/admin/campaigns/:campaignId",
  protect,
  authorizeRoles("admin"),
  adminGetCampaignDetails,
);

router.put(
  "/admin/campaigns/:campampaignId",
  protect,
  authorizeRoles("admin"),
  adminUpdateCampaign,
);

router.patch(
  "/admin/campaigns/:campaignId/status",
  protect,
  authorizeRoles("admin"),
  adminChangeCampaignStatus,
);

router.delete(
  "/admin/campaigns/:campaignId",
  protect,
  authorizeRoles("admin"),
  adminDeleteCampaign,
);

router.get(
  "/admin/analytics",
  protect,
  authorizeRoles("admin"),
  adminGetAdAnalytics,
);

router.get(
  "/admin/payments",
  protect,
  authorizeRoles("admin"),
  adminGetPaymentTransactions,
);

export default router;
