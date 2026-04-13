import { Op } from "sequelize";
import { Transaction, Wallet } from "../models/index.js";
import NotificationService from "./notificationService.js";
import SubscriptionService from "./subscriptionService.js";

class CommissionService {
  static async calculateCommission(userId, amount) {
    const subscription = await SubscriptionService.getUserSubscription(userId);
    const plan = subscription.plan;

    let commissionRate = 0.05;

    if (plan.slug === "pro") {
      commissionRate = 0.02;
    } else if (plan.slug === "business") {
      commissionRate = 0.01;
    }

    if (plan.slug === "free") {
      const userTotalSpent = await this.getUserTotalSpent(userId);
      if (userTotalSpent > 5000) {
        commissionRate = 0.03;
      }
      // else 5%
    }

    return {
      rate: commissionRate,
      amount: amount * commissionRate,
      platformFee: amount * commissionRate,
    };
  }

  static async getUserTotalSpent(userId) {
    const totalSpent = await Transaction.sum("amount", {
      where: {
        wallet_id: { [Op.ne]: null },
        type: "payment",
        status: "completed",
      },
      include: [
        {
          model: Wallet,
          where: { UserId: userId },
          required: true,
        },
      ],
    });
    return totalSpent || 0;
  }

  static async processCommission(contractId, clientId, freelancerId, amount) {
    const { rate, platformFee } = await this.calculateCommission(
      clientId,
      amount,
    );

    // Deduct from client's pending balance? Or deduct from the amount released?
    // Usually, commission is taken from the client's payment before releasing to freelancer.
    // The amount released to freelancer is amount - platformFee.

    const clientWallet = await Wallet.findOne({ where: { UserId: clientId } });
    if (clientWallet && clientWallet.pending_balance >= amount) {
      await clientWallet.decrement("pending_balance", { by: amount });
    }

    const platformTransaction = await Transaction.create({
      amount: platformFee,
      type: "commission",
      status: "completed",
      description: `Platform commission (${rate * 100}%) for contract #${contractId}`,
      reference_id: contractId,
      reference_type: "contract",
      completed_at: new Date(),
    });

    await NotificationService.createNotification({
      userId: clientId,
      type: "commission_charged",
      title: "Platform Commission",
      body: `A commission of $${platformFee.toFixed(2)} (${rate * 100}%) was applied to your payment for contract #${contractId}.`,
      data: { contractId, screen: "contract" },
    });

    return { platformFee, commissionRate: rate };
  }

  static async processFeaturePurchase(userId, feature, amount) {
    const userWallet = await Wallet.findOne({ where: { UserId: userId } });

    if (!userWallet || userWallet.balance < amount) {
      throw new Error("Insufficient balance");
    }

    await userWallet.decrement("balance", { by: amount });

    const transaction = await Transaction.create({
      wallet_id: userWallet.id,
      amount: -amount,
      type: "feature",
      status: "completed",
      description: `Purchase: ${feature}`,
      completed_at: new Date(),
    });

    await NotificationService.createNotification({
      userId: userId,
      type: "feature_purchased",
      title: `Feature Purchased: ${feature}`,
      body: `$${amount.toFixed(2)} was deducted from your wallet.`,
      data: { screen: "wallet" },
    });

    return transaction;
  }
}

export default CommissionService;
