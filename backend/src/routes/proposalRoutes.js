// routes/proposalRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { createProposal } from "../controllers/proposalController.js";

const router = express.Router();

router.post("/", protect, createProposal);

export default router;