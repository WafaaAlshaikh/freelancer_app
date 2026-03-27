// server.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import fs from "fs";
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
import stripeWebhookRoutes from "./src/routes/stripeWebhookRoutes.js";
import { initSocket } from "./src/socket/socketManager.js";

dotenv.config();

const app = express();
const server = http.createServer(app);

const io = initSocket(server);

const uploadDirs = ['uploads/cvs', 'uploads/avatars', 'uploads/portfolio'];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

app.use(cors({
  origin: '*', 
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use("/api/stripe", stripeWebhookRoutes);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

app.get("/", (req, res) => res.send("API is running..."));

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

app.use((req, res) => {
  res.status(404).json({ message: `Cannot ${req.method} ${req.path}` });
});

app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({ message: err.message || 'Internal server error' });
});

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    await sequelize.sync({ alter: true });
    console.log("✅ Tables synced with database");
    
    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`🔌 Socket.io ready for real-time events`);
    });
  } catch (err) {
    console.error("❌ DB connection error:", err);
  }
}

setInterval(async () => {
  try {
    const deleted = await NotificationService.cleanupOldNotifications();
    if (deleted > 0) console.log(`🧹 Cleaned up ${deleted} old notifications`);
  } catch (error) {
    console.error('Error cleaning notifications:', error);
  }
}, 24 * 60 * 60 * 1000);

startServer();

export { io };