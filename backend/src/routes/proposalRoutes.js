// routes/proposalRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  createProposal,
  analyzeProposalDraft,
} from "../controllers/proposalController.js";
import { checkProposalLimit } from "../middleware/featureAccess.js";

const router = express.Router();
router.post("/analyze-draft", protect, analyzeProposalDraft);
router.post("/", protect, checkProposalLimit, createProposal);

export default router;
