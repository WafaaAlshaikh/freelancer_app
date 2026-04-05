import { User, Transaction } from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "./notificationService.js";

class AffiliateService {
  static COMMISSION_RATE = 0.2;

  static generateReferralCode(userId) {
    return `REF-${userId}-${Date.now().toString(36).toUpperCase()}`;
  }

  static async applyReferralCode(newUserId, referralCode) {
    const referrer = await User.findOne({
      where: { referral_code: referralCode },
    });

    if (!referrer) {
      return { success: false, message: "Invalid referral code" };
    }

    await User.update(
      { referred_by: referrer.id },
      { where: { id: newUserId } },
    );

    return { success: true, referrerId: referrer.id };
  }

  static async awardCommission(referredUserId, amount, transactionType) {
    const referredUser = await User.findByPk(referredUserId);
    if (!referredUser || !referredUser.referred_by) return;

    const isEligible = await this.isTransactionEligible(
      referredUserId,
      transactionType,
      amount,
    );
    if (!isEligible) return;

    const commissionAmount = amount * this.COMMISSION_RATE;

    const referrerWallet = await Wallet.findOne({
      where: { UserId: referredUser.referred_by },
    });

    if (referrerWallet) {
      await referrerWallet.increment("balance", { by: commissionAmount });

      await Transaction.create({
        wallet_id: referrerWallet.id,
        amount: commissionAmount,
        type: "deposit",
        status: "completed",
        description: `Affiliate commission for referral (${referredUser.email})`,
        reference_id: referredUser.id,
        reference_type: "referral",
        completed_at: new Date(),
      });

      await NotificationService.createNotification({
        userId: referredUser.referred_by,
        type: "affiliate_commission",
        title: "Affiliate Commission Earned! 🎉",
        body: `You earned $${commissionAmount.toFixed(2)} from your referral's activity.`,
        data: { screen: "wallet" },
      });
    }
  }

  static async isTransactionEligible(userId, type, amount) {
    if (type === "subscription") {
      const previousSubPayments = await Transaction.count({
        where: {
          reference_type: "subscription",
          type: "subscription",
          user_id: userId,
        },
      });
      return previousSubPayments === 0;
    }

    if (type === "deposit" && amount >= 100) {
      const previousDeposits = await Transaction.count({
        where: {
          user_id: userId,
          type: "deposit",
          amount: { [Op.gte]: 100 },
        },
      });
      return previousDeposits === 0;
    }

    return false;
  }
}

export default AffiliateService;
