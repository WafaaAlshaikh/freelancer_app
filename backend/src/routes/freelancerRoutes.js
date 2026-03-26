// routes/freelancerRoutes.js 
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getProfile,
  updateProfile,
  getProposals,
  getProjects,
  getWallet,
  getMessages,
  uploadAndAnalyzeCV,
  uploadCV,
  updateLocation,
  uploadAvatar,
  getSuggestedProjects,
  getFreelancerStats,
  getFreelancerContracts
} from "../controllers/freelancerController.js";
import multer from "multer";
import path from "path";
import {
  createPortfolio,
  getUserPortfolio,
  updatePortfolio,
  deletePortfolio,
  uploadPortfolioImages
} from "../controllers/portfolioController.js";

import {
  getWallet as getFreelancerWallet,
  requestWithdrawal as requestFreelancerWithdrawal,
  updateMilestoneProgress,
} from "../controllers/freelancerController.js";


const router = express.Router();

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/avatars/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `avatar-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const uploadAvatarMiddleware = multer({
  storage: avatarStorage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
  limits: { fileSize: 2 * 1024 * 1024 } 
}).single('avatar');

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

router.get("/wallet", getWallet);

router.get("/messages", getMessages);

router.get("/contracts", getFreelancerContracts);

router.post("/portfolio", uploadPortfolioImages, createPortfolio);
router.get("/portfolio/:userId", getUserPortfolio);
router.put("/portfolio/:id", updatePortfolio);
router.delete("/portfolio/:id", deletePortfolio);

router.get("/wallet", getFreelancerWallet);
router.post("/wallet/withdraw", requestFreelancerWithdrawal);

router.put("/contracts/:contractId/milestones/:milestoneIndex/progress", updateMilestoneProgress);
export default router;