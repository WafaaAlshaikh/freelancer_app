import Portfolio from "../models/Portfolio.js";
import { User, WorkSubmission, Contract, Project } from "../models/index.js";
import FreelancerProfile from "../models/FreelancerProfile.js";
import multer from "multer";
import path from "path";
import fs from "fs";

const parseMilestonesValue = (raw) => {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  if (typeof raw === "string") {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return parsed;
      if (typeof parsed === "string") {
        const reparsed = JSON.parse(parsed);
        return Array.isArray(reparsed) ? reparsed : [];
      }
      return [];
    } catch {
      return [];
    }
  }
  return [];
};

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = "uploads/portfolio";
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      `portfolio-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`,
    );
  },
});

export const uploadPortfolioImages = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp|mp4|avi|mov|pdf|doc|docx/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase(),
    );
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      cb(null, true);
    } else {
      cb(new Error("Only images, videos, and documents are allowed"));
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 },
}).array("images", 10);

export const createPortfolio = async (req, res) => {
  try {
    const {
      title,
      description,
      project_url,
      github_url,
      technologies,
      completion_date,
      category,
      client_name,
      project_type,
      team_size,
      role,
    } = req.body;

    const imageUrls = req.files
      ? req.files.map((file) => `/uploads/portfolio/${file.filename}`)
      : [];

    const portfolio = await Portfolio.create({
      UserId: req.user.id,
      title,
      description,
      images: JSON.stringify(imageUrls),
      project_url,
      github_url,
      technologies: JSON.stringify(technologies || []),
      completion_date: completion_date || new Date(),
      category: category || "other",
      client_name: client_name || null,
      project_type: project_type || "personal",
      team_size: team_size ? parseInt(team_size) : null,
      role: role || null,
      featured: false,
      views: 0,
      likes: 0,
    });

    await FreelancerProfile.increment("portfolio_items_count", {
      where: { UserId: req.user.id },
    });

    try {
      const { default: ProfileCompletionService } = await import(
        "../services/profileCompletionService.js"
      );
      await ProfileCompletionService.calculateFreelancerProfileCompletion(
        req.user.id,
      );
    } catch (e) {
      console.warn("Profile completion update skipped:", e.message);
    }

    res.status(201).json({
      message: "✅ Portfolio item created successfully",
      portfolio,
    });
  } catch (err) {
    console.error("Error creating portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUserPortfolio = async (req, res) => {
  try {
    const { userId } = req.params;
    const portfolio = await Portfolio.findAll({
      where: { UserId: userId },
      order: [
        ["completion_date", "DESC"],
        ["featured", "DESC"],
      ],
    });

    const parsedPortfolio = portfolio.map((item) => ({
      ...item.toJSON(),
      images: JSON.parse(item.images || "[]"),
      technologies: JSON.parse(item.technologies || "[]"),
    }));

    res.json(parsedPortfolio);
  } catch (err) {
    console.error("Error getting portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updatePortfolio = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findOne({
      where: { id, UserId: req.user.id },
    });

    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }

    const updateData = { ...req.body };

    if (updateData.technologies && Array.isArray(updateData.technologies)) {
      updateData.technologies = JSON.stringify(updateData.technologies);
    }

    await portfolio.update(updateData);

    res.json({
      message: "✅ Portfolio updated successfully",
      portfolio,
    });
  } catch (err) {
    console.error("Error updating portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const deletePortfolio = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findOne({
      where: { id, UserId: req.user.id },
    });

    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }

    const images = JSON.parse(portfolio.images || "[]");
    images.forEach((imageUrl) => {
      const filePath = path.join(process.cwd(), imageUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    });

    await portfolio.destroy();

    await FreelancerProfile.decrement("portfolio_items_count", {
      where: { UserId: req.user.id },
    });

    try {
      const { default: ProfileCompletionService } = await import(
        "../services/profileCompletionService.js"
      );
      await ProfileCompletionService.calculateFreelancerProfileCompletion(
        req.user.id,
      );
    } catch (e) {
      console.warn("Profile completion update skipped:", e.message);
    }

    res.json({ message: "✅ Portfolio item deleted successfully" });
  } catch (err) {
    console.error("Error deleting portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const createPortfolioFromSubmission = async (req, res) => {
  try {
    const { submissionId } = req.body;
    const freelancerId = req.user.id;

    const submission = await WorkSubmission.findOne({
      where: { id: submissionId, freelancer_id: freelancerId },
      include: [{ model: Contract, include: [{ model: Project }] }],
    });

    if (!submission) {
      return res.status(404).json({ success: false, message: "Submission not found" });
    }

    const milestones = Array.isArray(submission.Contract?.milestones)
      ? submission.Contract.milestones
      : parseMilestonesValue(submission.Contract?.milestones);
    const milestoneIndex = submission.milestone_index;
    const milestoneStatus =
      milestoneIndex !== null &&
      milestoneIndex !== undefined &&
      milestones[milestoneIndex]
        ? milestones[milestoneIndex]?.status
        : null;
    const canAdd =
      submission.status === "approved" ||
      submission.Contract?.status === "completed" ||
      milestoneStatus === "approved" ||
      milestoneStatus === "completed";

    if (!canAdd) {
      return res
        .status(400)
        .json({
          success: false,
          message:
            "Submission is not approved yet. Approve the deliverable/milestone first.",
        });
    }

    const markerUrl = `submission://${submission.id}`;
    const existing = await Portfolio.findOne({
      where: { UserId: freelancerId, project_url: markerUrl },
    });
    if (existing) {
      return res.json({
        success: true,
        message: "Already added to portfolio",
        portfolio: existing,
      });
    }

    const files = Array.isArray(submission.files) ? submission.files : [];
    const imageFiles = files.filter((url) =>
      /\.(png|jpg|jpeg|webp|gif)$/i.test(url || ""),
    );
    const projectSkills = submission.Contract?.Project?.skills || [];

    const portfolio = await Portfolio.create({
      UserId: freelancerId,
      title: submission.title || submission.Contract?.Project?.title || "Delivered Project",
      description:
        submission.description ||
        `Delivered for project "${submission.Contract?.Project?.title || submission.Contract?.ProjectId}".`,
      images: JSON.stringify(imageFiles),
      project_url: markerUrl,
      github_url: (submission.links || [])[0] || null,
      technologies: JSON.stringify(projectSkills),
      completion_date: submission.approved_at || new Date(),
      category: submission.Contract?.Project?.category || "other",
      client_name: submission.Contract?.client?.name || null,
      project_type: "client_work",
      role: "freelancer",
      featured: false,
      views: 0,
      likes: 0,
    });

    await FreelancerProfile.increment("portfolio_items_count", {
      where: { UserId: freelancerId },
    });

    res.status(201).json({
      success: true,
      message: "Added to portfolio",
      portfolio,
    });
  } catch (err) {
    console.error("Error creating portfolio from submission:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const createPortfolioFromContractMilestone = async (req, res) => {
  try {
    const { contractId, milestoneIndex } = req.body;
    const freelancerId = req.user.id;

    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: freelancerId },
      include: [{ model: Project }],
    });

    if (!contract) {
      return res.status(404).json({ success: false, message: "Contract not found" });
    }

    const milestones = parseMilestonesValue(contract.milestones);
    const index =
      milestoneIndex === null || milestoneIndex === undefined
        ? null
        : Number(milestoneIndex);

    let canAdd = contract.status === "completed";
    let milestoneTitle = "Delivered milestone";
    let milestoneAmount = null;

    if (index !== null && !Number.isNaN(index) && milestones[index]) {
      const m = milestones[index];
      milestoneTitle = m.title || `Milestone #${index + 1}`;
      milestoneAmount = m.amount || null;
      canAdd =
        canAdd ||
        m.status === "approved" ||
        m.status === "completed";
    }

    if (!canAdd) {
      return res.status(400).json({
        success: false,
        message: "Milestone/contract is not approved yet",
      });
    }

    const markerUrl =
      index !== null ? `contract://${contract.id}/milestone://${index}` : `contract://${contract.id}`;
    const existing = await Portfolio.findOne({
      where: { UserId: freelancerId, project_url: markerUrl },
    });

    if (existing) {
      return res.json({
        success: true,
        message: "Already added to portfolio",
        portfolio: existing,
      });
    }

    const projectSkills = contract.Project?.skills || [];
    const portfolio = await Portfolio.create({
      UserId: freelancerId,
      title:
        index !== null
          ? `${milestoneTitle} (${contract.Project?.title || "Project"})`
          : contract.Project?.title || "Delivered Project",
      description:
        index !== null
          ? `Approved milestone delivered for "${contract.Project?.title || "project"}".`
          : `Completed contract delivery for "${contract.Project?.title || "project"}".`,
      images: JSON.stringify([]),
      project_url: markerUrl,
      github_url: null,
      technologies: JSON.stringify(projectSkills),
      completion_date: contract.end_date || new Date(),
      category: contract.Project?.category || "other",
      client_name: null,
      project_type: "client_work",
      role: "freelancer",
      featured: false,
      views: 0,
      likes: 0,
    });

    await FreelancerProfile.increment("portfolio_items_count", {
      where: { UserId: freelancerId },
    });

    return res.status(201).json({
      success: true,
      message: "Added to portfolio",
      portfolio,
    });
  } catch (err) {
    console.error("Error creating portfolio from contract milestone:", err);
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: err.message,
    });
  }
};

