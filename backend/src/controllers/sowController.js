// backend/src/controllers/sowController.js
import { Project, User, Contract } from "../models/index.js";
import AIService from "../services/aiService.js";

export const generateSOW = async (req, res) => {
  try {
    const {
      projectId,
      freelancerId,
      agreedAmount,
      milestones,
      additionalTerms,
    } = req.body;
    const clientId = req.user.id;

    console.log("📄 Generating SOW for project:", projectId);

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    if (project.UserId !== clientId) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const freelancer = await User.findByPk(freelancerId, {
      attributes: ["id", "name", "email", "avatar"],
    });

    if (!freelancer) {
      return res
        .status(404)
        .json({ success: false, message: "Freelancer not found" });
    }

    const projectData = {
      title: project.title,
      description: project.description,
      category: project.category,
      skills: project.skills ? JSON.parse(project.skills) : [],
      budget: agreedAmount || project.budget,
      duration: project.duration,
      clientName: req.user.name,
      clientEmail: req.user.email,
    };

    const sowResult = await AIService.generateProfessionalSOW(
      projectData,
      freelancer,
      milestones,
      additionalTerms || "",
    );

    res.json({
      success: true,
      sow: sowResult.html,
      sowNumber: sowResult.sowNumber,
      analysis: sowResult.analysis,
      recommendations: sowResult.analysis.final_recommendations || [],
    });
  } catch (error) {
    console.error("❌ Error generating SOW:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Failed to generate SOW",
    });
  }
};

export const analyzeProjectWithMarket = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    const projectData = {
      title: project.title,
      description: project.description,
      category: project.category,
      skills: project.skills ? JSON.parse(project.skills) : [],
      budget: project.budget,
      duration: project.duration,
    };

    const analysis = await AIService.analyzeProjectWithMarket(projectData);

    res.json({
      success: true,
      analysis,
    });
  } catch (error) {
    console.error("❌ Analysis error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getMarketRecommendations = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    const projectData = {
      category: project.category,
      budget: project.budget,
      duration: project.duration,
      skills: project.skills ? JSON.parse(project.skills) : [],
    };

    const marketInsights = await AIService.getMarketInsights(projectData);

    res.json({
      success: true,
      recommendations: marketInsights?.recommendations || [],
      insights: marketInsights,
    });
  } catch (error) {
    console.error("❌ Error getting recommendations:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
