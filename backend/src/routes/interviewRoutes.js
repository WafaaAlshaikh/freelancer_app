import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  createInterviewInvitation,
  getUserInterviews,
  getInterviewById,
  respondToInterview,
  rescheduleInterview,
  addInterviewNotes,
  cancelInterview,
  getInterviewStats,
  createSmartInterviewInvitation,
  getSmartAnalytics,
  getTimeSuggestions,
  createGroupInterviewInvitation,
  addToCalendar,
  sendManualReminder,
  addPostInterviewFeedback,
  exportInterviewStats,
  compareFreelancers,
  getQuestionLibrary,
} from "../controllers/interviewController.js";

const router = express.Router();

router.use(protect);

router.post("/invite", createInterviewInvitation);
router.get("/my", getUserInterviews);
router.get("/stats", getInterviewStats);
router.get("/:invitationId", getInterviewById);
router.put("/:invitationId/respond", respondToInterview);
router.put("/:invitationId/reschedule", rescheduleInterview);
router.post("/:invitationId/notes", addInterviewNotes);
router.delete("/:invitationId/cancel", cancelInterview);

router.post("/smart-invite", createSmartInterviewInvitation);
router.get("/smart-analytics", getSmartAnalytics);
router.get("/time-suggestions", getTimeSuggestions);

router.post("/group-invite", protect, createGroupInterviewInvitation);
router.post("/:invitationId/add-to-calendar", protect, addToCalendar);
router.post("/:invitationId/send-reminder", protect, sendManualReminder);
router.post("/:invitationId/feedback", protect, addPostInterviewFeedback);
router.get("/export-stats", protect, exportInterviewStats);
router.post("/compare-freelancers", protect, compareFreelancers);
router.get("/question-library", protect, getQuestionLibrary);
export default router;
