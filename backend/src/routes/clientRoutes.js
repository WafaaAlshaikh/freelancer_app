// routes/clientRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardStats,
  getMyProjects,
  getProjectById,
  createProject,
  updateProject,
  deleteProject,
  getProjectProposals,
  updateProposalStatus,
  getProjectContract,
  getMyContracts,
  completeProject,
  startNegotiation,
  updateNegotiation,
  acceptProposalWithNegotiation,
  confirmPayment,
  releaseMilestone,
  requestWithdrawal,
  getWallet,
  createCheckoutSession,
  handlePaymentSuccess,
} from "../controllers/clientController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("client"));

// Dashboard
router.get("/dashboard/stats", getDashboardStats);

// Projects
router.get("/projects", getMyProjects);
router.post("/projects", createProject);
router.get("/projects/:id", getProjectById);
router.put("/projects/:id", updateProject);
router.delete("/projects/:id", deleteProject);
router.put("/projects/:projectId/complete", completeProject);

// Proposals
router.get("/projects/:projectId/proposals", getProjectProposals);
router.put("/proposals/:id", updateProposalStatus);


router.post("/proposals/:proposalId/negotiate", startNegotiation);
router.put("/proposals/:proposalId/negotiate", updateNegotiation);
router.post("/proposals/:proposalId/accept", acceptProposalWithNegotiation);

// Contracts
router.get("/projects/:projectId/contract", getProjectContract);
router.get("/contracts", getMyContracts);

router.post("/contracts/:contractId/confirm-payment", confirmPayment);
router.post("/contracts/:contractId/milestones/:milestoneIndex/release", releaseMilestone);

// Wallet
router.get("/wallet", getWallet);
router.post("/wallet/withdraw", requestWithdrawal);

// Stripe Checkout
router.post("/contracts/:contractId/create-checkout", createCheckoutSession);
router.get("/payment/success", handlePaymentSuccess);

export default router;