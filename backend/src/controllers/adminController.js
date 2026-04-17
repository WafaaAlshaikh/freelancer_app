// controllers/adminController.js
import { User, Project, Contract, FreelancerProfile, ClientProfile, Rating, Transaction, sequelize } from "../models/index.js";
import { Op } from "sequelize";

export const getDashboardStats = async (req, res) => {
  try {
    console.log('📊 Fetching admin dashboard stats...');
    
    const [
      totalUsers,
      totalFreelancers,
      totalClients,
      totalProjects,
      totalContracts,
      totalEarnings,
      pendingProjects,
      activeContracts,
      completedContracts,
      pendingDisputes,
    ] = await Promise.all([
      User.count(),
      User.count({ where: { role: "freelancer" } }),
      User.count({ where: { role: "client" } }),
      Project.count(),
      Contract.count(),
      Transaction.sum("amount", { where: { type: "platform_fee", status: "completed" } }),
      Project.count({ where: { status: "pending_review" } }),
      Contract.count({ where: { status: "active" } }),
      Contract.count({ where: { status: "completed" } }),
      Contract.count({ where: { status: "disputed" } }),
    ]);

    const recentUsers = await User.findAll({
      where: {
        createdAt: {
          [Op.gte]: new Date(new Date() - 7 * 24 * 60 * 60 * 1000),
        },
      },
      attributes: ["id", "name", "email", "role", "avatar", "createdAt", "account_status"],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const recentProjects = await Project.findAll({
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 10,
    });

    const monthlyStats = await sequelize.query(`
      SELECT 
        DATE_FORMAT(createdAt, '%Y-%m') as month,
        COUNT(*) as users,
        SUM(CASE WHEN role = 'freelancer' THEN 1 ELSE 0 END) as freelancers,
        SUM(CASE WHEN role = 'client' THEN 1 ELSE 0 END) as clients
      FROM Users
      WHERE createdAt >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(createdAt, '%Y-%m')
      ORDER BY month ASC
    `);

    res.json({
      success: true,
      stats: {
        totalUsers,
        totalFreelancers,
        totalClients,
        totalProjects,
        totalContracts,
        totalEarnings: totalEarnings || 0,
        pendingProjects,
        activeContracts,
        completedContracts,
        pendingDisputes,
      },
      recentUsers: recentUsers.map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        createdAt: user.createdAt,
        accountStatus: user.account_status,
      })),
      recentProjects,
      monthlyStats: monthlyStats[0] || [],
    });
    
    console.log('✅ Dashboard stats fetched successfully');
    
  } catch (err) {
    console.error("❌ Error in getDashboardStats:", err);
    res.json({
      success: false,
      stats: {
        totalUsers: 0,
        totalFreelancers: 0,
        totalClients: 0,
        totalProjects: 0,
        totalContracts: 0,
        totalEarnings: 0,
        pendingProjects: 0,
        activeContracts: 0,
        completedContracts: 0,
        pendingDisputes: 0,
      },
      monthlyStats: [],
      recentUsers: [],
      recentProjects: [],
    });
  }
};

export const getAllUsers = async (req, res) => {
  try {
    const { role, status, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (role && role !== "all") where.role = role;
    if (status && status !== "all") where.account_status = status;
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where,
      attributes: { exclude: ["password", "verification_code", "reset_password_token"] },
      include: [
        {
          model: FreelancerProfile,
          required: false,
          attributes: ["rating", "completed_projects_count", "total_earnings"],
        },
        {
          model: ClientProfile,
          required: false,
          attributes: ["company_name", "payment_verified"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      users: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllUsers:", err);
    res.status(500).json({ 
      success: false, 
      message: "Server error", 
      error: err.message,
      users: [],
      total: 0,
      totalPages: 0,
    });
  }
};

export const getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByPk(userId, {
      attributes: { exclude: ["password", "verification_code"] },
      include: [
        {
          model: FreelancerProfile,
          required: false,
        },
        {
          model: ClientProfile,
          required: false,
        },
      ],
    });

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const projects = await Project.count({ where: { UserId: userId } });
    const contracts = await Contract.count({ 
      where: { 
        [Op.or]: [
          { FreelancerId: userId },
          { ClientId: userId }
        ]
      } 
    });
    const ratings = await Rating.findAll({
      where: { toUserId: userId },
      attributes: ["rating"],
    });
    
    const avgRating = ratings.length > 0
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;

    res.json({
      success: true,
      user,
      stats: {
        projects,
        contracts,
        avgRating,
        totalRatings: ratings.length,
      },
    });
  } catch (err) {
    console.error("❌ Error in getUserDetails:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const updateUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, reason } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    await user.update({ account_status: status });

    console.log(`✅ User ${userId} status updated to ${status}`);

    res.json({
      success: true,
      message: `User status updated to ${status}`,
    });
  } catch (err) {
    console.error("❌ Error in updateUserStatus:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const verifyUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { verified } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    await user.update({ is_verified: verified });

    if (user.role === "freelancer") {
      await FreelancerProfile.update(
        { is_verified: verified },
        { where: { UserId: userId } }
      );
    } else if (user.role === "client") {
      await ClientProfile.update(
        { id_verified: verified },
        { where: { UserId: userId } }
      );
    }

    console.log(`✅ User ${userId} verification set to ${verified}`);

    res.json({
      success: true,
      message: verified ? "User verified" : "User verification removed",
    });
  } catch (err) {
    console.error("❌ Error in verifyUser:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const getAllProjects = async (req, res) => {
  try {
    const { status, category, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") where.status = status;
    if (category && category !== "all") where.category = category;
    if (search) {
      where[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Project.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar", "email"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      projects: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllProjects:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const deleteProject = async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ success: false, message: "Project not found" });
    }

    await project.destroy();

    console.log(`✅ Project ${projectId} deleted by admin`);

    res.json({
      success: true,
      message: "Project deleted successfully",
    });
  } catch (err) {
    console.error("❌ Error in deleteProject:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const getAllContracts = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") where.status = status;

    const { count, rows } = await Contract.findAndCountAll({
      where,
      include: [
        {
          model: Project,
          attributes: ["id", "title", "budget"],
        },
        {
          model: User,
          as: "client",
          attributes: ["id", "name", "avatar"],
        },
        {
          model: User,
          as: "freelancer",
          attributes: ["id", "name", "avatar"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      contracts: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    console.error("❌ Error in getAllContracts:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};

export const resolveDispute = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { resolution, refundTo, amount } = req.body;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res.status(404).json({ success: false, message: "Contract not found" });
    }

    await contract.update({
      status: "resolved",
      dispute_resolution: resolution,
      dispute_resolved_at: new Date(),
    });

    console.log(`✅ Dispute resolved for contract ${contractId}`);

    res.json({
      success: true,
      message: "Dispute resolved successfully",
    });
  } catch (err) {
    console.error("❌ Error in resolveDispute:", err);
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
};