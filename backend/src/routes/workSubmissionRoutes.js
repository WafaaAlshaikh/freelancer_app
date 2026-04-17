// ===== backend/src/routes/workSubmissionRoutes.js =====
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  submitWork,
  approveWork,
  requestRevision,
  getContractSubmissions,
  uploadWorkFile,
} from "../controllers/workSubmissionController.js";

const router = express.Router();

router.use(protect);

router.post("/", submitWork);
router.post("/:submissionId/approve", approveWork);
router.post("/:submissionId/revision", requestRevision);
router.get("/contract/:contractId", getContractSubmissions);
router.post("/upload", uploadWorkFile);

export default router;
