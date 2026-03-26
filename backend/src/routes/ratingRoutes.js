// routes/ratingRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  addRating,
  getContractRatings,
  getUserRatings,
  checkCanRate
} from "../controllers/ratingController.js";

const router = express.Router();

router.use(protect);

router.post("/", addRating);

router.get("/can-rate/:contractId", checkCanRate);

router.get("/contract/:contractId", getContractRatings);

router.get("/user/:userId", getUserRatings);

export default router;