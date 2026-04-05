// controllers/proposalController.js
import { Proposal, Project, User } from "../models/index.js";
import NotificationService from "../services/notificationService.js";
import SubscriptionService from "../services/subscriptionService.js";

export const createProposal = async (req, res) => {
  try {
    console.log("📥 [CREATE PROPOSAL] Request received");
    console.log("👤 User ID:", req.user.id);
    console.log("📦 Body:", req.body);

    const { projectId, price, delivery_time, proposal_text } = req.body;

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
