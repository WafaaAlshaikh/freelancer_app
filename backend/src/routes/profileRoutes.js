import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getFreelancerPublicProfile,
  getMyFreelancerProfile,
  updateFreelancerProfile,
  getClientPublicProfile,
  getMyClientProfile,
  updateClientProfile,
  uploadProfileImages,
  uploadCompanyLogo,
  handleCompanyLogoUpload,
  searchFreelancers,
} from "../controllers/profileController.js";

const router = express.Router();

router.get("/freelancer/:userId", protect, getFreelancerPublicProfile);
router.get("/client/:userId", protect, getClientPublicProfile);
router.get("/freelancers/search", protect, searchFreelancers);

router.get(
  "/me/freelancer",
  protect,
  authorizeRoles("freelancer"),
  getMyFreelancerProfile,
);
router.put(
  "/me/freelancer",
  protect,
  authorizeRoles("freelancer"),
  uploadProfileImages,
  updateFreelancerProfile,
);

router.get("/me/client", protect, authorizeRoles("client"), getMyClientProfile);
router.put(
  "/me/client",
  protect,
  authorizeRoles("client"),
  uploadProfileImages,
  updateClientProfile,
);
router.post(
  "/me/client/logo",
  protect,
  authorizeRoles("client"),
  uploadCompanyLogo,
  handleCompanyLogoUpload,
);
export default router;
