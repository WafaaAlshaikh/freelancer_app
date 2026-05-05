import AdCampaign from "../models/AdCampaign.js";
import AdImpression from "../models/AdImpression.js";
import AdService from "../services/adService.js";
import AdPaymentService from "../services/adPaymentService.js";
import { User, AdTransaction } from "../models/index.js";
import { sequelize } from "../config/db.js";
import { Op, fn } from "sequelize";

export const getActiveAds = async (req, res) => {
  try {
    const { placement, limit = 3 } = req.query;
    const userId = req.user?.id;
    const userRole = req.user?.role;
    const userCountry =
      req.headers["cf-ipcountry"] || req.query.country || "all";

    const ads = await AdService.getActiveAds(
      placement,
      userId,
      userRole,
      userCountry,
    );

    res.json({
      success: true,
      ads: ads.slice(0, parseInt(limit)).map((ad) => ({
        id: ad.id,
        title: ad.title,
        description: ad.description_text,
        image_url: ad.image_url,
        cta_text: ad.cta_text,
        ad_type: ad.ad_type,
      })),
    });
  } catch (err) {
    console.error("Error getting ads:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const trackAdClick = async (req, res) => {
  try {
    const { campaignId } = req.params;
    const userId = req.user?.id;
    const userRole = req.user?.role;
    const userCountry = req.headers["cf-ipcountry"] || "unknown";

    const targetUrl = await AdService.recordClick(
      campaignId,
      userId,
      userCountry,
      userRole,
    );

    res.json({ success: true, url: targetUrl });
  } catch (err) {
    console.error("Error tracking click:", err);
    res.status(500).json({ success: false });
  }
};

export const getMyCampaigns = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = { advertiser_id: userId };
    if (status && status !== "all") where.status = status;

    const { count, rows } = await AdCampaign.findAndCountAll({
      where,
      order: [["created_at", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    res.json({
      success: true,
      campaigns: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createCampaign = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      name,
      description,
      ad_type,
      placement,
      title,
      description_text,
      image_url,
      target_url,
      cta_text,
      pricing_model,
      cost_per_click,
      cost_per_impression,
      total_budget,
      daily_budget,
      start_date,
      end_date,
      target_countries,
      target_categories,
      user_roles,
    } = req.body;

    const campaign = await AdCampaign.create({
      advertiser_id: userId,
      name,
      description,
      ad_type,
      placement,
      title,
      description_text,
      image_url,
      target_url,
      cta_text,
      pricing_model,
      cost_per_click: cost_per_click || 0.1,
      cost_per_impression: cost_per_impression || 0.01,
      total_budget,
      daily_budget,
      start_date: new Date(start_date),
      end_date: new Date(end_date),
      target_countries: target_countries
        ? JSON.stringify(target_countries)
        : null,
      target_categories: target_categories
        ? JSON.stringify(target_categories)
        : null,
      user_roles: user_roles ? JSON.stringify(user_roles) : null,
      status: "draft",
    });

    res.json({ success: true, campaign });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const activateCampaign = async (req, res) => {
  try {
    const { campaignId } = req.params;
    const campaign = await AdCampaign.findByPk(campaignId);

    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    if (campaign.advertiser_id !== req.user.id && req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const paymentStatus = await AdPaymentService.checkPaymentStatus(campaignId);

    if (!paymentStatus.isPaid) {
      return res.status(400).json({
        success: false,
        message: "Payment not completed. Please complete payment first.",
        requiresPayment: true,
      });
    }

    if (campaign.spent_amount >= campaign.total_budget) {
      return res.status(400).json({
        success: false,
        message: "Campaign budget exhausted. Please add more funds.",
      });
    }

    const now = new Date();
    const startDate = new Date(campaign.start_date);
    const endDate = new Date(campaign.end_date);

    if (now < startDate) {
      return res.status(400).json({
        success: false,
        message: `Campaign cannot be activated before ${startDate.toLocaleDateString()}`,
      });
    }

    if (now > endDate) {
      return res.status(400).json({
        success: false,
        message: "Campaign end date has passed",
      });
    }

    await campaign.update({ status: "active" });

    res.json({
      success: true,
      message: "Campaign activated successfully",
      campaign: {
        id: campaign.id,
        status: "active",
        start_date: campaign.start_date,
        end_date: campaign.end_date,
      },
    });
  } catch (err) {
    console.error("Error activating campaign:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createPaymentSession = async (req, res) => {
  try {
    const { campaignId } = req.params;
    const { successUrl, cancelUrl } = req.body;

    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    if (campaign.advertiser_id !== req.user.id && req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const session = await AdPaymentService.createCheckoutSession(
      campaignId,
      req.user.id,
      successUrl || `${process.env.FRONTEND_URL}/ads/campaigns?payment=success`,
      cancelUrl || `${process.env.FRONTEND_URL}/ads/campaigns?payment=cancel`,
    );

    res.json({ success: true, url: session.url, sessionId: session.sessionId });
  } catch (err) {
    console.error("Error creating payment session:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const payWithWallet = async (req, res) => {
  try {
    const { campaignId } = req.params;

    const result = await AdPaymentService.payFromWallet(
      campaignId,
      req.user.id,
    );
    res.json(result);
  } catch (err) {
    console.error("Error paying with wallet:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const recordManualPayment = async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Admin only" });
    }

    const { campaignId } = req.params;
    const { amount, reference } = req.body;

    const result = await AdPaymentService.recordManualPayment(
      campaignId,
      req.user.id,
      amount,
      reference,
    );

    res.json(result);
  } catch (err) {
    console.error("Error recording manual payment:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getPaymentStatus = async (req, res) => {
  try {
    const { campaignId } = req.params;

    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    if (campaign.advertiser_id !== req.user.id && req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    const status = await AdPaymentService.checkPaymentStatus(campaignId);
    res.json(status);
  } catch (err) {
    console.error("Error checking payment status:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getAdRevenueStats = async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Admin only" });
    }

    const stats = await AdPaymentService.getAdminStats();
    res.json({ success: true, stats });
  } catch (err) {
    console.error("Error getting ad revenue stats:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const pauseCampaign = async (req, res) => {
  try {
    const { campaignId } = req.params;
    const campaign = await AdCampaign.findByPk(campaignId);

    if (!campaign) return res.status(404).json({ success: false });
    if (campaign.advertiser_id !== req.user.id && req.user.role !== "admin") {
      return res.status(403).json({ success: false });
    }

    await campaign.update({ status: "paused" });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false });
  }
};

export const getAdAnalytics = async (req, res) => {
  try {
    const { campaignId, startDate, endDate, groupBy = "day" } = req.query;

    const where = {};
    if (campaignId) where.campaign_id = campaignId;
    if (startDate && endDate) {
      where.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)],
      };
    }

    let groupFormat;
    if (groupBy === "day") groupFormat = "%Y-%m-%d";
    else if (groupBy === "month") groupFormat = "%Y-%m";
    else groupFormat = "%Y-%m-%d";

    const stats = await AdImpression.findAll({
      attributes: [
        [
          sequelize.fn("DATE_FORMAT", sequelize.col("created_at"), groupFormat),
          "date",
        ],
        "type",
        [sequelize.fn("COUNT", sequelize.col("*")), "count"],
        [sequelize.fn("SUM", sequelize.col("revenue")), "revenue"],
      ],
      where,
      group: ["date", "type"],
      order: [[sequelize.literal("date"), "ASC"]],
      raw: true,
    });

    const summary = await AdService.getAdStats(
      req.user.role === "admin" ? null : req.user.id,
    );

    res.json({ success: true, analytics: stats, summary });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getAdvertiserStats = async (req, res) => {
  try {
    const stats = await AdService.getAdStats(req.user.id);
    res.json({ success: true, stats });
  } catch (err) {
    res.status(500).json({ success: false });
  }
};

export const adminGetAllCampaigns = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const {
      status,
      page = 1,
      limit = 20,
      search = "",
      sortBy = "created_at",
      sortOrder = "DESC",
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (status && status !== "all") {
      where.status = status;
    }

    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
      ];
    }

    const { count, rows } = await AdCampaign.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: "advertiser",
          attributes: ["id", "name", "email", "avatar", "role"],
        },
      ],
      order: [[sortBy, sortOrder]],
      limit: parseInt(limit),
      offset,
      distinct: true,
    });

    res.json({
      success: true,
      campaigns: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
      stats: await getAdminCampaignStats(),
    });
  } catch (err) {
    console.error("Error in adminGetAllCampaigns:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

const getAdminCampaignStats = async () => {
  try {
    const [
      totalCampaigns,
      activeCampaigns,
      pausedCampaigns,
      completedCampaigns,
      draftCampaigns,
      pendingApprovalCampaigns,
    ] = await Promise.all([
      AdCampaign.count(),
      AdCampaign.count({ where: { status: "active" } }),
      AdCampaign.count({ where: { status: "paused" } }),
      AdCampaign.count({ where: { status: "completed" } }),
      AdCampaign.count({ where: { status: "draft" } }),
      AdCampaign.count({ where: { status: "pending_approval" } }),
    ]);

    const totalSpent = (await AdCampaign.sum("spent_amount")) || 0;
    const totalBudget = (await AdCampaign.sum("total_budget")) || 0;
    const totalImpressions = (await AdCampaign.sum("impressions")) || 0;
    const totalClicks = (await AdCampaign.sum("clicks")) || 0;

    const pendingPayments = await AdTransaction.count({
      where: { payment_status: "pending" },
    });

    return {
      total_campaigns: totalCampaigns,
      active_campaigns: activeCampaigns,
      paused_campaigns: pausedCampaigns,
      completed_campaigns: completedCampaigns,
      draft_campaigns: draftCampaigns,
      pending_approval: pendingApprovalCampaigns,
      total_spent: totalSpent,
      total_budget: totalBudget,
      total_impressions: totalImpressions,
      total_clicks: totalClicks,
      pending_payments: pendingPayments,
      click_through_rate:
        totalImpressions > 0
          ? ((totalClicks / totalImpressions) * 100).toFixed(2)
          : 0,
    };
  } catch (error) {
    console.error("Error getting admin campaign stats:", error);
    return {};
  }
};

export const adminGetCampaignDetails = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { campaignId } = req.params;

    const campaign = await AdCampaign.findByPk(campaignId, {
      include: [
        {
          model: User,
          as: "advertiser",
          attributes: [
            "id",
            "name",
            "email",
            "avatar",
            "role",
            "account_status",
          ],
        },
      ],
    });

    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    const impressionsStats = await AdImpression.findAll({
      where: { campaign_id: campaignId },
      attributes: [
        [sequelize.fn("DATE", sequelize.col("created_at")), "date"],
        [sequelize.fn("COUNT", sequelize.col("*")), "count"],
        "type",
      ],
      group: ["date", "type"],
      order: [[sequelize.literal("date"), "DESC"]],
      limit: 30,
    });

    const paymentTransactions = await AdTransaction.findAll({
      where: { campaign_id: campaignId },
      order: [["created_at", "DESC"]],
    });

    res.json({
      success: true,
      campaign,
      stats: {
        impressions_stats: impressionsStats,
        payment_transactions: paymentTransactions,
        platform_commission: parseFloat(campaign.spent_amount) * 0.2,
      },
    });
  } catch (err) {
    console.error("Error in adminGetCampaignDetails:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const adminUpdateCampaign = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { campaignId } = req.params;
    const updateData = req.body;

    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    const allowedFields = [
      "name",
      "description",
      "title",
      "description_text",
      "image_url",
      "target_url",
      "cta_text",
      "cost_per_click",
      "cost_per_impression",
      "total_budget",
      "daily_budget",
      "start_date",
      "end_date",
      "target_countries",
      "target_categories",
      "user_roles",
      "status",
    ];

    const updates = {};
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        updates[field] = updateData[field];
      }
    }

    await campaign.update(updates);

    console.log(`✅ Admin ${req.user.id} updated campaign ${campaignId}`);

    res.json({
      success: true,
      message: "Campaign updated successfully",
      campaign,
    });
  } catch (err) {
    console.error("Error in adminUpdateCampaign:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const adminChangeCampaignStatus = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { campaignId } = req.params;
    const { status, reason } = req.body;

    const validStatuses = [
      "draft",
      "active",
      "paused",
      "completed",
      "cancelled",
      "pending_approval",
    ];
    if (!validStatuses.includes(status)) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid status" });
    }

    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) {
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    if (status === "active") {
      const now = new Date();
      if (now > new Date(campaign.end_date)) {
        return res
          .status(400)
          .json({ success: false, message: "Campaign end date has passed" });
      }
      if (campaign.spent_amount >= campaign.total_budget) {
        return res
          .status(400)
          .json({ success: false, message: "Campaign budget exhausted" });
      }
    }

    await campaign.update({ status });

    console.log(
      `✅ Admin ${req.user.id} changed campaign ${campaignId} status to ${status}`,
    );

    res.json({
      success: true,
      message: `Campaign status changed to ${status}`,
      campaign: { id: campaign.id, status: campaign.status },
    });
  } catch (err) {
    console.error("Error in adminChangeCampaignStatus:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const adminDeleteCampaign = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    if (req.user?.role !== "admin") {
      await transaction.rollback();
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { campaignId } = req.params;

    const campaign = await AdCampaign.findByPk(campaignId);
    if (!campaign) {
      await transaction.rollback();
      return res
        .status(404)
        .json({ success: false, message: "Campaign not found" });
    }

    await AdImpression.destroy({
      where: { campaign_id: campaignId },
      transaction,
    });
    await AdTransaction.destroy({
      where: { campaign_id: campaignId },
      transaction,
    });
    await campaign.destroy({ transaction });

    await transaction.commit();

    console.log(`✅ Admin ${req.user.id} deleted campaign ${campaignId}`);

    res.json({
      success: true,
      message: "Campaign deleted successfully",
    });
  } catch (err) {
    await transaction.rollback();
    console.error("Error in adminDeleteCampaign:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const adminGetAdAnalytics = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { period = "month", startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        created_at: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
      };
    } else {
      const defaultStart = new Date();
      defaultStart.setDate(defaultStart.getDate() - 30);
      dateFilter = {
        created_at: {
          [Op.gte]: defaultStart,
        },
      };
    }

    const dailyStats = await AdImpression.findAll({
      attributes: [
        [sequelize.fn("DATE", sequelize.col("created_at")), "date"],
        "type",
        [sequelize.fn("COUNT", sequelize.col("*")), "count"],
        [sequelize.fn("SUM", sequelize.col("revenue")), "revenue"],
      ],
      where: dateFilter,
      group: ["date", "type"],
      order: [[sequelize.literal("date"), "ASC"]],
      raw: true,
    });

    const typeStats = await AdCampaign.findAll({
      attributes: [
        "ad_type",
        [
          sequelize.fn("SUM", sequelize.col("impressions")),
          "total_impressions",
        ],
        [sequelize.fn("SUM", sequelize.col("clicks")), "total_clicks"],
        [sequelize.fn("SUM", sequelize.col("spent_amount")), "total_spent"],
      ],
      group: ["ad_type"],
    });

    const advertiserStats = await AdCampaign.findAll({
      attributes: [
        "advertiser_id",
        [
          sequelize.fn("COUNT", sequelize.col("AdCampaign.id")),
          "campaign_count",
        ],
        [sequelize.fn("SUM", sequelize.col("spent_amount")), "total_spent"],
      ],
      include: [
        {
          model: User,
          as: "advertiser",
          attributes: ["name", "email"],
        },
      ],
      group: ["advertiser_id", "advertiser.id"],
    });

    const totalRevenue = (await AdImpression.sum("revenue")) || 0;

    const topAdvertisers = advertiserStats
      .map((stat) => ({
        id: stat.advertiser_id,
        name: stat.advertiser?.name || "Unknown",
        email: stat.advertiser?.email,
        campaign_count:
          parseInt(stat.dataValues.campaign_count) ||
          parseInt(stat.campaign_count) ||
          0,
        total_spent:
          parseFloat(stat.dataValues.total_spent) ||
          parseFloat(stat.total_spent) ||
          0,
        platform_commission:
          (parseFloat(stat.dataValues.total_spent) ||
            parseFloat(stat.total_spent) ||
            0) * 0.2,
      }))
      .sort((a, b) => b.total_spent - a.total_spent)
      .slice(0, 10);

    res.json({
      success: true,
      analytics: {
        daily_stats: dailyStats,
        type_stats: typeStats,
        top_advertisers: topAdvertisers,
        summary: {
          total_revenue: totalRevenue,
          platform_commission: totalRevenue,
          total_campaigns: await AdCampaign.count(),
          active_campaigns: await AdCampaign.count({
            where: { status: "active" },
          }),
        },
      },
    });
  } catch (err) {
    console.error("Error in adminGetAdAnalytics:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};

export const adminGetPaymentTransactions = async (req, res) => {
  try {
    if (req.user?.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Admin access required" });
    }

    const { campaignId, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (campaignId) where.campaign_id = campaignId;

    const { count, rows } = await AdTransaction.findAndCountAll({
      where,
      include: [
        {
          model: AdCampaign,
          attributes: ["name", "advertiser_id"],
          include: [
            {
              model: User,
              as: "advertiser",
              attributes: ["name", "email"],
            },
          ],
        },
      ],
      order: [["created_at", "DESC"]],
      limit: parseInt(limit),
      offset,
    });

    const summary = {
      total_paid:
        (await AdTransaction.sum("amount", {
          where: { payment_status: "paid" },
        })) || 0,
      total_pending:
        (await AdTransaction.sum("amount", {
          where: { payment_status: "pending" },
        })) || 0,
      total_refunded:
        (await AdTransaction.sum("amount", {
          where: { payment_status: "refunded" },
        })) || 0,
    };

    res.json({
      success: true,
      transactions: rows,
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / parseInt(limit)),
      summary,
    });
  } catch (err) {
    console.error("Error in adminGetPaymentTransactions:", err);
    res.status(500).json({ success: false, message: err.message });
  }
};
