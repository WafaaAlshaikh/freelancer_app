// routes/landingRoutes.js
import express from "express";
import {
  getLandingPage,
  getTestimonials,
  getStats,
} from "../controllers/landingController.js";

const router = express.Router();

router.get("/", getLandingPage);
router.get("/testimonials", getTestimonials);
router.get("/stats", getStats);

export default router;