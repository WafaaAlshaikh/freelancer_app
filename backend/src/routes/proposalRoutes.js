// routes/proposalRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { createProposal } from "../controllers/proposalController.js";
import { checkProposalLimit } from "../middleware/featureAccess.js";

const router = express.Router();
router.post("/", protect, checkProposalLimit, createProposal);
router.post("/", protect, createProposal);

export default router;
