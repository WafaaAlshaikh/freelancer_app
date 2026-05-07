// server.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import fs from "fs";
import Stripe from "stripe";
import http from "http";
import { sequelize } from "./src/config/db.js";
import authRoutes from "./src/routes/authRoutes.js";
import freelancerRoutes from "./src/routes/freelancerRoutes.js";
import projectRoutes from "./src/routes/projectRoutes.js";
import proposalRoutes from "./src/routes/proposalRoutes.js";
import clientRoutes from "./src/routes/clientRoutes.js";
import aiRoutes from "./src/routes/aiRoutes.js";
import contractRoutes from "./src/routes/contractRoutes.js";
import ratingRoutes from "./src/routes/ratingRoutes.js";
import milestoneRoutes from "./src/routes/milestoneRoutes.js";
import githubRoutes from "./src/routes/githubRoutes.js";
import notificationRoutes from "./src/routes/notificationRoutes.js";
import chatRoutes from "./src/routes/chatRoutes.js";
import NotificationService from "./src/services/notificationService.js";
import PaymentService from "./src/services/paymentService.js";
import stripeWebhookRoutes from "./src/routes/stripeWebhookRoutes.js";
import { initSocket } from "./src/socket/socketManager.js";
import dashboardRoutes from "./src/routes/dashboardRoutes.js";
import profileRoutes from "./src/routes/profileRoutes.js";
import adminRoutes from "./src/routes/adminRoutes.js";
import landingRoutes from "./src/routes/landingRoutes.js";
import adminLandingRoutes from "./src/routes/adminLandingRoutes.js";
import { protect, authorizeRoles } from "./src/middleware/authMiddleware.js";
import skillTestRoutes from "./src/routes/skillTestRoutes.js";
import subscriptionRoutes from "./src/routes/subscriptionRoutes.js";
import featureRoutes from "./src/routes/featureRoutes.js";
import { User } from "./src/models/index.js";
import SubscriptionService from "./src/services/subscriptionService.js";
import subscriptionDevRoutes from "./src/routes/subscriptionDevRoutes.js";
import invoiceRoutes from "./src/routes/invoiceRoutes.js";
import adminSubscriptionRoutes from "./src/routes/adminSubscriptionRoutes.js";
import CronService from "./src/services/CronService.js";
import favoriteRoutes from "./src/routes/favoriteRoutes.js";
import workSubmissionRoutes from "./src/routes/workSubmissionRoutes.js";
import financialRoutes from "./src/routes/financialRoutes.js";
import advancedSearchRoutes from "./src/routes/advancedSearchRoutes.js";
import interviewRoutes from "./src/routes/interviewRoutes.js";
import { initWebSocket } from "./src/services/websocketService.js";
import SmartReminderService from "./src/services/smartReminderService.js";
import clientSearchRoutes from "./src/routes/clientSearchRoutes.js";
import AdRoutes from "./src/routes/adRoutes.js";
import disputeRoutes from "./src/routes/disputeRoutes.js";

dotenv.config();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
console.log(
  "✅ Stripe initialized with key:",
  process.env.STRIPE_SECRET_KEY ? "Present" : "Missing",
);

const app = express();

// ==================== MIDDLEWARE ====================
app.use(
  cors({
    origin: "*",
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "X-Requested-With",
      "Accept",
    ],
  }),
);

