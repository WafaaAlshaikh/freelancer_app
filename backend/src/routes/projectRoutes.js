// routes/projectRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { getAllProjects, getProjectById } from "../controllers/projectController.js";

const router = express.Router();

router.get("/", protect, getAllProjects);
router.get("/:id", protect, getProjectById);

export default router;