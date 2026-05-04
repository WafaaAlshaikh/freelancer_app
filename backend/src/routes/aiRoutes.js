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
      const { title, description, category, skills, budget, duration } =
        req.body;

      console.log("🤖 [ANALYZE] Starting AI project analysis...");
      console.log(`📋 Project: "${title}" (${category || "general"})`);
      console.log(`🔧 Skills: ${skills?.length || 0} skills provided`);

      let aiAnalysis;
      try {
        aiAnalysis = await AIService.analyzeProject({
          title: title || "",
          description: description || "",
          category: category || "general",
          skills: skills || [],
          budget: budget || 1000,
          duration: duration || 21,
        });

        console.log(
          `✅ AI analysis successful with ${aiAnalysis.suggested_milestones?.length || 0} milestones`,
        );
      } catch (aiError) {
        console.error("⚠️ AI analysis failed, using default:", aiError.message);
        aiAnalysis = AIService.getDefaultProjectAnalysis({
          title,
          description,
          category,
          skills,
          budget,
        });
      }

      const ensureValidMilestones = (milestones, title, description) => {
        if (milestones && Array.isArray(milestones) && milestones.length > 0) {
          const validMilestones = milestones.filter(
            (m) =>
              m.title && typeof m.percentage === "number" && m.percentage > 0,
          );

          if (validMilestones.length > 0) {
            const total = validMilestones.reduce(
              (sum, m) => sum + m.percentage,
              0,
            );
            if (total !== 100 && total > 0) {
              const factor = 100 / total;
              validMilestones.forEach((m) => {
                m.percentage = Math.round(m.percentage * factor);
              });
            }
            return validMilestones;
          }
        }

        const text = `${title} ${description}`.toLowerCase();

        if (
          text.includes("ecommerce") ||
          text.includes("shop") ||
          text.includes("clothes")
        ) {
          return [
            {
              title: "Project Setup & Database Design",
              description:
                "Setup project structure, database schema, authentication system",
              percentage: 20,
            },
            {
              title: "Product & Category Management",
              description: "Product catalog, categories, inventory management",
              percentage: 30,
            },
            {
              title: "Shopping Cart & Payment Integration",
              description: "Cart functionality, payment gateway integration",
              percentage: 30,
            },
            {
              title: "Testing & Deployment",
              description: "QA testing, bug fixes, production deployment",
              percentage: 20,
            },
          ];
        }

        return [
          {
            title: "Project Setup & Planning",
            description:
              "Initial setup, requirements analysis, timeline planning",
            percentage: 20,
          },
          {
            title: "Core Development",
            description: "Main features implementation",
            percentage: 50,
          },
          {
            title: "Testing & Final Delivery",
            description: "Quality assurance, bug fixes, final delivery",
            percentage: 30,
          },
        ];
      };

      const responseData = {
        success: true,
        analysis: {
          difficulty_level: aiAnalysis.difficulty_level || "intermediate",
          estimated_duration_days:
            aiAnalysis.estimated_duration_days || duration || 21,
          price_range: aiAnalysis.price_range || {
            min: Math.round((budget || 1000) * 0.8),
            max: Math.round((budget || 1000) * 1.2),
            recommended: budget || 1500,
            currency: "USD",
          },
          complexity_factors: aiAnalysis.complexity_factors || [
            "Standard Development",
            "Requirements analysis",
            "Quality assurance",
          ],
          market_comparison: aiAnalysis.market_comparison || {
            lowest: Math.round((budget || 1000) * 0.7),
            average: budget || 1500,
            highest: Math.round((budget || 1000) * 1.3),
          },
          suggested_milestones: ensureValidMilestones(
            aiAnalysis.suggested_milestones,
            title,
            description,
          ),
          risks: aiAnalysis.risks || [
            "Timeline management",
            "Scope creep",
            "Communication clarity",
          ],
          tips: aiAnalysis.tips || [
            "Define clear requirements before starting",
            "Use version control (Git)",
            "Schedule regular progress meetings",
          ],
          confidence_score: aiAnalysis.confidence_score || 85,
        },
      };

      console.log(
        `📊 Final response: ${responseData.analysis.suggested_milestones.length} milestones`,
      );
      responseData.analysis.suggested_milestones.forEach((m, i) => {
        console.log(`   ${i + 1}. ${m.title} (${m.percentage}%)`);
      });

      res.json(responseData);
    } catch (error) {
      console.error("❌ [ANALYZE] Fatal error:", error);

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
              description:
                "Initial setup, requirements analysis, and architecture design",
              percentage: 20,
            },
            {
              title: "Core Development",
              description: "Main features implementation",
              percentage: 50,
            },
            {
              title: "Testing & Delivery",
              description: "Quality assurance, bug fixes, and final delivery",
              percentage: 30,
            },
          ],
          risks: ["Timeline management"],
          tips: ["Communicate regularly", "Use version control"],
          confidence_score: 50,
        },
      });
    }
  },
);

function _ensureValidMilestones(milestones, title, description) {
  if (milestones && Array.isArray(milestones) && milestones.length > 0) {
    const validMilestones = milestones.filter(
      (m) => m.title && typeof m.percentage === "number" && m.percentage > 0,
    );

    if (validMilestones.length > 0) {
      const total = validMilestones.reduce((sum, m) => sum + m.percentage, 0);
      if (total !== 100 && total > 0) {
        const factor = 100 / total;
        validMilestones.forEach((m) => {
          m.percentage = Math.round(m.percentage * factor);
        });
      }
      return validMilestones;
    }
  }

  const text = `${title} ${description}`.toLowerCase();

  if (text.includes("ecommerce") || text.includes("shop")) {
    return [
      {
        title: "Project Setup & Database Design",
        description:
          "Setup project structure, database schema, authentication system",
        percentage: 20,
      },
      {
        title: "Product & Category Management",
        description: "Product catalog, categories, inventory management",
        percentage: 30,
      },
      {
        title: "Shopping Cart & Payment Integration",
        description: "Cart functionality, payment gateway integration",
        percentage: 30,
      },
      {
        title: "Testing & Deployment",
        description: "QA testing, bug fixes, production deployment",
        percentage: 20,
      },
    ];
  }

  if (
    text.includes("mobile") ||
    text.includes("flutter") ||
    text.includes("android") ||
    text.includes("ios")
  ) {
    return [
      {
        title: "UI/UX Design & Setup",
        description: "App design, project setup, navigation structure",
        percentage: 20,
      },
      {
        title: "Core Features Development",
        description: "Main functionality implementation",
        percentage: 40,
      },
      {
        title: "API Integration & Testing",
        description: "Backend integration, unit testing, bug fixes",
        percentage: 25,
      },
      {
        title: "Store Submission & Launch",
        description: "App store preparation, submission, launch",
        percentage: 15,
      },
    ];
  }

  if (
    text.includes("web") ||
    text.includes("website") ||
    text.includes("react")
  ) {
    return [
      {
        title: "Frontend Development",
        description: "UI components, responsive design, state management",
        percentage: 35,
      },
      {
        title: "Backend Development",
        description: "API development, database integration, authentication",
        percentage: 35,
      },
      {
        title: "Testing & Deployment",
        description: "QA testing, performance optimization, deployment",
        percentage: 30,
      },
    ];
  }

  return [
    {
      title: "Project Setup & Planning",
      description: "Initial setup, requirements analysis, timeline planning",
      percentage: 20,
    },
    {
      title: "Core Development",
      description: "Main features implementation",
      percentage: 50,
    },
    {
      title: "Testing & Final Delivery",
      description: "Quality assurance, bug fixes, final delivery",
      percentage: 30,
    },
  ];
}

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
