// routes/freelancerRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getProfile,
  updateProfile,
  getProposals,
  getProjects,
  getProjectContract,
  getWallet,
  getMessages,
  uploadAndAnalyzeCV,
  uploadCV,
  updateLocation,
  uploadAvatar,
  getSuggestedProjects,
  getFreelancerStats,
  getFreelancerContracts,
} from "../controllers/freelancerController.js";
import multer from "multer";
import path from "path";
import ContractService from "../services/contractService.js";
import {
  createPortfolio,
  getUserPortfolio,
  updatePortfolio,
  deletePortfolio,
  uploadPortfolioImages,
  createPortfolioFromSubmission,
  createPortfolioFromContractMilestone,
} from "../controllers/portfolioController.js";

import {
  getWallet as getFreelancerWallet,
  requestWithdrawal as requestFreelancerWithdrawal,
  updateMilestoneProgress,
} from "../controllers/freelancerController.js";
import {
  Offer,
  User,
  Project,
  Contract,
  Notification,
} from "../models/index.js";
import NotificationService from "../services/notificationService.js";

const router = express.Router();

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/avatars/");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      `avatar-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`,
    );
  },
});

const uploadAvatarMiddleware = multer({
  storage: avatarStorage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"));
    }
  },
  limits: { fileSize: 2 * 1024 * 1024 },
}).single("avatar");

router.use(protect);
router.use(authorizeRoles("freelancer"));

router.get("/profile", getProfile);
router.put("/profile", updateProfile);
router.post("/profile/avatar", uploadAvatarMiddleware, uploadAvatar);
router.post("/profile/cv-upload", uploadCV, uploadAndAnalyzeCV);
router.post("/profile/location", updateLocation);

router.get("/stats", getFreelancerStats);
router.get("/suggested-projects", getSuggestedProjects);

router.get("/proposals", getProposals);

router.get("/projects", getProjects);
router.get("/projects/:projectId/contract", getProjectContract);

router.get("/wallet", getWallet);

router.get("/messages", getMessages);

router.get("/contracts", getFreelancerContracts);

router.post("/portfolio", uploadPortfolioImages, createPortfolio);
router.post("/portfolio/from-submission", createPortfolioFromSubmission);
router.post(
  "/portfolio/from-contract-milestone",
  createPortfolioFromContractMilestone,
);
router.get("/portfolio/:userId", getUserPortfolio);
router.put("/portfolio/:id", updatePortfolio);
router.delete("/portfolio/:id", deletePortfolio);

router.get("/wallet", getFreelancerWallet);
router.post("/wallet/withdraw", requestFreelancerWithdrawal);

router.put(
  "/contracts/:contractId/milestones/:milestoneIndex/progress",
  updateMilestoneProgress,
);

router.get(
  "/offers",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      console.log("🔍 ===== GET /offers =====");
      console.log("📌 User ID:", req.user.id);
      console.log("📌 User Role:", req.user.role);

      console.log("📌 Offer Model available:", typeof Offer !== "undefined");

      const offers = await Offer.findAll({
        where: { freelancerId: req.user.id },
        order: [["createdAt", "DESC"]],
        include: [
          { model: User, as: "client", attributes: ["id", "name", "avatar"] },
          { model: Project, as: "project", attributes: ["id", "title"] },
        ],
      });

      console.log("📊 Offers found:", offers.length);
      console.log("📊 Offers data:", JSON.stringify(offers, null, 2));

      const formatted = offers.map((o) => ({
        id: o.id,
        clientId: o.clientId,
        clientName: o.client?.name,
        clientAvatar: o.client?.avatar,
        projectId: o.projectId,
        projectTitle: o.project?.title,
        amount: o.amount,
        message: o.message,
        status: o.status,
        createdAt: o.createdAt,
        expiresAt: o.expiresAt,
        viewedAt: o.viewedAt,
      }));

      console.log("✅ Response:", {
        success: true,
        offersCount: formatted.length,
      });
      res.json({ success: true, offers: formatted });
    } catch (error) {
      console.error("❌ Error in GET /offers:", error);
      console.error("❌ Error stack:", error.stack);
      res.status(500).json({ success: false, message: error.message });
    }
  },
);

router.post(
  "/offers/:id/respond",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const offer = await Offer.findByPk(id);
      if (!offer) {
        return res
          .status(404)
          .json({ success: false, message: "Offer not found" });
      }

      if (offer.freelancerId !== req.user.id) {
        return res
          .status(403)
          .json({ success: false, message: "Unauthorized" });
      }

      await offer.update({
        status: status,
        viewedAt: new Date(),
      });

      let contractId = null;

      if (status === "accepted") {
        const project = await Project.findByPk(offer.projectId);
        if (project) {
          const milestones = ContractService.generateMilestones(
            offer.amount || project.budget,
            project,
          );

          const contractDocument = ContractService.generateContractDocument({
            projectId: offer.projectId,
            freelancerId: offer.freelancerId,
            clientId: offer.clientId,
            agreed_amount: offer.amount || project.budget,
            project,
            milestones,
          });

          const contract = await Contract.create({
            ProjectId: offer.projectId,
            FreelancerId: offer.freelancerId,
            ClientId: offer.clientId,
            agreed_amount: offer.amount || project.budget,
            status: "pending_freelancer",
            milestones: JSON.stringify(milestones),
            contract_document: contractDocument,
            terms: "Standard terms and conditions apply.",
          });

          contractId = contract.id;

          await NotificationService.createNotification({
            userId: offer.clientId,
            type: "offer_accepted",
            title: "Offer Accepted! 🎉",
            body: `${req.user.name} accepted your offer.`,
            data: { contractId: contract.id, offerId: offer.id },
          });
        }
      }

      res.json({
        success: true,
        message: `Offer ${status}`,
        contractId: contractId,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },
);

router.get(
  "/offers/unread-count",
  protect,
  authorizeRoles("freelancer"),
  async (req, res) => {
    try {
      const count = await Offer.count({
        where: {
          freelancerId: req.user.id,
          status: "pending",
          viewedAt: null,
        },
      });
      res.json({ success: true, count });
    } catch (error) {
      res.json({ success: true, count: 0 });
    }
  },
);
export default router;
