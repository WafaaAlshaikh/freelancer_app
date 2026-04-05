import { User, Project } from "../models/index.js";
import CommissionService from "../services/commissionService.js";

const FEATURE_PRICES = {
  'profile_feature': 9.99,
  'project_highlight': 4.99,
  'skill_certificate': 29.00,
  'ai_resume_review': 9.99,
};

export const purchaseFeature = async (req, res) => {
  try {
    const { feature, entityId } = req.body;

    if (!FEATURE_PRICES[feature]) {
      return res.status(400).json({ success: false, message: 'Invalid feature' });
    }

    const price = FEATURE_PRICES[feature];

    await CommissionService.processFeaturePurchase(req.user.id, feature, price);

    switch (feature) {
      case 'profile_feature':
        await User.update({ is_featured: true, featured_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) }, { where: { id: req.user.id } });
        break;
      case 'project_highlight':
        await Project.update({ is_highlighted: true, highlighted_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) }, { where: { id: entityId } });
        break;
      case 'skill_certificate':
        // Logic for generating and issuing a certificate
        // This would typically involve an external service or PDF generation
        break;
      case 'ai_resume_review':
        // Trigger AI resume review and send result via email/notification
        break;
    }

    res.json({ success: true, message: `Successfully purchased ${feature}` });
  } catch (error) {
    console.error('Error purchasing feature:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getFeaturePrices = async (req, res) => {
  res.json({ success: true, prices: FEATURE_PRICES });
};