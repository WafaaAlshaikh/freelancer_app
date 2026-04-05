// backend/src/routes/featureRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  purchaseFeature,
  getFeaturePrices,
} from "../controllers/featureController.js";

const router = express.Router();

router.post("/purchase", protect, purchaseFeature);
router.get("/prices", protect, getFeaturePrices);

export default router;
