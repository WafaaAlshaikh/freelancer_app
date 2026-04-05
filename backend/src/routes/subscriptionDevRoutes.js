// backend/src/routes/subscriptionDevRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { manualActivateSubscription } from "../controllers/subscriptionDevController.js";

const router = express.Router();

router.post("/manual-activate", protect, manualActivateSubscription);

export default router;
