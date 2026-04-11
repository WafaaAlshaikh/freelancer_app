// backend/src/routes/aiRoutes.js

import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import AIMatchingService from "../services/aiMatchingService.js";
import AIService from "../services/aiService.js";
import AIChatController from "../controllers/aiChatController.js";
import {
  generateSOW,
  analyzeProjectWithMarket,
  getMarketRecommendations,
} from "../controllers/sowController.js";

const router = express.Router();

router.get(
  "/freelancer/suggestions",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const result = await AIMatchingService.suggestProjectsForFreelancer(
        req.user.id,
        req.query.limit || 10,
      );
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },
);

router.get(
  "/client/suggestions/:projectId",
  protect,
  authorizeRoles("client"),
  async (req, res) => {
    try {
      const result = await AIMatchingService.suggestFreelancersForClient(
        req.params.projectId,
        req.query.limit || 10,
      );
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },
);

router.post(
  "/analyze-project",
  protect,
  authorizeRoles("client", "freelancer"),
  async (req, res) => {
    try {
      const { title, description, category, skills, budget } = req.body;

      console.log("🤖 Analyzing project:", {
        title,
        description: description?.substring(0, 100),
        skills: skills?.length || 0,
      });

      const defaultAnalysis = AIService.getDefaultProjectAnalysis({
        title,
        description,
        category,
        skills,
        budget,
      });

      console.log("✅ Default analysis generated:", {
        hasMilestones: defaultAnalysis?.suggested_milestones?.length > 0,
        milestonesCount: defaultAnalysis?.suggested_milestones?.length || 0,
        firstMilestone: defaultAnalysis?.suggested_milestones?.[0]?.title,
      });

      const responseData = {
        success: true,
        analysis: {
          difficulty_level: defaultAnalysis.difficulty_level || "intermediate",
          estimated_duration_days:
            defaultAnalysis.estimated_duration_days || 21,
          price_range: defaultAnalysis.price_range || {
            min: 1000,
            max: 2000,
            recommended: 1500,
            currency: "USD",
          },
          complexity_factors: defaultAnalysis.complexity_factors || [
            "Standard Development",
          ],
          market_comparison: defaultAnalysis.market_comparison || {
            lowest: 800,
            average: 1500,
            highest: 2500,
          },
          suggested_milestones: defaultAnalysis.suggested_milestones || [],
          risks: defaultAnalysis.risks || ["Timeline management"],
          tips: defaultAnalysis.tips || ["Communicate regularly"],
        },
      };

      if (responseData.analysis.suggested_milestones.length === 0) {
        console.log(
          "⚠️ WARNING: No milestones in response! Adding default milestones.",
        );
        responseData.analysis.suggested_milestones = [
          {
            title: "Project Setup & Planning",
            description: "Initial setup and requirements",
            percentage: 20,
          },
          {
            title: "Core Development",
            description: "Main features implementation",
            percentage: 50,
          },
          {
            title: "Testing & Delivery",
            description: "QA and final delivery",
            percentage: 30,
          },
        ];
      }

      console.log(
        `✅ Sending response with ${responseData.analysis.suggested_milestones.length} milestones`,
      );
      res.json(responseData);
    } catch (error) {
      console.error("❌ Analysis error:", error);

      res.json({
        success: true,
        analysis: {
          difficulty_level: "intermediate",
          estimated_duration_days: 21,
          price_range: {
            min: 1000,
            max: 2000,
            recommended: 1500,
            currency: "USD",
          },
          complexity_factors: ["Standard Development"],
          market_comparison: {
            lowest: 800,
            average: 1500,
            highest: 2500,
          },
          suggested_milestones: [
            {
              title: "Project Setup & Planning",
              description: "Initial setup and requirements",
              percentage: 20,
            },
            {
              title: "Core Development",
              description: "Main features implementation",
              percentage: 50,
            },
            {
              title: "Testing & Delivery",
              description: "QA and final delivery",
              percentage: 30,
            },
          ],
          risks: ["Timeline management"],
          tips: ["Communicate regularly"],
        },
      });
    }
  },
);

router.get(
  "/smart-pricing/:projectId",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const pricing = await AIService.getSmartPricing(
        req.user.id,
        req.params.projectId,
      );
      res.json({ success: true, pricing });
    } catch (error) {
      console.error("❌ Smart pricing error:", error);
      res.json({ success: false, pricing: null });
    }
  },
);

router.get(
  "/personalized-recommendations",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const recommendations =
        await AIMatchingService.getPersonalizedRecommendations(
          req.user.id,
          req.query.limit || 10,
        );
      res.json({ success: true, recommendations });
    } catch (error) {
      console.error("❌ Recommendations error:", error);
      res.json({ success: false, recommendations: [] });
    }
  },
);

router.post("/chat", protect, AIChatController.chat);
router.get("/chat/history", protect, AIChatController.getChatHistory);
router.delete("/chat/history", protect, AIChatController.clearChatHistory);

router.post("/generate-sow", protect, authorizeRoles("client"), generateSOW);

router.get(
  "/analyze-with-market/:projectId",
  protect,
  authorizeRoles("client", "freelancer"),
  analyzeProjectWithMarket,
);

router.get(
  "/market-recommendations/:projectId",
  protect,
  authorizeRoles("client"),
  getMarketRecommendations,
);
export default router;
