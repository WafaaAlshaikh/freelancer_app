// routes/githubRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  connectGithubRepo,
  getGithubCommits,
  githubWebhook
} from "../controllers/githubController.js";

const router = express.Router();

router.use(protect);

router.post("/connect", connectGithubRepo);
router.get("/commits/:contractId", getGithubCommits);
router.post("/webhook/:contractId", githubWebhook);

export default router;