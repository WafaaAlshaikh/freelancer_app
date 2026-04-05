// backend/src/controllers/subscriptionDevController.js

import SubscriptionDevService from "../services/subscriptionDevService.js";

export const manualActivateSubscription = async (req, res) => {
  try {
    const { planSlug } = req.body;
    const userId = req.user.id;

    if (!planSlug) {
      return res.status(400).json({
        success: false,
        message: "Plan slug is required",
      });
    }

    const result = await SubscriptionDevService.manualActivateSubscription(
      userId,
      planSlug,
    );

    res.json({
      success: true,
      subscription: result.subscription,
      plan: result.plan,
      message: `✅ ${result.plan.name} plan activated successfully!`,
    });
  } catch (error) {
    console.error("Error in manual activation:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
