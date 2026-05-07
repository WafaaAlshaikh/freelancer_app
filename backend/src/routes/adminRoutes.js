// routes/adminRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardStats,
  getAllUsers,
  createUser,
  resendAccountEmail,
  getUserDetails,
  updateUserStatus,
  verifyUser,
  getAllProjects,
  deleteProject,
  getAllContracts,
  resolveDispute,
  getAllDisputes,
  getDisputeDetails,
  resolveDisputeAdmin,
  rejectDispute,
} from "../controllers/adminController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("admin"));

router.get("/dashboard/stats", getDashboardStats);

router.post("/users", createUser);
router.post("/users/:userId/resend-email", resendAccountEmail);
router.get("/users", getAllUsers);
router.get("/users/:userId", getUserDetails);
router.put("/users/:userId/status", updateUserStatus);
router.put("/users/:userId/verify", verifyUser);

router.get("/projects", getAllProjects);
router.delete("/projects/:projectId", deleteProject);

router.get("/contracts", getAllContracts);
router.post("/contracts/:contractId/resolve", resolveDispute);

router.get("/disputes", getAllDisputes);
router.get("/disputes/:disputeId", getDisputeDetails);
router.post("/disputes/:disputeId/resolve", resolveDisputeAdmin);
router.post("/disputes/:disputeId/reject", rejectDispute);

export default router;