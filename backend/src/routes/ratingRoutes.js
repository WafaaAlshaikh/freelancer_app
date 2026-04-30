// routes/ratingRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  addRating,
  getContractRatings,
  getUserRatings,
  checkCanRate,
  addReviewReply,
  markReviewHelpful,
} from "../controllers/ratingController.js";

const router = express.Router();

router.use(protect);

router.post("/", addRating);

router.get("/can-rate/:contractId", checkCanRate);

router.get("/contract/:contractId", getContractRatings);

router.get("/user/:userId", getUserRatings);

router.post("/:reviewId/reply", addReviewReply);
router.post("/:reviewId/helpful", markReviewHelpful);

router.post("/:id/helpful", async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const rating = await Rating.findByPk(id);
    if (!rating) {
      return res.status(404).json({ message: "Rating not found" });
    }

    let helpfulVotes = rating.helpfulVotes
      ? JSON.parse(rating.helpfulVotes)
      : [];
    if (!helpfulVotes.includes(userId)) {
      helpfulVotes.push(userId);
      await rating.update({ helpfulVotes: JSON.stringify(helpfulVotes) });
    }

    res.json({ success: true, count: helpfulVotes.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post("/:id/reply", async (req, res) => {
  try {
    const { id } = req.params;
    const { reply } = req.body;
    const userId = req.user.id;

    const rating = await Rating.findByPk(id);
    if (!rating) {
      return res.status(404).json({ message: "Rating not found" });
    }

    await rating.update({
      reply: reply,
      repliedAt: new Date(),
      repliedBy: userId,
    });

    res.json({ success: true, rating });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/analytics/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const ratings = await Rating.findAll({
      where: { toUserId: userId },
    });

    const total = ratings.length;
    const average =
      total > 0 ? ratings.reduce((sum, r) => sum + r.rating, 0) / total : 0;

    const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    ratings.forEach((r) => distribution[r.rating]++);

    const monthlyStats = {};
    ratings.forEach((r) => {
      const month = r.createdAt.toISOString().slice(0, 7);
      if (!monthlyStats[month]) monthlyStats[month] = { count: 0, sum: 0 };
      monthlyStats[month].count++;
      monthlyStats[month].sum += r.rating;
    });

    res.json({
      stats: {
        average,
        total,
        distribution,
        monthlyStats,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
