// backend/src/controllers/adminAnalyticsController.js
import AdminAnalyticsService from "../services/adminAnalyticsService.js";
import AdminAuditLog from "../models/AdminAuditLog.js";

export const getTopPerformers = async (req, res) => {
  try {
    const { criteria = "overall", limit = 10 } = req.query;
    const performers = await AdminAnalyticsService.getTopPerformers(
      criteria,
      parseInt(limit),
    );

    await AdminAnalyticsService.logAdminAction({
      adminId: req.user.id,
      adminName: req.user.name,
      action: "export",
      targetType: "analytics",
      targetName: `top_performers_${criteria}`,
      ipAddress: req.ip,
      userAgent: req.headers["user-agent"],
      severity: "low",
    });

    res.json({ success: true, performers });
  } catch (error) {
    console.error("Error getting top performers:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getPredictiveAnalytics = async (req, res) => {
  try {
    const predictions = await AdminAnalyticsService.getPredictiveAnalytics();
    res.json({ success: true, predictions });
  } catch (error) {
    console.error("Error getting predictive analytics:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getActiveInsights = async (req, res) => {
  try {
    const insights = await AdminAnalyticsService.getActiveInsights();
    res.json({ success: true, insights });
  } catch (error) {
    console.error("Error getting insights:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const resolveInsight = async (req, res) => {
  try {
    const { insightId } = req.params;
    const insight = await AdminAnalyticsService.resolveInsight(
      insightId,
      req.user.id,
    );
    res.json({ success: true, insight });
  } catch (error) {
    console.error("Error resolving insight:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAuditLogs = async (req, res) => {
  try {
    const { adminId, action, targetType, severity, startDate, endDate, limit } =
      req.query;
    const logs = await AdminAnalyticsService.getAuditLogs({
      adminId,
      action,
      targetType,
      severity,
      startDate,
      endDate,
      limit,
    });
    res.json({ success: true, logs });
  } catch (error) {
    console.error("Error getting audit logs:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAdvancedStats = async (req, res) => {
  try {
    const stats = await AdminAnalyticsService.getAdvancedStats();
    res.json({ success: true, stats });
  } catch (error) {
    console.error("Error getting advanced stats:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUserSatisfaction = async (req, res) => {
  try {
    const analysis = await AdminAnalyticsService.getUserSatisfactionAnalysis();
    res.json({ success: true, analysis });
  } catch (error) {
    console.error("Error getting user satisfaction:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const auditMiddleware = (action, targetType, getTargetName = null) => {
  return async (req, res, next) => {
    const originalJson = res.json;

    res.json = function (data) {
      if (data && data.success) {
        const targetId = req.params.id || req.body.id;
        const targetName = getTargetName ? getTargetName(req) : null;

        AdminAnalyticsService.logAdminAction({
          adminId: req.user.id,
          adminName: req.user.name,
          action: action,
          targetType: targetType,
          targetId: targetId,
          targetName: targetName,
          changes: req.body,
          ipAddress: req.ip,
          userAgent: req.headers["user-agent"],
          severity: action === "delete" ? "high" : "medium",
        }).catch(console.error);
      }

      originalJson.call(this, data);
    };

    next();
  };
};
