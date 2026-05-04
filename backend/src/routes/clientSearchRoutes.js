// routes/clientSearchRoutes.js
import express from "express";
import { protect, authorizeRoles } from "../middleware/authMiddleware.js";
import {
  searchFreelancers,
  getTopFreelancers,
  getFreelancerPreview,
  getFreelancerStatsForClient,
  compareFreelancers,
} from "../controllers/freelancerController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("client"));

router.get("/", searchFreelancers);
router.get("/top", getTopFreelancers);
router.post("/compare", compareFreelancers);
router.get("/:id/preview", getFreelancerPreview);
router.get("/:id/stats", getFreelancerStatsForClient);

export default router;
