// ===== backend/src/controllers/favoriteController.js =====
import { UserFavorite, Project, User } from "../models/index.js";
import { Op } from "sequelize";

export const addToFavorites = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.id;

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res
        .status(404)
        .json({ success: false, message: "Project not found" });
    }

    const existing = await UserFavorite.findOne({
      where: { user_id: userId, project_id: projectId },
    });

    if (existing) {
      return res
        .status(400)
        .json({ success: false, message: "Already in favorites" });
    }

    const favorite = await UserFavorite.create({
      user_id: userId,
      project_id: projectId,
    });

    await project.increment("favorites_count");

    res.json({
      success: true,
      message: "Added to favorites",
      favorite,
    });
  } catch (error) {
    console.error("Error adding to favorites:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const removeFromFavorites = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.id;

    const deleted = await UserFavorite.destroy({
      where: { user_id: userId, project_id: projectId },
    });

    if (deleted === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Not in favorites" });
    }

    await Project.decrement("favorites_count", { where: { id: projectId } });

    res.json({
      success: true,
      message: "Removed from favorites",
    });
  } catch (error) {
    console.error("Error removing from favorites:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getUserFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const { count, rows } = await UserFavorite.findAndCountAll({
      where: { user_id: userId },
      include: [
        {
          model: Project,
          include: [
            {
              model: User,
              as: "client",
              attributes: ["id", "name", "avatar"],
            },
          ],
        },
      ],
      order: [["created_at", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    const favorites = rows.map((fav) => ({
      id: fav.id,
      project: fav.Project,
      addedAt: fav.created_at,
    }));

    res.json({
      success: true,
      favorites,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (error) {
    console.error("Error getting favorites:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const checkFavorite = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.id;

    const favorite = await UserFavorite.findOne({
      where: { user_id: userId, project_id: projectId },
    });

    res.json({
      success: true,
      isFavorite: !!favorite,
    });
  } catch (error) {
    console.error("Error checking favorite:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getRecentProjects = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const projects = await Project.findAll({
      where: { status: "open" },
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
    });

    const userId = req.user.id;
    const favoriteProjects = await UserFavorite.findAll({
      where: { user_id: userId },
      attributes: ["project_id"],
    });
    const favoriteIds = new Set(favoriteProjects.map((f) => f.project_id));

    const projectsWithFavorite = projects.map((project) => ({
      ...project.toJSON(),
      isFavorite: favoriteIds.has(project.id),
    }));

    res.json({
      success: true,
      projects: projectsWithFavorite,
    });
  } catch (error) {
    console.error("Error getting recent projects:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
