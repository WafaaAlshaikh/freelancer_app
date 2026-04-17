import SubscriptionService from "../services/subscriptionService.js";
import SubscriptionPlan from "../models/SubscriptionPlan.js";
import UserSubscription from "../models/UserSubscription.js";
import Coupon from "../models/Coupon.js";
import CouponService from "../services/CouponService.js";
import { Op } from "sequelize";

export const getSubscriptionStats = async (req, res) => {
  try {
    const stats = {
      total_subscriptions: await UserSubscription.count(),
      active_subscriptions: await UserSubscription.count({
        where: { status: "active" },
      }),
      trialing_subscriptions: await UserSubscription.count({
        where: { status: "trialing" },
      }),
      canceled_subscriptions: await UserSubscription.count({
        where: { status: "canceled" },
      }),
      expired_subscriptions: await UserSubscription.count({
        where: { status: "expired" },
      }),

      monthly_recurring_revenue:
        await SubscriptionService.calculateMonthlyRevenue(),
      yearly_recurring_revenue:
        await SubscriptionService.calculateYearlyRevenue(),

      popular_plan: await getMostPopularPlan(),
      upgrade_rate: await calculateUpgradeRate(),
      churn_rate: await calculateChurnRate(),

      revenue_by_plan: await getRevenueByPlan(),
      subscriptions_by_plan: await getSubscriptionsByPlan(),
    };

    res.json({ success: true, stats });
  } catch (error) {
    console.error("Error getting subscription stats:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getAllPlansAdmin = async (req, res) => {
  try {
    const plans = await SubscriptionPlan.findAll({
      order: [
        ["sort_order", "ASC"],
        ["price", "ASC"],
      ],
    });
    res.json({ success: true, plans });
  } catch (error) {
    console.error("Error getting plans:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const createPlan = async (req, res) => {
  try {
    const {
      name,
      slug,
      description,
      price,
      billing_period,
      features,
      proposal_limit,
      active_project_limit,
      ai_insights,
      priority_support,
      api_access,
      custom_branding,
      trial_days,
      sort_order,
      is_recommended,
    } = req.body;

    const plan = await SubscriptionPlan.create({
      name,
      slug,
      description,
      price,
      billing_period,
      features,
      proposal_limit,
      active_project_limit,
      ai_insights,
      priority_support,
      api_access,
      custom_branding,
      trial_days: trial_days || 14,
      sort_order: sort_order || 0,
      is_recommended: is_recommended || false,
      is_active: true,
    });

    res.json({ success: true, plan });
  } catch (error) {
    console.error("Error creating plan:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const updatePlan = async (req, res) => {
  try {
    const { id } = req.params;
    const plan = await SubscriptionPlan.findByPk(id);

    if (!plan) {
      return res
        .status(404)
        .json({ success: false, message: "Plan not found" });
    }

    await plan.update(req.body);
    res.json({ success: true, plan });
  } catch (error) {
    console.error("Error updating plan:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const deletePlan = async (req, res) => {
  try {
    const { id } = req.params;
    const plan = await SubscriptionPlan.findByPk(id);

    if (!plan) {
      return res
        .status(404)
        .json({ success: false, message: "Plan not found" });
    }

    const activeSubscriptions = await UserSubscription.count({
      where: { plan_id: id, status: "active" },
    });

    if (activeSubscriptions > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete plan with ${activeSubscriptions} active subscriptions`,
      });
    }

    await plan.destroy();
    res.json({ success: true, message: "Plan deleted successfully" });
  } catch (error) {
    console.error("Error deleting plan:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getAllCoupons = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const result = await CouponService.getAllCoupons(
      parseInt(page),
      parseInt(limit),
    );
    res.json({ success: true, ...result });
  } catch (error) {
    console.error("Error getting coupons:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const createCoupon = async (req, res) => {
  try {
    const coupon = await CouponService.createCoupon(req.body);
    res.json({ success: true, coupon });
  } catch (error) {
    console.error("Error creating coupon:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const updateCoupon = async (req, res) => {
  try {
    const { id } = req.params;
    const coupon = await CouponService.updateCoupon(id, req.body);
    res.json({ success: true, coupon });
  } catch (error) {
    console.error("Error updating coupon:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const deleteCoupon = async (req, res) => {
  try {
    const { id } = req.params;
    await CouponService.deleteCoupon(id);
    res.json({ success: true, message: "Coupon deleted successfully" });
  } catch (error) {
    console.error("Error deleting coupon:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

async function getMostPopularPlan() {
  try {
    const subscriptions = await UserSubscription.findAll({
      where: { status: "active" },
      attributes: ["plan_id"],
      group: ["plan_id"],
      raw: true,
    });

    if (!subscriptions || subscriptions.length === 0) return null;

    const planCounts = {};
    for (const sub of subscriptions) {
      const planId = sub.plan_id;
      planCounts[planId] = (planCounts[planId] || 0) + 1;
    }

    let mostPopularId = null;
    let maxCount = 0;
    for (const [planId, count] of Object.entries(planCounts)) {
      if (count > maxCount) {
        maxCount = count;
        mostPopularId = planId;
      }
    }

    if (!mostPopularId) return null;

    const plan = await SubscriptionPlan.findByPk(mostPopularId);
    return plan ? { id: plan.id, name: plan.name, count: maxCount } : null;
  } catch (error) {
    console.error("Error in getMostPopularPlan:", error);
    return null;
  }
}

async function calculateUpgradeRate() {
  try {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const newSubscriptions = await UserSubscription.count({
      where: {
        createdAt: { [Op.gte]: startOfMonth },
      },
    });

    const upgradedSubscriptions = await UserSubscription.count({
      where: {
        createdAt: { [Op.gte]: startOfMonth },
        plan_id: { [Op.ne]: 1 },
      },
    });

    const totalSubscriptions = await UserSubscription.count({
      where: { createdAt: { [Op.gte]: startOfMonth } },
    });

    return totalSubscriptions > 0
      ? (upgradedSubscriptions / totalSubscriptions) * 100
      : 0;
  } catch (error) {
    console.error("Error calculating upgrade rate:", error);
    return 0;
  }
}

async function calculateChurnRate() {
  try {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const canceled = await UserSubscription.count({
      where: {
        status: "canceled",
        updatedAt: { [Op.gte]: startOfMonth },
      },
    });

    const active = await UserSubscription.count({
      where: { status: "active" },
    });

    return active > 0 ? (canceled / active) * 100 : 0;
  } catch (error) {
    console.error("Error calculating churn rate:", error);
    return 0;
  }
}

async function getRevenueByPlan() {
  try {
    const plans = await SubscriptionPlan.findAll();
    const revenue = {};

    for (const plan of plans) {
      const subscriptions = await UserSubscription.count({
        where: { plan_id: plan.id, status: "active" },
      });
      revenue[plan.name] = subscriptions * parseFloat(plan.price);
    }

    return revenue;
  } catch (error) {
    console.error("Error in getRevenueByPlan:", error);
    return {};
  }
}

async function getSubscriptionsByPlan() {
  try {
    const plans = await SubscriptionPlan.findAll();
    const counts = {};

    for (const plan of plans) {
      const count = await UserSubscription.count({
        where: { plan_id: plan.id, status: "active" },
      });
      counts[plan.name] = count;
    }

    return counts;
  } catch (error) {
    console.error("Error in getSubscriptionsByPlan:", error);
    return {};
  }
}
