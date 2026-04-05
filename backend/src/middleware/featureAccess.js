import SubscriptionService from "../services/subscriptionService.js";

export const checkFeatureAccess = (featureName) => {
  return async (req, res, next) => {
    try {
      const subscription = await SubscriptionService.getUserSubscription(
        req.user.id,
      );

      const featureMap = {
        ai_insights: subscription.plan.ai_insights,
        priority_support: subscription.plan.priority_support,
        api_access: subscription.plan.api_access,
        custom_branding: subscription.plan.custom_branding,
      };

      const hasAccess = featureMap[featureName] || false;

      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          error: "upgrade_required",
          message: `This feature requires ${featureName.replace("_", " ")}. Please upgrade your subscription.`,
          required_plan:
            await SubscriptionService.getRequiredPlanForFeature(featureName),
        });
      }

      next();
    } catch (error) {
      console.error("Feature access error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  };
};

export const checkProposalLimit = async (req, res, next) => {
  try {
    const canSubmit = await SubscriptionService.canSubmitProposal(req.user.id);

    if (!canSubmit) {
      return res.status(403).json({
        success: false,
        error: "limit_reached",
        message:
          "You have reached your monthly proposal limit. Upgrade to continue.",
      });
    }

    next();
  } catch (error) {
    console.error("Proposal limit error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const checkActiveProjectsLimit = async (req, res, next) => {
  try {
    const canCreate = await SubscriptionService.canCreateActiveProject(
      req.user.id,
    );

    if (!canCreate) {
      return res.status(403).json({
        success: false,
        error: "limit_reached",
        message:
          "You have reached your active projects limit. Upgrade to continue.",
      });
    }

    next();
  } catch (error) {
    console.error("Active projects limit error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
