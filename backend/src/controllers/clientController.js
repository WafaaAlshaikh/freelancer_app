// controllers/clientController.js
import stripe from "../config/stripe.js";
import { sequelize } from "../config/db.js";
import { Op, fn, col } from "sequelize";
import {
  Project,
  Proposal,
  User,
  FreelancerProfile,
  Contract,
  Wallet,
  Transaction,
  Notification,
} from "../models/index.js";
import ContractService from "../services/contractService.js";
import NotificationService from "../services/notificationService.js";
import PaymentService from "../services/paymentService.js";

export const getDashboardStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const totalProjects = await Project.count({ where: { UserId: userId } });
    const openProjects = await Project.count({
      where: { UserId: userId, status: "open" },
    });
    const inProgressProjects = await Project.count({
      where: { UserId: userId, status: "in_progress" },
    });
    const completedProjects = await Project.count({
      where: { UserId: userId, status: "completed" },
    });

    const myProjects = await Project.findAll({
      where: { UserId: userId },
      attributes: ["id"],
    });

    const projectIds = myProjects.map((p) => p.id);

    const totalProposals = await Proposal.count({
      where: { ProjectId: { [Op.in]: projectIds } },
    });

    const pendingProposals = await Proposal.count({
      where: {
        ProjectId: { [Op.in]: projectIds },
        status: "pending",
      },
    });

    const completedContracts = await Contract.findAll({
      where: { status: "completed" },
      include: [
        {
          model: Project,
          where: { UserId: userId },
        },
      ],
    });

    const totalSpent = completedContracts.reduce(
      (sum, contract) => sum + (contract.agreed_amount || 0),
      0,
    );

    res.json({
      stats: {
        totalProjects,
        openProjects,
        inProgressProjects,
        completedProjects,
        totalProposals,
        pendingProposals,
        totalSpent,
      },
    });
  } catch (err) {
    console.error("Error in getDashboardStats:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMyProjects = async (req, res) => {
  try {
    console.log("📥 Fetching projects for client:", req.user.id);

    const projects = await Project.findAll({
      where: { UserId: req.user.id },
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(`✅ Found ${projects.length} projects`);

    const projectsWithCounts = await Promise.all(
      projects.map(async (project) => {
        const proposalsCount = await Proposal.count({
          where: { ProjectId: project.id },
        });

        return {
          ...project.toJSON(),
          proposalsCount,
        };
      }),
    );

    res.json(projectsWithCounts);
  } catch (err) {
    console.error("❌ Error in getMyProjects:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectById = async (req, res) => {
  try {
    const { id } = req.params;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
      include: [
        {
          model: User,
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    const proposals = await Proposal.findAll({
      where: { ProjectId: id },
      include: [
        {
          model: User,
          attributes: ["id", "name", "avatar"],
        },
        {
          model: FreelancerProfile,
          attributes: ["title", "rating", "experience_years", "skills"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    const contract = await Contract.findOne({
      where: { ProjectId: id },
    });

    res.json({
      project,
      proposals,
      contract,
    });
  } catch (err) {
    console.error("Error in getProjectById:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createProject = async (req, res) => {
  try {
    const { title, description, budget, duration, category, skills } = req.body;

    if (!title || !description || !budget || !duration) {
      return res.status(400).json({
        message:
          "Please provide all required fields: title, description, budget, duration",
      });
    }

    const project = await Project.create({
      title,
      description,
      budget: parseFloat(budget),
      duration: parseInt(duration),
      category: category || "other",
      skills: skills ? JSON.stringify(skills) : "[]",
      status: "open",
      UserId: req.user.id,
    });

    res.status(201).json({
      message: "✅ Project created successfully",
      project,
    });
  } catch (err) {
    console.error("Error in createProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    if (project.status !== "open") {
      return res.status(400).json({
        message:
          "Cannot update project that is already in progress or completed",
      });
    }

    await project.update(updates);

    res.json({
      message: "✅ Project updated successfully",
      project,
    });
  } catch (err) {
    console.error("Error in updateProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const deleteProject = async (req, res) => {
  try {
    const { id } = req.params;

    const project = await Project.findOne({
      where: {
        id: id,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    if (project.status !== "open") {
      return res.status(400).json({
        message:
          "Cannot delete project that is already in progress or completed",
      });
    }

    await Proposal.destroy({ where: { ProjectId: id } });

    await project.destroy();

    res.json({ message: "✅ Project deleted successfully" });
  } catch (err) {
    console.error("Error in deleteProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectProposals = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findOne({
      where: {
        id: projectId,
        UserId: req.user.id,
      },
    });

    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }
    const proposals = await Proposal.findAll({
      where: { ProjectId: projectId },
      include: [
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar", "email"],
        },
        {
          model: FreelancerProfile,
          as: "profile",
          required: false,
          attributes: [
            "id",
            "title",
            "rating",
            "experience_years",
            "skills",
            "location",
            "cv_url",
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    console.log(
      `✅ Found ${proposals.length} proposals for project ${projectId}`,
    );

    const enhancedProposals = proposals.map((proposal) => {
      const proposalData = proposal.toJSON();
      return {
        ...proposalData,
        freelancerProfile: proposalData.profile,
        profile: undefined,
      };
    });

    res.json(enhancedProposals);
  } catch (err) {
    console.error("❌ Error in getProjectProposals:", err);
    res.status(500).json({
      message: "Server error",
      error: err.message,
    });
  }
};
export const updateProposalStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!["accepted", "rejected"].includes(status)) {
      return res
        .status(400)
        .json({ message: "Invalid status. Use 'accepted' or 'rejected'" });
    }

    const proposal = await Proposal.findByPk(id, {
      include: [
        {
          model: Project,
          include: [{ model: User, as: "client", attributes: ["id", "name"] }],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name"],
        },
      ],
    });

    if (!proposal) {
      return res
        .status(404)
        .json({ message: "Proposal not found or you don't have permission" });
    }

    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({
        message: `This proposal is already ${proposal.status}`,
      });
    }

    await proposal.update({ status });

    if (status === "accepted") {
      await Proposal.update(
        { status: "rejected" },
        {
          where: {
            ProjectId: proposal.ProjectId,
            id: { [Op.ne]: id },
            status: "pending",
          },
        },
      );

      const contract = await ContractService.createContractDraft(
        proposal.ProjectId,
        proposal.UserId,
        req.user.id,
        proposal.price,
      );

      await NotificationService.createNotification({
        userId: proposal.UserId,
        type: "proposal_accepted",
        title: "Your Proposal Was Accepted! 🎉",
        body: `Your proposal for "${proposal.Project.title}" has been accepted. Please review the contract.`,
        data: {
          projectId: proposal.ProjectId,
          contractId: contract.id,
          proposalId: proposal.id,
          screen: "contract",
        },
      });

      console.log("✅ Contract draft created:", contract.id);

      return res.json({
        message: "✅ Proposal accepted. Please review and sign the contract.",
        proposal,
        contract,
        requiresSignature: true,
      });
    }

    await NotificationService.createNotification({
      userId: proposal.UserId,
      type: "proposal_rejected",
      title: "Proposal Update",
      body: `Your proposal for "${proposal.Project.title}" was not selected this time.`,
      data: {
        projectId: proposal.ProjectId,
        proposalId: proposal.id,
        screen: "my_proposals",
      },
    });

    res.json({
      message: "✅ Proposal rejected",
      proposal,
    });
  } catch (err) {
    console.error("❌ Error in updateProposalStatus:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectContract = async (req, res) => {
  try {
    const { projectId } = req.params;

    const contract = await Contract.findOne({
      where: { ProjectId: projectId },
      include: [
        {
          model: Project,
          where: { UserId: req.user.id },
        },
        {
          model: User,
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    res.json(contract);
  } catch (err) {
    console.error("Error in getProjectContract:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getMyContracts = async (req, res) => {
  try {
    const contracts = await Contract.findAll({
      include: [
        {
          model: Project,
          where: { UserId: req.user.id },
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    res.json(contracts);
  } catch (err) {
    console.error("❌ Error in getMyContracts:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const completeProject = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findOne({
      where: {
        id: projectId,
        UserId: req.user.id,
        status: "in_progress",
      },
    });

    if (!project) {
      return res
        .status(404)
        .json({ message: "Project not found or not in progress" });
    }

    await project.update({ status: "completed" });

    const contract = await Contract.findOne({
      where: { ProjectId: projectId },
    });

    if (contract) {
      await contract.update({
        status: "completed",
        end_date: new Date(),
      });
    }

    res.json({
      message: "✅ Project completed successfully",
      project,
      contractId: contract?.id,
    });
  } catch (err) {
    console.error("Error in completeProject:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createContractFromProposal = async (req, res) => {
  try {
    const { proposalId } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [Project],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    const project = await Project.findOne({
      where: { id: proposal.ProjectId, UserId: req.user.id },
    });

    if (!project) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const contract = await ContractService.createContractDraft(
      proposal.ProjectId,
      proposal.UserId,
      req.user.id,
      proposal.price,
    );

    res.status(201).json({
      message: "Contract created successfully",
      contract,
    });
  } catch (err) {
    console.error("Error creating contract:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const startNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [
        { model: Project },
        { model: User, as: "freelancer", attributes: ["id", "name"] },
      ],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    if (proposal.status !== "pending") {
      return res.status(400).json({ message: "Proposal already processed" });
    }

    await proposal.update({ status: "negotiating" });

    res.json({
      message: "Negotiation started",
      proposal: {
        id: proposal.id,
        price: proposal.price,
        delivery_time: proposal.delivery_time,
        milestones: proposal.milestones,
        freelancer: proposal.freelancer,
      },
    });
  } catch (err) {
    console.error("Error in startNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updateNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;
    const { price, delivery_time, milestones } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [{ model: Project }],
    });

    if (!proposal) {
      return res.status(404).json({ message: "Proposal not found" });
    }

    if (
      proposal.Project.UserId !== req.user.id &&
      proposal.UserId !== req.user.id
    ) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const updateData = {};
    if (price) updateData.price = parseFloat(price);
    if (delivery_time) updateData.delivery_time = parseInt(delivery_time);
    if (milestones) updateData.milestones = milestones;

    const negotiatedData = {
      ...proposal.negotiated_data,
      [req.user.id]: updateData,
      last_updated_by: req.user.id,
      last_updated_at: new Date(),
    };

    await proposal.update({
      negotiated_data: negotiatedData,
      ...updateData,
    });

    res.json({
      message: "Negotiation updated",
      proposal,
    });
  } catch (err) {
    console.error("Error in updateNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const acceptProposalWithNegotiation = async (req, res) => {
  try {
    const { proposalId } = req.params;
    const { agreedPrice, agreedMilestones } = req.body;

    const proposal = await Proposal.findByPk(proposalId, {
      include: [
        { model: Project, include: [{ model: User, as: "client" }] },
        { model: User, as: "freelancer", attributes: ["id", "name", "email"] },
      ],
    });

    if (!proposal)
      return res.status(404).json({ message: "Proposal not found" });
    if (proposal.Project.UserId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const finalPrice = agreedPrice || proposal.price;
    const finalMilestones = agreedMilestones || proposal.milestones || [];

    const aiContract = await ContractService.generateAIContract(
      proposal.ProjectId,
      proposal.UserId,
      req.user.id,
      finalPrice,
      finalMilestones,
    );

    await Proposal.update(
      { status: "rejected" },
      { where: { ProjectId: proposal.ProjectId, id: { [Op.ne]: proposalId } } },
    );
    await proposal.update({ status: "accepted" });

    const contract = await Contract.create({
      ProjectId: proposal.ProjectId,
      FreelancerId: proposal.UserId,
      ClientId: req.user.id,
      agreed_amount: finalPrice,
      contract_document: aiContract,
      status: "draft",
      terms: "AI-generated contract with industry-specific clauses",
      milestones: JSON.stringify(finalMilestones),
    });

    const paymentIntent = await PaymentService.createEscrowPaymentIntent(
      contract.id,
      req.user.id,
    );

    res.json({
      message: "✅ Proposal accepted with AI-generated contract",
      contract,
      paymentIntent,
      requiresPayment: true,
    });
  } catch (err) {
    console.error("Error in acceptProposalWithNegotiation:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const confirmPayment = async (req, res) => {
  try {
    const { contractId, paymentIntentId } = req.body;

    const contract = await Contract.findByPk(contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.ClientId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    await PaymentService.handlePaymentSuccess(paymentIntentId);

    res.json({
      message: "✅ Payment confirmed. Contract is now active.",
      contract,
    });
  } catch (err) {
    console.error("Error in confirmPayment:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const releaseMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;

    const result = await PaymentService.releaseMilestonePayment(
      parseInt(contractId),
      parseInt(milestoneIndex),
      req.user.id,
    );

    res.json({
      message: "✅ Milestone payment released",
      ...result,
    });
  } catch (err) {
    console.error("Error in releaseMilestone:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const requestWithdrawal = async (req, res) => {
  try {
    const { amount } = req.body;

    const result = await PaymentService.requestWithdrawal(req.user.id, amount);

    res.json(result);
  } catch (err) {
    console.error("Error in requestWithdrawal:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ where: { UserId: req.user.id } });

    if (!wallet) {
      wallet = await Wallet.create({ UserId: req.user.id, balance: 0 });
    }

    const transactions = await Transaction.findAll({
      where: { wallet_id: wallet.id },
      order: [["createdAt", "DESC"]],
      limit: 50,
    });

    res.json({
      wallet,
      transactions,
    });
  } catch (err) {
    console.error("Error in getWallet:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createCheckoutSession = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { paymentIntentId } = req.body;

    console.log("🔍 Creating checkout session for contract:", contractId);
    console.log("🔍 Payment Intent ID:", paymentIntentId);

    const frontendUrl = process.env.FRONTEND_URL || "http://localhost:5000";
    console.log("🔍 Frontend URL:", frontendUrl);

    const result = await PaymentService.createCheckoutSession(
      contractId,
      req.user.id,
      frontendUrl,
    );

    console.log("✅ Checkout session result:", result);

    if (result.checkoutUrl) {
      res.json({
        success: true,
        checkoutUrl: result.checkoutUrl,
        sessionId: result.sessionId,
      });
    } else {
      res.status(400).json({
        success: false,
        message: "Failed to create checkout session",
      });
    }
  } catch (err) {
    console.error("Error creating checkout session:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const manualConfirmPayment = async (req, res) => {
  try {
    const { contractId } = req.params;

    console.log("💰 Manual payment confirmation for contract:", contractId);

    const contract = await Contract.findByPk(contractId);

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    await contract.update({
      escrow_status: "funded",
      payment_status: "escrow",
    });

    console.log(
      "✅ Contract updated:",
      contract.id,
      "escrow_status:",
      contract.escrow_status,
    );

    let clientWallet = await Wallet.findOne({
      where: { UserId: contract.ClientId },
    });
    if (!clientWallet) {
      clientWallet = await Wallet.create({
        UserId: contract.ClientId,
        balance: 0,
      });
    }

    const newPendingBalance =
      (clientWallet.pending_balance || 0) + contract.agreed_amount;
    await clientWallet.update({
      pending_balance: newPendingBalance,
    });
    console.log(
      "✅ Client wallet updated, pending_balance:",
      newPendingBalance,
    );

    const transaction = await Transaction.create({
      wallet_id: clientWallet.id,
      amount: contract.agreed_amount,
      type: "deposit",
      status: "completed",
      description: `Escrow deposit for contract #${contract.id}`,
      reference_id: contract.id,
      reference_type: "contract",
      completed_at: new Date(),
    });
    console.log("✅ Transaction created:", transaction.id);

    await NotificationService.createNotification({
      userId: contract.ClientId,
      type: "payment_received",
      title: "Payment Confirmed ✅",
      body: `$${contract.agreed_amount} has been deposited into escrow.`,
      data: { contractId: contract.id, screen: "contract" },
    });

    await NotificationService.createNotification({
      userId: contract.FreelancerId,
      type: "payment_received",
      title: "Payment Secured 💰",
      body: `The client has funded $${contract.agreed_amount} into escrow.`,
      data: { contractId: contract.id, screen: "contract" },
    });

    res.json({
      success: true,
      message: "Payment confirmed successfully",
      contract,
    });
  } catch (err) {
    console.error("Error in manualConfirmPayment:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const handlePaymentSuccess = async (req, res) => {
  try {
    const { session_id, contract_id } = req.query;

    console.log("💰 Payment success callback:", { session_id, contract_id });

    const result = await PaymentService.handleCheckoutSuccess(session_id);

    if (result.success) {
      res.redirect(
        `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=success`,
      );
    } else {
      res.redirect(
        `${process.env.FRONTEND_URL}/contract/${contract_id}?payment=failed`,
      );
    }
  } catch (err) {
    console.error("Error handling payment success:", err);
    res.redirect(`${process.env.FRONTEND_URL}/contract?payment=failed`);
  }
};

export const approveMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: userId },
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const milestones = contract.milestones;
    const milestone = milestones[milestoneIndex];

    if (!milestone) {
      return res.status(404).json({ message: "Milestone not found" });
    }

    if (milestone.status !== "completed") {
      return res.status(400).json({ message: "Milestone not completed yet" });
    }

    if (milestone.status === "approved") {
      return res.status(400).json({ message: "Milestone already approved" });
    }

    await PaymentService.releaseMilestonePayment(
      contractId,
      milestoneIndex,
      userId,
    );

    milestone.status = "approved";
    milestone.approved_at = new Date();
    milestones[milestoneIndex] = milestone;

    await contract.update({ milestones: JSON.stringify(milestones) });

    await NotificationService.createNotification({
      userId: contract.FreelancerId,
      type: "payment_released",
      title: "Milestone Payment Released! 💰",
      body: `$${milestone.amount} has been released for "${milestone.title}"`,
      data: { contractId: contract.id, screen: "contract" },
    });

    res.json({
      message: "✅ Milestone approved and payment released",
      milestone,
    });
  } catch (err) {
    console.error("Error approving milestone:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const createDirectPayment = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId, {
      include: [{ model: Project }],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.ClientId !== userId) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    console.log(
      "💰 Creating Payment Intent for amount:",
      contract.agreed_amount,
    );
    console.log(
      "🔑 Using Stripe key:",
      process.env.STRIPE_SECRET_KEY ? "Present" : "Missing",
    );

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(contract.agreed_amount * 100),
      currency: "usd",
      metadata: {
        contractId: contract.id,
        type: "escrow",
        projectTitle: contract.Project?.title || "Project Payment",
      },
      description: `Contract #${contract.id} - ${contract.Project?.title}`,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    console.log("✅ Payment Intent created:", paymentIntent.id);

    await contract.update({
      escrow_id: paymentIntent.id,
      escrow_status: "pending",
    });

    res.json({
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: contract.agreed_amount,
    });
  } catch (err) {
    console.error("Error creating direct payment:", err);
    res.status(500).json({
      success: false,
      message: err.message,
      error: err.toString(),
    });
  }
};

export const getClientDashboardOverview = async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();

    const projects = await Project.findAll({
      where: { UserId: userId },
      attributes: ["id", "title", "status", "budget", "createdAt"],
    });

    const totalProjects = projects.length;
    const openProjects = projects.filter((p) => p.status === "open").length;
    const inProgressProjects = projects.filter(
      (p) => p.status === "in_progress",
    ).length;
    const completedProjects = projects.filter(
      (p) => p.status === "completed",
    ).length;

    const projectIds = projects.map((p) => p.id);

    const proposals = await Proposal.findAll({
      where: { ProjectId: projectIds },
      include: [
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
        {
          model: FreelancerProfile,
          as: "profile",
          attributes: ["title", "rating", "skills"],
        },
        { model: Project, attributes: ["title", "id"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

    const totalProposals = proposals.length;
    const pendingProposals = proposals.filter(
      (p) => p.status === "pending",
    ).length;
    const acceptedProposals = proposals.filter(
      (p) => p.status === "accepted",
    ).length;

    const contracts = await Contract.findAll({
      where: { ClientId: userId },
      include: [
        { model: Project, attributes: ["title", "category"] },
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const completedContracts = contracts.filter(
      (c) => c.status === "completed",
    );
    const totalSpent = completedContracts.reduce(
      (sum, c) => sum + (parseFloat(c.agreed_amount) || 0),
      0,
    );
    const escrowHeld = contracts
      .filter((c) => c.escrow_status === "funded")
      .reduce((sum, c) => sum + (parseFloat(c.agreed_amount) || 0), 0);

    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    sixMonthsAgo.setDate(1);
    sixMonthsAgo.setHours(0, 0, 0, 0);

    const wallet = await Wallet.findOne({ where: { UserId: userId } });
    let monthlySpending = [];

    if (wallet) {
      const raw = await Transaction.findAll({
        where: {
          wallet_id: wallet.id,
          type: "deposit",
          status: "completed",
          createdAt: { [Op.gte]: sixMonthsAgo },
        },
        attributes: [
          [sequelize.fn("YEAR", sequelize.col("createdAt")), "year"],
          [sequelize.fn("MONTH", sequelize.col("createdAt")), "month"],
          [sequelize.fn("SUM", sequelize.col("amount")), "total"],
        ],
        group: [
          sequelize.fn("YEAR", sequelize.col("createdAt")),
          sequelize.fn("MONTH", sequelize.col("createdAt")),
        ],
        order: [
          [sequelize.fn("YEAR", sequelize.col("createdAt")), "ASC"],
          [sequelize.fn("MONTH", sequelize.col("createdAt")), "ASC"],
        ],
        raw: true,
      });

      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        const y = d.getFullYear();
        const m = d.getMonth() + 1;
        const found = raw.find(
          (r) => Number(r.year) === y && Number(r.month) === m,
        );
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          total: found ? parseFloat(found.total) : 0,
        });
      }
    } else {
      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          total: 0,
        });
      }
    }

    const activeContracts = contracts
      .filter((c) => c.status === "active")
      .map((c) => {
        const milestones = c.milestones
          ? Array.isArray(c.milestones)
            ? c.milestones
            : JSON.parse(c.milestones)
          : [];
        const total = milestones.length;
        const done = milestones.filter(
          (m) => m.status === "completed" || m.status === "approved",
        ).length;
        const progress = total > 0 ? Math.round((done / total) * 100) : 0;
        const nextMs = milestones.find(
          (m) => m.status !== "completed" && m.status !== "approved",
        );

        return {
          id: c.id,
          status: c.status,
          escrowStatus: c.escrow_status,
          agreedAmount: parseFloat(c.agreed_amount) || 0,
          releasedAmount: parseFloat(c.released_amount) || 0,
          progress: progress,
          milestonesTotal: total,
          milestonesDone: done,
          projectTitle: c.Project?.title,
          projectCategory: c.Project?.category,
          projectId: c.Project?.id,
          freelancerName: c.freelancer?.name,
          freelancerAvatar: c.freelancer?.avatar,
          nextMilestoneTitle: nextMs?.title || null,
        };
      });

    const notifications = await Notification.findAll({
      where: { userId: userId },
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

    const statusBreakdown = [
      { label: "Open", value: openProjects, color: "#3B82F6" },
      { label: "In Progress", value: inProgressProjects, color: "#F59E0B" },
      { label: "Completed", value: completedProjects, color: "#10B981" },
    ].filter((s) => s.value > 0);

    const topFreelancers = await User.findAll({
      where: { role: "freelancer" },
      include: [{ model: FreelancerProfile, attributes: ["rating"] }],
      limit: 5,
      attributes: ["id", "name", "avatar"],
    });

    res.json({
      stats: {
        totalProjects,
        openProjects,
        inProgressProjects,
        completedProjects,
        totalProposals,
        pendingProposals,
        acceptedProposals,
        totalSpent,
        escrowHeld,
        totalReleased: 0,
        proposalAcceptRate:
          totalProposals > 0
            ? Math.round((acceptedProposals / totalProposals) * 100)
            : 0,
      },
      monthlySpending,
      statusBreakdown,
      recentProposals: proposals.map((p) => ({
        id: p.id,
        status: p.status,
        price: parseFloat(p.price) || 0,
        deliveryTime: p.delivery_time,
        proposalText: p.proposal_text,
        projectTitle: p.Project?.title,
        projectId: p.Project?.id,
        freelancerName: p.freelancer?.name,
        freelancerAvatar: p.freelancer?.avatar,
        freelancerTitle: p.profile?.title,
        freelancerRating: p.profile?.rating,
        skills: p.profile?.skills
          ? typeof p.profile.skills === "string"
            ? JSON.parse(p.profile.skills)
            : p.profile.skills
          : [],
      })),
      activeContracts,
      recentActivity: notifications.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: n.isRead,
        createdAt: n.createdAt,
        data: n.data,
      })),
      topFreelancers: topFreelancers.map((f) => ({
        id: f.id,
        name: f.name,
        avatar: f.avatar,
        rating: f.FreelancerProfile?.rating || 0,
      })),
    });
  } catch (error) {
    console.error("❌ Error in getClientDashboardOverview:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

export const getClientProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findByPk(userId, {
      attributes: ["id", "name", "avatar", "email"],
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      id: user.id,
      name: user.name,
      avatar: user.avatar,
      email: user.email,
      company: user.company || null,
      phone: user.phone || null,
    });
  } catch (error) {
    console.error("❌ Error in getClientProfile:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
