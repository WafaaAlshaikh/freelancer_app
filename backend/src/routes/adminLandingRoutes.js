// routes/adminLandingRoutes.js
import express from "express";
import {
  updateSection,
  getAllSections,
  getTestimonials,
  createTestimonial,
  updateTestimonial,
  deleteTestimonial,
  getStats,
  updateStat,
} from "../controllers/landingController.js";

const router = express.Router();

router.get("/sections", getAllSections);
router.put("/sections/:section", updateSection);

router.get("/testimonials", getTestimonials);
router.post("/testimonials", createTestimonial);
router.put("/testimonials/:id", updateTestimonial);
router.delete("/testimonials/:id", deleteTestimonial);

router.get("/stats", getStats);
router.put("/stats/:key", updateStat);

export default router;
