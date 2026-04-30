// controllers/ratingController.js
import {
  Rating,
  Contract,
  User,
  FreelancerProfile,
  Project,
  ReviewHelpful,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "../services/notificationService.js";

export const addRating = async (req, res) => {
  try {
    const { contractId, rating, comment } = req.body;
    const fromUserId = req.user.id;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        message: "Rating must be between 1 and 5",
      });
    }

    const contract = await Contract.findByPk(contractId, {
      include: [
        { model: Project, attributes: ["title"] },
        { model: User, as: "client", attributes: ["id", "name"] },
        { model: User, as: "freelancer", attributes: ["id", "name"] },
      ],
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.status !== "completed") {
      return res.status(400).json({
        message: "You can only rate completed contracts",
      });
    }

    let toUserId;
    let role;

    if (contract.ClientId === fromUserId) {
      toUserId = contract.FreelancerId;
      role = "client";
    } else if (contract.FreelancerId === fromUserId) {
      toUserId = contract.ClientId;
      role = "freelancer";
    } else {
      return res.status(403).json({
        message: "You are not part of this contract",
      });
    }

    const existingRating = await Rating.findOne({
      where: { contractId, fromUserId },
    });

    if (existingRating) {
      return res.status(400).json({
        message: "You have already rated this contract",
      });
    }

    const newRating = await Rating.create({
      contractId,
      fromUserId,
      toUserId,
      rating,
      comment: comment?.trim() || null,
      role,
      isVerifiedPurchase: true,
    });

    if (role === "client") {
      await updateFreelancerRating(toUserId);
    } else if (role === "freelancer") {
      await updateClientRating(toUserId);
    }

    await updateUserRating(toUserId);

    const bothRated = await checkBothRated(contractId);

    const ratedUser = await User.findByPk(toUserId);
    const rater = await User.findByPk(fromUserId);

    await NotificationService.createNotification({
      userId: toUserId,
      type: "new_review",
      title: "New Review Received ⭐",
      body: `${rater.name} rated you ${rating}/5 for "${contract.Project.title}"`,
      data: {
        contractId: contract.id,
        rating: rating,
        screen: "contract",
      },
    });

    res.status(201).json({
      message: "✅ Rating added successfully",
      rating: newRating,
      bothRated,
    });
  } catch (err) {
    console.error("Error in addRating:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

async function updateFreelancerRating(freelancerId) {
  try {
    const ratings = await Rating.findAll({
      where: {
        toUserId: freelancerId,
        role: "client",
      },
      attributes: ["rating"],
    });

    if (ratings.length === 0) return;

    const averageRating =
      ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length;

    await FreelancerProfile.update(
      { rating: averageRating },
      { where: { UserId: freelancerId } },
    );

    console.log(
      `✅ Updated freelancer ${freelancerId} rating to ${averageRating}`,
    );
  } catch (err) {
    console.error("Error updating freelancer rating:", err);
  }
}

async function checkBothRated(contractId) {
  const ratings = await Rating.findAll({
    where: { contractId },
  });

  const hasClientRating = ratings.some((r) => r.role === "client");
  const hasFreelancerRating = ratings.some((r) => r.role === "freelancer");

  return {
    bothRated: hasClientRating && hasFreelancerRating,
    clientRated: hasClientRating,
    freelancerRated: hasFreelancerRating,
  };
}

export const getContractRatings = async (req, res) => {
  try {
    const { contractId } = req.params;

    const ratings = await Rating.findAll({
      where: { contractId },
      include: [
        {
          model: User,
          as: "fromUser",
          attributes: ["id", "name", "avatar"],
        },
      ],
    });

    res.json(ratings);
  } catch (err) {
    console.error("Error in getContractRatings:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUserRatings = async (req, res) => {
  try {
    const { userId } = req.params;

    const ratings = await Rating.findAll({
      where: { toUserId: userId },
      include: [
        {
          model: User,
          as: "fromUser",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: Contract,
          include: [
            {
              model: Project,
              attributes: ["id", "title"],
            },
          ],
        },
      ],
      order: [["createdAt", "DESC"]],
    });

    const totalRatings = ratings.length;
    const averageRating =
      totalRatings > 0
        ? ratings.reduce((sum, r) => sum + r.rating, 0) / totalRatings
        : 0;

    const distribution = {
      1: ratings.filter((r) => r.rating === 1).length,
      2: ratings.filter((r) => r.rating === 2).length,
      3: ratings.filter((r) => r.rating === 3).length,
      4: ratings.filter((r) => r.rating === 4).length,
      5: ratings.filter((r) => r.rating === 5).length,
    };

    res.json({
      ratings,
      stats: {
        total: totalRatings,
        average: averageRating,
        distribution,
      },
    });
  } catch (err) {
    console.error("Error in getUserRatings:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const checkCanRate = async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const isClient = contract.ClientId === userId;
    const isFreelancer = contract.FreelancerId === userId;

    if (!isClient && !isFreelancer) {
      return res.json({ canRate: false, reason: "Not part of contract" });
    }

    if (contract.status !== "completed") {
      return res.json({ canRate: false, reason: "Contract not completed" });
    }

    const existingRating = await Rating.findOne({
      where: { contractId, fromUserId: userId },
    });

    if (existingRating) {
      return res.json({ canRate: false, reason: "Already rated" });
    }

    res.json({
      canRate: true,
      role: isClient ? "client" : "freelancer",
    });
  } catch (err) {
    console.error("Error in checkCanRate:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const addReviewReply = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { reply } = req.body;
    const userId = req.user.id;

    if (!reply || reply.trim().length < 3) {
      return res.status(400).json({
        success: false,
        message: "Reply must be at least 3 characters",
      });
    }

    const review = await Rating.findByPk(reviewId);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: "Review not found",
      });
    }

    if (review.toUserId !== userId) {
      return res.status(403).json({
        success: false,
        message: "Only the rated user can reply",
      });
    }

    await review.update({
      reply: reply.trim(),
      repliedAt: new Date(),
    });

    await NotificationService.createNotification({
      userId: review.fromUserId,
      type: "review_reply",
      title: "Reply to your review 📝",
      body: `Someone replied to your review: "${reply.substring(0, 50)}..."`,
      data: {
        reviewId: review.id,
        contractId: review.contractId,
        screen: "review_details",
      },
    });

    res.json({
      success: true,
      message: "Reply added successfully",
      reply: review.reply,
      repliedAt: review.repliedAt,
    });
  } catch (error) {
    console.error("Error in addReviewReply:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const markReviewHelpful = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;

    const review = await Rating.findByPk(reviewId);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: "Review not found",
      });
    }

    if (review.fromUserId === userId) {
      return res.status(400).json({
        success: false,
        message: "You cannot mark your own review as helpful",
      });
    }

    const existing = await ReviewHelpful.findOne({
      where: { reviewId, userId },
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "You already marked this review as helpful",
      });
    }

    await ReviewHelpful.create({ reviewId, userId });

    const newCount = (review.helpfulCount || 0) + 1;
    await review.update({ helpfulCount: newCount });

    res.json({
      success: true,
      message: "Marked as helpful",
      helpfulCount: newCount,
    });
  } catch (error) {
    console.error("Error in markReviewHelpful:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

async function updateUserRating(userId) {
  try {
    const ratings = await Rating.findAll({
      where: { toUserId: userId },
      attributes: ["rating"],
    });

    if (ratings.length === 0) return;

    const averageRating =
      ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length;

    await User.update({ rating: averageRating }, { where: { id: userId } });

    console.log(`✅ Updated user ${userId} rating to ${averageRating}`);
  } catch (err) {
    console.error("Error updating user rating:", err);
  }
}

async function updateClientRating(clientId) {
  try {
    const ratings = await Rating.findAll({
      where: { toUserId: clientId, role: "freelancer" },
      attributes: ["rating"],
    });

    if (ratings.length === 0) return;

    const averageRating =
      ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length;

    await ClientProfile.update(
      { rating: averageRating },
      { where: { UserId: clientId } },
    );

    console.log(`✅ Updated client ${clientId} rating to ${averageRating}`);
  } catch (err) {
    console.error("Error updating client rating:", err);
  }
}