export const toggleFeatured = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findOne({
      where: { id, UserId: req.user.id },
    });

    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }

    await portfolio.update({ featured: !portfolio.featured });

    res.json({
      message: `✅ Portfolio item ${portfolio.featured ? "featured" : "unfeatured"} successfully`,
      portfolio,
    });
  } catch (err) {
    console.error("Error toggling featured:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const incrementViews = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findByPk(id);

    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }

    await portfolio.increment("views");

    res.json({
      message: "✅ Views incremented",
      views: portfolio.views + 1,
    });
  } catch (err) {
    console.error("Error incrementing views:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const toggleLike = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const portfolio = await Portfolio.findByPk(id);
    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }

    const likes = JSON.parse(portfolio.likes || "[]");
    const userIndex = likes.indexOf(userId);

    if (userIndex > -1) {
      likes.splice(userIndex, 1);
      await portfolio.update({ likes: JSON.stringify(likes) });

      res.json({
        message: "✅ Portfolio item unliked",
        liked: false,
        totalLikes: likes.length,
      });
    } else {
      likes.push(userId);
      await portfolio.update({ likes: JSON.stringify(likes) });

      res.json({
        message: "✅ Portfolio item liked",
        liked: true,
        totalLikes: likes.length,
      });
    }
  } catch (err) {
    console.error("Error toggling like:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getPortfolioAnalytics = async (req, res) => {
  try {
    const { userId } = req.params;

    const portfolioItems = await Portfolio.findAll({
      where: { UserId: userId },
      attributes: ["category", "views", "likes", "completion_date"],
    });

    const totalViews = portfolioItems.reduce(
      (sum, item) => sum + item.views,
      0,
    );
    const totalLikes = portfolioItems.reduce(
      (sum, item) => sum + JSON.parse(item.likes || "[]").length,
      0,
    );
    const totalItems = portfolioItems.length;

    const categoryStats = {};
    portfolioItems.forEach((item) => {
      if (!categoryStats[item.category]) {
        categoryStats[item.category] = {
          count: 0,
          views: 0,
          likes: 0,
        };
      }
      categoryStats[item.category].count++;
      categoryStats[item.category].views += item.views;
      categoryStats[item.category].likes += JSON.parse(
        item.likes || "[]",
      ).length;
    });

    res.json({
      totalViews,
      totalLikes,
      totalItems,
      categoryStats,
      averageViewsPerItem:
        totalItems > 0 ? Math.round(totalViews / totalItems) : 0,
      averageLikesPerItem:
        totalItems > 0 ? Math.round(totalLikes / totalItems) : 0,
    });
  } catch (err) {
    console.error("Error getting portfolio analytics:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
