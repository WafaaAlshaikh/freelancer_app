import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const AdCampaign = sequelize.define("AdCampaign", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  name: { type: DataTypes.STRING, allowNull: false },
  description: DataTypes.TEXT,

  ad_type: {
    type: DataTypes.ENUM("banner", "sidebar", "popup", "video", "native"),
    defaultValue: "banner",
  },

  placement: {
    type: DataTypes.STRING,
    comment: "home_top, home_bottom, sidebar_top, search_results, project_page",
  },

  title: DataTypes.STRING,
  description_text: DataTypes.TEXT,
  image_url: DataTypes.STRING,
  video_url: DataTypes.STRING,
  target_url: DataTypes.STRING,
  cta_text: { type: DataTypes.STRING, defaultValue: "Learn More" },

  pricing_model: {
    type: DataTypes.ENUM("cpc", "cpm", "cpa", "flat"),
    defaultValue: "cpc",
  },

  cost_per_click: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0.1 },
  cost_per_impression: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0.01 },
  cost_per_action: { type: DataTypes.DECIMAL(10, 2), defaultValue: 5.0 },
  flat_fee: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },

  total_budget: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  daily_budget: { type: DataTypes.DECIMAL(10, 2) },
  spent_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },

  impressions: { type: DataTypes.INTEGER, defaultValue: 0 },
  clicks: { type: DataTypes.INTEGER, defaultValue: 0 },
  conversions: { type: DataTypes.INTEGER, defaultValue: 0 },

  target_countries: {
    type: DataTypes.TEXT,
    comment: "JSON array of country codes",
  },
  target_categories: {
    type: DataTypes.TEXT,
    comment: "JSON array of project categories",
  },
  min_user_rating: { type: DataTypes.DECIMAL(3, 2), defaultValue: 0 },
  user_roles: {
    type: DataTypes.TEXT,
    comment: "JSON array: client, freelancer",
  },

  start_date: { type: DataTypes.DATE, allowNull: false },
  end_date: { type: DataTypes.DATE, allowNull: false },

  status: {
    type: DataTypes.ENUM("draft", "active", "paused", "completed", "cancelled"),
    defaultValue: "draft",
  },

  advertiser_id: {
    type: DataTypes.INTEGER,
    references: { model: "Users", key: "id" },
    allowNull: false,
  },

  payment_status: {
    type: DataTypes.ENUM("pending", "paid", "partial", "refunded"),
    defaultValue: "pending",
  },
  payment_transaction_id: DataTypes.STRING,

  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default AdCampaign;
