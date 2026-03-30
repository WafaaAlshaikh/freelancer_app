// src/routes/chatRoutes.js
import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { protect } from "../middleware/authMiddleware.js";
import {
  createChat,
  getUserChats,
  getChatMessages,
  sendMessage,
  markMessagesAsRead,
  deleteMessage,
  getUnreadCount,
  createChatFromContract,
} from "../controllers/chatController.js";

const router = express.Router();

router.use(protect);

router.post("/", createChat);

router.get("/", getUserChats);

router.get("/unread-count", getUnreadCount);

router.post("/contract/:contractId", createChatFromContract);

router.get("/:chatId/messages", getChatMessages);

router.post("/:chatId/messages", sendMessage);

router.put("/:chatId/read", markMessagesAsRead);

router.delete("/messages/:messageId", deleteMessage);

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = "uploads/chats";
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `chat-${req.user.id}-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error("Only images and documents are allowed"));
    }
  },
}).single("file");

router.post("/upload", protect, (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const fileUrl = `/uploads/chats/${req.file.filename}`;
    res.json({
      success: true,
      url: fileUrl,
      fileName: req.file.originalname,
      size: req.file.size,
    });
  });
});

export default router;