app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.url}`);
  next();
});

app.use("/api/stripe", stripeWebhookRoutes);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ==================== CREATE HTTP SERVER ====================
const server = http.createServer(app);

const io = initWebSocket(server);
app.set("io", io);

const chatIo = initSocket(server);

SmartReminderService.init();

const uploadDirs = [
  "uploads/cvs",
  "uploads/avatars",
  "uploads/portfolio",
  "uploads/chats",
  "uploads/covers",
  "uploads/logos",
  "uploads/temp",
];
uploadDirs.forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

app.use("/uploads", express.static("uploads"));

app.get("/", (req, res) => res.send("API is running..."));

// ==================== API ROUTES ====================
app.use("/api/auth", authRoutes);
app.use("/api/freelancer", freelancerRoutes);
app.use("/api/projects", projectRoutes);
app.use("/api/proposals", proposalRoutes);
app.use("/api/client", clientRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/contracts", contractRoutes);
app.use("/api/ratings", ratingRoutes);
app.use("/api/milestones", milestoneRoutes);
app.use("/api/github", githubRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/client/dashboard", dashboardRoutes);
app.use("/api/profiles", profileRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/landing", landingRoutes);
app.use("/api/skill-tests", skillTestRoutes);
app.use("/api/subscription", subscriptionRoutes);
app.use("/api/features", featureRoutes);
app.use("/api/subscription-dev", subscriptionDevRoutes);
app.use("/api/admin/subscription", adminSubscriptionRoutes);
app.use("/api/invoices", invoiceRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/work-submissions", workSubmissionRoutes);
app.use("/api/financial", financialRoutes);
app.use("/api/search", advancedSearchRoutes);
app.use("/api/interviews", interviewRoutes);
app.use("/api/client/search", clientSearchRoutes);
app.use("/api/ads", AdRoutes);
app.use("/api/disputes", disputeRoutes);
app.use(
  "/api/admin/landing",
  protect,
  authorizeRoles("admin"),
  adminLandingRoutes,
);

// ==================== USER USAGE API ====================
app.get("/api/user/usage", protect, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    const subscription = await SubscriptionService.getUserSubscription(
      req.user.id,
    );

    let interviewBlock = {};
    if (req.user.role === "client") {
      const iu = await SubscriptionService.getClientInterviewUsage(req.user.id);
      interviewBlock = {
        interviews_used: iu.interviews_used,
        interviews_limit: iu.interviews_limit,
        interviews_remaining: iu.remaining,
      };
    }

    res.json({
      success: true,
      usage: {
        proposals_used: user.proposal_count_this_month || 0,
        proposals_limit: subscription.plan.proposal_limit,
        active_projects_used: user.active_projects_count || 0,
        active_projects_limit: subscription.plan.active_project_limit,
        plan_slug: subscription.plan?.slug,
        plan_name: subscription.plan?.name,
        ...interviewBlock,
      },
    });
  } catch (error) {
    console.error("Error getting user usage:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ==================== PAYMENT REDIRECTS ====================
app.get("/payment-success", (req, res) => {
  const { session_id, contract_id } = req.query;
  res.redirect(
    `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=success`,
  );
});

app.get("/payment-cancel", (req, res) => {
  const { contract_id } = req.query;
  res.redirect(
    `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=cancelled`,
  );
});

// ==================== FLUTTER WEB ROUTING SUPPORT ====================
app.get("/api/subscription/success", (req, res) => {
  const queryString = new URLSearchParams(req.query).toString();
  const redirectUrl = `${process.env.FRONTEND_URL}/subscription_success${queryString ? "?" + queryString : ""}`;
  console.log("🔄 Stripe success -> Flutter:", redirectUrl);
  res.redirect(redirectUrl);
});

app.get("/api/subscription/cancel", (req, res) => {
  const redirectUrl = `${process.env.FRONTEND_URL}/subscription_cancel`;
  console.log("🔄 Stripe cancel -> Flutter:", redirectUrl);
  res.redirect(redirectUrl);
});

app.get("/api/subscription/my", (req, res) => {
  const queryString = new URLSearchParams(req.query).toString();
  const redirectUrl = `${process.env.FRONTEND_URL}/#/subscription/my${queryString ? "?" + queryString : ""}`;
  console.log("🔄 Redirecting to Flutter:", redirectUrl);
  res.redirect(redirectUrl);
});

app.get("/api/subscription/success-old", (req, res) => {
  const queryString = new URLSearchParams(req.query).toString();
  const redirectUrl = `${process.env.FRONTEND_URL}/#/subscription/success${queryString ? "?" + queryString : ""}`;
  console.log("🔄 Stripe success (old) -> Flutter:", redirectUrl);
  res.redirect(redirectUrl);
});

app.use("/api/subscription", (req, res, next) => {
  if (
    req.method === "GET" &&
    !req.path.includes("checkout") &&
    !req.path.includes("confirm")
  ) {
    const redirectUrl = `${process.env.FRONTEND_URL}/#${req.originalUrl}`;
    console.log("🔄 Any subscription route -> Flutter:", redirectUrl);
    res.redirect(redirectUrl);
  } else {
    next();
  }
});

// ==================== ERROR HANDLERS ====================
app.use((req, res) => {
  console.log(`❌ 404 - Route not found: ${req.method} ${req.url}`);
  res.status(404).json({ message: `Cannot ${req.method} ${req.path}` });
});

app.use((err, req, res, next) => {
  console.error("❌ Unhandled error:", err);
  res.status(500).json({ message: err.message || "Internal server error" });
});
import listEndpoints from "express-list-routes";

// ==================== START SERVER ====================
const PORT = process.env.PORT || 5001;
listEndpoints(app);

async function startServer() {
  try {
    await sequelize.sync({ alter: false });
    console.log("✅ Tables synced with database");

    CronService.initialize();

    server.listen(PORT, () => {
      console.log(`\n🚀 Server running on port ${PORT}`);
      console.log(`🔌 WebSocket (Interview) enabled`);
      console.log(`💬 Socket.io (Chat) enabled`);
      console.log(`⏰ Smart Reminder Service enabled`);
      console.log(`📡 Frontend URL: ${process.env.FRONTEND_URL}`);
      console.log(
        `💳 Stripe: ${process.env.STRIPE_SECRET_KEY ? "Configured" : "Missing"}`,
      );
      console.log(`\n✅ All systems operational!\n`);
    });
  } catch (err) {
    console.error("❌ DB connection error:", err);
    process.exit(1);
  }
}

// ==================== CLEANUP JOBS ====================
setInterval(
  async () => {
    try {
      const deleted = await NotificationService.cleanupOldNotifications();
      if (deleted > 0)
        console.log(`🧹 Cleaned up ${deleted} old notifications`);
    } catch (error) {
      console.error("Error cleaning notifications:", error);
    }
  },
  24 * 60 * 60 * 1000,
);

// ==================== EXPORTS ====================
export { io, stripe, server };
startServer();
