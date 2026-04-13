// controllers/proposalController.js
import { Proposal, Project, User } from "../models/index.js";
import NotificationService from "../services/notificationService.js";
import SubscriptionService from "../services/subscriptionService.js";
import AIService from "../services/aiService.js";

const normalizeMilestones = (rawMilestones, totalPrice) => {
  if (!Array.isArray(rawMilestones) || rawMilestones.length === 0) return [];

  const normalized = rawMilestones
    .map((m) => ({
      title: (m?.title || "").toString().trim(),
      description: (m?.description || "").toString().trim(),
      amount: Number(m?.amount || 0),
      percentage: Number(m?.percentage || 0),
      due_date: m?.due_date || null,
      status: "pending",
    }))
    .filter((m) => m.title && m.amount > 0);

  if (normalized.length === 0) return [];

  const sumAmount = normalized.reduce((sum, m) => sum + m.amount, 0);
  const hasValidTotal = Math.abs(sumAmount - Number(totalPrice)) <= 0.01;
  if (!hasValidTotal) {
    throw new Error("Milestone amounts do not match proposal price");
  }

  const percentageSum = normalized.reduce((sum, m) => sum + m.percentage, 0);
  if (percentageSum > 0 && Math.abs(percentageSum - 100) > 1) {
    throw new Error("Milestone percentages must add up to 100");
  }

  return normalized;
};

export const createProposal = async (req, res) => {
  try {
    console.log("📥 [CREATE PROPOSAL] Request received");
    console.log("👤 User ID:", req.user.id);
    console.log("📦 Body:", req.body);

    const { projectId, price, delivery_time, proposal_text, milestones } =
      req.body;

    if (!projectId || !price || !delivery_time || !proposal_text) {
      console.log("❌ Missing fields:", {
        projectId,
        price,
        delivery_time,
        proposal_text,
      });
      return res.status(400).json({
        message: "Missing required fields",
        required: ["projectId", "price", "delivery_time", "proposal_text"],
      });
    }

    console.log("🔍 Checking project:", projectId);
    const project = await Project.findByPk(projectId, {
      include: [{ model: User, as: "client", attributes: ["id", "name"] }],
    });

    if (!project) {
      console.log("❌ Project not found:", projectId);
      return res.status(404).json({ message: "Project not found" });
    }

    console.log("✅ Project found:", project.title, "Status:", project.status);

    const canSubmit = await SubscriptionService.canSubmitProposal(req.user.id);
    if (!canSubmit) {
      return res.status(403).json({
        message:
          "You have reached your proposal limit for this month. Please upgrade your plan to submit more proposals.",
      });
    }

    if (project.status !== "open") {
      console.log("❌ Project not open:", project.status);
      return res
        .status(400)
        .json({ message: "This project is not accepting proposals" });
    }

    console.log(
      "🔍 Checking existing proposal for user:",
      req.user.id,
      "project:",
      projectId,
    );
    const existingProposal = await Proposal.findOne({
      where: {
        UserId: req.user.id,
        ProjectId: projectId,
      },
    });

    if (existingProposal) {
      console.log("❌ Duplicate proposal found");
      return res
        .status(400)
        .json({ message: "You already submitted a proposal for this project" });
    }

    console.log("📝 Creating new proposal...");
    const proposal = await Proposal.create({
      UserId: req.user.id,
      ProjectId: projectId,
      price: parseFloat(price),
      delivery_time: parseInt(delivery_time),
      proposal_text: proposal_text.trim(),
      milestones: normalizeMilestones(milestones, parseFloat(price)),
      status: "pending",
    });
    await SubscriptionService.incrementProposalCount(req.user.id);

    await NotificationService.createNotification({
      userId: project.UserId,
      type: "proposal_received",
      title: "New Proposal Received",
      body: `${req.user.name} submitted a proposal for "${project.title}"`,
      data: {
        projectId: project.id,
        proposalId: proposal.id,
        freelancerId: req.user.id,
        screen: "project_proposals",
      },
    });

    console.log("✅ Proposal created successfully with ID:", proposal.id);

    res.status(201).json({
      message: "✅ Proposal submitted successfully",
      proposal,
    });
  } catch (err) {
    console.error("❌ [ERROR] in createProposal:");
    console.error("Error name:", err.name);
    console.error("Error message:", err.message);
    console.error("Error stack:", err.stack);

    res.status(500).json({
      message: "Server error",
      error: err.message,
      details: err.toString(),
    });
  }
};

export const analyzeProposalDraft = async (req, res) => {
  try {
    const { projectId, price, delivery_time, proposal_text } = req.body;

    if (!projectId || !price || !delivery_time || !proposal_text) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields for proposal analysis",
      });
    }

    const project = await Project.findByPk(projectId, {
      include: [{ model: User, as: "client", attributes: ["id", "name"] }],
    });
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    const analysis = await AIService.analyzeProposalDraft(
      {
        price: Number(price),
        delivery_time: Number(delivery_time),
        proposal_text: proposal_text.toString(),
      },
      {
        title: project.title,
        description: project.description,
        budget: Number(project.budget || 0),
        duration: Number(project.duration || 0),
        skills: project.skills || [],
      },
    );

    res.json({
      success: true,
      analysis,
    });
  } catch (err) {
    console.error("❌ Error in analyzeProposalDraft:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};
