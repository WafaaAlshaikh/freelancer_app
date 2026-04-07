// ===== backend/src/controllers/advancedSearchController.js =====
import { Project, User, FreelancerProfile,ProjectAlert,
 } from "../models/index.js";
import { Op } from "sequelize";
import SavedFilter from "../models/SavedFilter.js";

export const advancedProjectSearch = async (req, res) => {
  try {
    const {
      query,
      category,
      minBudget,
      maxBudget,
      minDuration,
      maxDuration,
      skills,
      status = "open",
      sortBy = "relevance",
      page = 1,
      limit = 20,
    } = req.query;

    const where = { status };
    const offset = (parseInt(page) - 1) * parseInt(limit);

    if (query) {
      where[Op.or] = [
        { title: { [Op.like]: `%${query}%` } },
        { description: { [Op.like]: `%${query}%` } },
      ];
    }

    if (category && category !== "all") {
      where.category = category;
    }

    if (minBudget) {
      where.budget = { [Op.gte]: parseFloat(minBudget) };
    }
    if (maxBudget) {
      where.budget = { ...where.budget, [Op.lte]: parseFloat(maxBudget) };
    }

    if (minDuration) {
      where.duration = { [Op.gte]: parseInt(minDuration) };
    }
    if (maxDuration) {
      where.duration = { ...where.duration, [Op.lte]: parseInt(maxDuration) };
    }

    if (skills && skills.length > 0) {
      const skillsArray = skills.split(',');
      where[Op.and] = skillsArray.map(skill => ({
        skills: { [Op.like]: `%${skill}%` },
      }));
    }

    let order = [];
    switch (sortBy) {
      case "budget_high":
        order = [["budget", "DESC"]];
        break;
      case "budget_low":
        order = [["budget", "ASC"]];
        break;
      case "newest":
        order = [["createdAt", "DESC"]];
        break;
      case "oldest":
        order = [["createdAt", "ASC"]];
        break;
      case "duration_short":
        order = [["duration", "ASC"]];
        break;
      case "duration_long":
        order = [["duration", "DESC"]];
        break;
      default:
        order = [["createdAt", "DESC"]];
    }

    const { count, rows } = await Project.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order,
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      projects: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
      query: req.query,
    });
  } catch (error) {
    console.error("Error in advanced search:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const saveSearchFilter = async (req, res) => {
  try {
    const { name, filterData, isDefault } = req.body;
    const userId = req.user.id;

    if (isDefault) {
      await SavedFilter.update(
        { is_default: false },
        { where: { user_id: userId, is_default: true } }
      );
    }

    const savedFilter = await SavedFilter.create({
      user_id: userId,
      name,
      filter_data: filterData,
      is_default: isDefault || false,
    });

    res.json({
      success: true,
      message: "Filter saved successfully",
      filter: savedFilter,
    });
  } catch (error) {
    console.error("Error saving filter:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getSavedFilters = async (req, res) => {
  try {
    const userId = req.user.id;

    const filters = await SavedFilter.findAll({
      where: { user_id: userId },
      order: [["is_default", "DESC"], ["created_at", "DESC"]],
    });

    res.json({
      success: true,
      filters,
    });
  } catch (error) {
    console.error("Error getting saved filters:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const deleteSavedFilter = async (req, res) => {
  try {
    const { filterId } = req.params;
    const userId = req.user.id;

    const deleted = await SavedFilter.destroy({
      where: { id: filterId, user_id: userId },
    });

    if (deleted === 0) {
      return res.status(404).json({ success: false, message: "Filter not found" });
    }

    res.json({
      success: true,
      message: "Filter deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting filter:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const createProjectAlert = async (req, res) => {
  try {
    const {
      name,
      keywords,
      skills,
      minBudget,
      maxBudget,
      categories,
      notificationMethods,
    } = req.body;
    const userId = req.user.id;

    const alert = await ProjectAlert.create({
      user_id: userId,
      name,
      keywords: keywords || [],
      skills: skills || [],
      min_budget: minBudget,
      max_budget: maxBudget,
      categories: categories || [],
      notification_methods: notificationMethods || ["email", "push"],
      is_active: true,
    });

    res.json({
      success: true,
      message: "Project alert created successfully",
      alert,
    });
  } catch (error) {
    console.error("Error creating project alert:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getUserAlerts = async (req, res) => {
  try {
    const userId = req.user.id;

    const alerts = await ProjectAlert.findAll({
      where: { user_id: userId },
      order: [["created_at", "DESC"]],
    });

    res.json({
      success: true,
      alerts,
    });
  } catch (error) {
    console.error("Error getting alerts:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const deleteAlert = async (req, res) => {
  try {
    const { alertId } = req.params;
    const userId = req.user.id;

    const deleted = await ProjectAlert.destroy({
      where: { id: alertId, user_id: userId },
    });

    if (deleted === 0) {
      return res.status(404).json({ success: false, message: "Alert not found" });
    }

    res.json({
      success: true,
      message: "Alert deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting alert:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const toggleAlert = async (req, res) => {
  try {
    const { alertId } = req.params;
    const userId = req.user.id;

    const alert = await ProjectAlert.findOne({
      where: { id: alertId, user_id: userId },
    });

    if (!alert) {
      return res.status(404).json({ success: false, message: "Alert not found" });
    }

    await alert.update({ is_active: !alert.is_active });

    res.json({
      success: true,
      message: `Alert ${alert.is_active ? "activated" : "deactivated"}`,
      alert,
    });
  } catch (error) {
    console.error("Error toggling alert:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

