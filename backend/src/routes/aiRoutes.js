// routes/aiRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import AIMatchingService from "../services/aiMatchingService.js";

const router = express.Router();

router.get(
  "/freelancer/suggestions", 
  protect, 
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const result = await AIMatchingService.suggestProjectsForFreelancer(
        req.user.id,
        req.query.limit || 10
      );
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);

router.get(
  "/client/suggestions/:projectId",
  protect,
  authorizeRoles("client"),
  async (req, res) => {
    try {
      const result = await AIMatchingService.suggestFreelancersForClient(
        req.params.projectId,
        req.query.limit || 10
      );
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);

export default router;