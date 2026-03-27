// src/routes/chatRoutes.js
import express from "express";
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

export default router;