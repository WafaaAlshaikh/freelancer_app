// routes/adminRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  updateUserStatus,
  verifyUser,
  getAllProjects,
  deleteProject,
  getAllContracts,
  resolveDispute,
} from "../controllers/adminController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("admin"));

router.get("/dashboard/stats", getDashboardStats);

router.get("/users", getAllUsers);
router.get("/users/:userId", getUserDetails);
router.put("/users/:userId/status", updateUserStatus);
router.put("/users/:userId/verify", verifyUser);

router.get("/projects", getAllProjects);
router.delete("/projects/:projectId", deleteProject);

router.get("/contracts", getAllContracts);
router.post("/contracts/:contractId/resolve", resolveDispute);

export default router;