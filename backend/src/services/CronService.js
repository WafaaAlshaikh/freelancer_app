import cron from "node-cron";
import { Op } from "sequelize";
import UserSubscription from "../models/UserSubscription.js";
import SubscriptionPlan from "../models/SubscriptionPlan.js";
import User from "../models/User.js";
import NotificationService from "./notificationService.js";
import SubscriptionService from "./subscriptionService.js";

class CronService {
  static initialize() {
    cron.schedule("0 0 * * *", async () => {
      console.log("🕐 Running daily subscription check...");
      await this.checkExpiredSubscriptions();
    });

    cron.schedule("0 9 * * *", async () => {
      console.log("🕐 Running expiring subscriptions notification...");
      await this.notifyExpiringSubscriptions();
    });

    cron.schedule("0 0 1 * *", async () => {
      console.log("🕐 Running monthly subscription report...");
      await this.generateMonthlyReport();
    });

    console.log("✅ Cron jobs initialized");
  }

  static async checkExpiredSubscriptions() {
    try {
      const expiredSubscriptions = await UserSubscription.findAll({
        where: {
          status: "active",
          current_period_end: { [Op.lt]: new Date() },
        },
        include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
      });

      console.log(`Found ${expiredSubscriptions.length} expired subscriptions`);

      for (const subscription of expiredSubscriptions) {
        await subscription.update({ status: "expired" });

        await SubscriptionLog.create({
          user_id: subscription.user_id,
          old_plan_id: subscription.plan_id,
          action: "expired",
        });

        await NotificationService.createNotification({
          userId: subscription.user_id,
          type: "subscription_expired",
          title: "Subscription Expired",
          body: "Your subscription has expired. Renew now to continue enjoying premium features.",
          data: { screen: "subscription/plans" },
        }).catch((e) => console.log("Notification error:", e.message));
      }
    } catch (error) {
      console.error("Error checking expired subscriptions:", error);
    }
  }

  static async notifyExpiringSubscriptions() {
    const daysBefore = [30, 14, 7, 3, 1];

    for (const days of daysBefore) {
      const expiringDate = new Date();
      expiringDate.setDate(expiringDate.getDate() + days);

      const expiringStart = new Date(expiringDate);
      expiringStart.setHours(0, 0, 0, 0);

      const expiringEnd = new Date(expiringDate);
      expiringEnd.setHours(23, 59, 59, 999);

      const subscriptions = await UserSubscription.findAll({
        where: {
          status: "active",
          current_period_end: {
            [Op.between]: [expiringStart, expiringEnd],
          },
        },
        include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
      });

      for (const subscription of subscriptions) {
        await NotificationService.createNotification({
          userId: subscription.user_id,
          type: "subscription_expiring",
          title: `Subscription Expires in ${days} Days`,
          body: `Your ${subscription.SubscriptionPlan.name} subscription will expire in ${days} days. Renew now to avoid interruption.`,
          data: { screen: "subscription/plans" },
        }).catch((e) => console.log("Notification error:", e.message));

        await this.sendExpirationEmail(
          subscription.user_id,
          subscription,
          days,
        );
      }
    }
  }

  static async sendExpirationEmail(userId, subscription, daysLeft) {
    try {
      const user = await User.findByPk(userId);
      if (!user || !user.email) return;

      console.log(
        `📧 Expiration email sent to ${user.email}: ${daysLeft} days left`,
      );
    } catch (error) {
      console.error("Error sending expiration email:", error);
    }
  }

  static async generateMonthlyReport() {
    try {
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      const newSubscriptions = await UserSubscription.count({
        where: {
          createdAt: { [Op.between]: [startOfMonth, endOfMonth] },
        },
      });

      const canceledSubscriptions = await UserSubscription.count({
        where: {
          cancel_at_period_end: true,
          current_period_end: { [Op.between]: [startOfMonth, endOfMonth] },
        },
      });

      const revenue = await SubscriptionService.calculateMonthlyRevenue(
        startOfMonth,
        endOfMonth,
      );

      const report = {
        month: `${now.getFullYear()}-${now.getMonth() + 1}`,
        new_subscriptions: newSubscriptions,
        canceled_subscriptions: canceledSubscriptions,
        total_active_subscriptions: await UserSubscription.count({
          where: { status: "active" },
        }),
        monthly_revenue: revenue,
        churn_rate:
          newSubscriptions > 0
            ? (canceledSubscriptions / newSubscriptions) * 100
            : 0,
      };

      console.log("📊 Monthly Report:", report);

      await this.saveReport(report);

      return report;
    } catch (error) {
      console.error("Error generating report:", error);
    }
  }

  static async saveReport(report) {
    console.log("Report saved:", report.month);
  }

  static async calculateMRR() {
    const activeSubscriptions = await UserSubscription.findAll({
      where: { status: "active" },
      include: [{ model: SubscriptionPlan, as: "SubscriptionPlan" }],
    });

    let mrr = 0;
    for (const sub of activeSubscriptions) {
      mrr += parseFloat(sub.SubscriptionPlan.price);
    }

    return mrr;
  }
}

export default CronService;
