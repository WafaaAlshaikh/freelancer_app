import Portfolio from "../models/Portfolio.js";
import { User } from "../models/index.js";
import FreelancerProfile from "../models/FreelancerProfile.js";
import multer from "multer";
import path from "path";
import fs from "fs";

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
      where: { user_id: req.user.id },
    });

    const ProfileCompletionService =
      require("../services/profileCompletionService.js").default;
    await ProfileCompletionService.calculateFreelancerProfileCompletion(
      req.user.id,
    );

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
      where: { user_id: req.user.id },
    });

    const ProfileCompletionService =
      require("../services/profileCompletionService.js").default;
    await ProfileCompletionService.calculateFreelancerProfileCompletion(
      req.user.id,
    );

    res.json({ message: "✅ Portfolio item deleted successfully" });
  } catch (err) {
    console.error("Error deleting portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
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
