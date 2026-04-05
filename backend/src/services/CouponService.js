import Coupon from "../models/Coupon.js";
import { Op } from "sequelize";

class CouponService {
  static async createCoupon(data) {
    let discountPercent = null;
    let discountAmount = null;

    if (data.discount_type === "percentage") {
      discountPercent = data.discount_value;
    } else if (data.discount_type === "fixed") {
      discountAmount = data.discount_value;
    }

    if (data.discount_percent !== undefined)
      discountPercent = data.discount_percent;
    if (data.discount_amount !== undefined)
      discountAmount = data.discount_amount;

    const couponData = {
      code: data.code.toUpperCase(),
      discount_percent: discountPercent,
      discount_amount: discountAmount,
      valid_from: data.valid_from,
      valid_until: data.valid_until,
      max_uses: data.max_uses || null,
      applicable_plans: data.applicable_plans || null,
      is_active: data.is_active !== undefined ? data.is_active : true,
    };

    const coupon = await Coupon.create(couponData);
    return coupon;
  }

  static async validateCoupon(code, planSlug = null) {
    const coupon = await Coupon.findOne({
      where: {
        code: code.toUpperCase(),
        is_active: true,
        valid_from: { [Op.lte]: new Date() },
        valid_until: { [Op.gte]: new Date() },
      },
    });

    if (!coupon) {
      return { valid: false, message: "Invalid or expired coupon code" };
    }

    if (coupon.max_uses && coupon.used_count >= coupon.max_uses) {
      return { valid: false, message: "Coupon has reached maximum uses" };
    }

    if (coupon.applicable_plans && planSlug) {
      if (!coupon.applicable_plans.includes(planSlug)) {
        return { valid: false, message: "Coupon not applicable for this plan" };
      }
    }

    return {
      valid: true,
      coupon,
      discount:
        coupon.discount_percent > 0
          ? { type: "percentage", value: coupon.discount_percent }
          : { type: "amount", value: coupon.discount_amount },
    };
  }

  static async applyCoupon(code, userId, subscriptionId = null) {
    const validation = await this.validateCoupon(code);

    if (!validation.valid) {
      return validation;
    }

    const coupon = validation.coupon;

    await coupon.increment("used_count");

    await SubscriptionLog.create({
      user_id: userId,
      action: "coupon_applied",
      coupon_code: code,
      metadata: { discount: validation.discount },
    });

    return {
      success: true,
      discount: validation.discount,
      coupon: coupon,
    };
  }

  static async getAllCoupons(page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const { count, rows } = await Coupon.findAndCountAll({
      order: [["createdAt", "DESC"]],
      limit,
      offset,
    });

    return {
      coupons: rows,
      total: count,
      page,
      totalPages: Math.ceil(count / limit),
    };
  }

  static async updateCoupon(couponId, data) {
    const coupon = await Coupon.findByPk(couponId);
    if (!coupon) {
      throw new Error("Coupon not found");
    }

    await coupon.update(data);
    return coupon;
  }

  static async deleteCoupon(couponId) {
    const coupon = await Coupon.findByPk(couponId);
    if (!coupon) {
      throw new Error("Coupon not found");
    }

    await coupon.destroy();
    return { success: true };
  }
}

export default CouponService;
