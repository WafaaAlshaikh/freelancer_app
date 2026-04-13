// ===== backend/src/controllers/workSubmissionController.js =====
import {
  WorkSubmission,
  Contract,
  Project,
  User,
  Notification,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";

export const submitWork = async (req, res) => {
  try {
    const { contractId, milestoneIndex, title, description, files, links } =
      req.body;
    const freelancerId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: freelancerId },
      include: [{ model: Project }],
    });

    if (!contract) {
      return res
        .status(404)
        .json({ success: false, message: "Contract not found" });
    }

    if (contract.status !== "active") {
      return res
        .status(400)
        .json({ success: false, message: "Contract is not active" });
    }

    const submission = await WorkSubmission.create({
      contract_id: contractId,
      milestone_index: milestoneIndex || null,
      freelancer_id: freelancerId,
      client_id: contract.ClientId,
      title,
      description,
      files: files || [],
      links: links || [],
      status: "pending",
      submitted_at: new Date(),
    });

    await NotificationService.createNotification({
      userId: contract.ClientId,
      type: "work_submitted",
      title: "New Work Submitted",
      body: `${req.user.name} has submitted work for "${contract.Project?.title}"`,
      data: {
        submissionId: submission.id,
        contractId: contract.id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Work submitted successfully",
      submission,
    });
  } catch (error) {
    console.error("Error submitting work:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const approveWork = async (req, res) => {
  try {
    const { submissionId } = req.params;
    const clientId = req.user.id;

    const submission = await WorkSubmission.findOne({
      where: { id: submissionId, client_id: clientId },
      include: [{ model: Contract }],
    });

    if (!submission) {
      return res
        .status(404)
        .json({ success: false, message: "Submission not found" });
    }

    await submission.update({
      status: "approved",
      approved_at: new Date(),
    });

    if (
      submission.milestone_index !== null &&
      submission.milestone_index !== undefined
    ) {
      const contract = submission.Contract;
      let milestones = contract.milestones;
      if (typeof milestones === "string") {
        milestones = JSON.parse(milestones);
      }

      if (milestones[submission.milestone_index]) {
        milestones[submission.milestone_index].status = "completed";
        milestones[submission.milestone_index].completed_at = new Date();
        await contract.update({ milestones: JSON.stringify(milestones) });
      }
    }

    await NotificationService.createNotification({
      userId: submission.freelancer_id,
      type: "work_approved",
      title: "Work Approved!",
      body: "Your work has been approved by the client.",
      data: {
        submissionId: submission.id,
        contractId: submission.contract_id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Work approved successfully",
      submission,
    });
  } catch (error) {
    console.error("Error approving work:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const requestRevision = async (req, res) => {
  try {
    const { submissionId } = req.params;
    const { revisionMessage } = req.body;
    const clientId = req.user.id;

    const submission = await WorkSubmission.findOne({
      where: { id: submissionId, client_id: clientId },
    });

    if (!submission) {
      return res
        .status(404)
        .json({ success: false, message: "Submission not found" });
    }

    await submission.update({
      status: "revision_requested",
      revision_request_message: revisionMessage,
    });

    await NotificationService.createNotification({
      userId: submission.freelancer_id,
      type: "revision_requested",
      title: "Revision Requested",
      body: revisionMessage || "The client has requested changes to your work.",
      data: {
        submissionId: submission.id,
        contractId: submission.contract_id,
        screen: "contract_progress",
      },
    });

    res.json({
      success: true,
      message: "Revision requested",
      submission,
    });
  } catch (error) {
    console.error("Error requesting revision:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getContractSubmissions = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const submissions = await WorkSubmission.findAll({
      where: {
        contract_id: contractId,
        [Op.or]: [{ freelancer_id: userId }, { client_id: userId }],
      },
      order: [["submitted_at", "DESC"]],
    });

    res.json({
      success: true,
      submissions,
    });
  } catch (error) {
    console.error("Error getting submissions:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
