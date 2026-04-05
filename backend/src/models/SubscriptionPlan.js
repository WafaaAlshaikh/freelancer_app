import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const SubscriptionPlan = sequelize.define(
  "SubscriptionPlan",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    slug: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    billing_period: {
      type: DataTypes.ENUM("monthly", "yearly"),
      defaultValue: "monthly",
    },
    features: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    proposal_limit: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    active_project_limit: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    ai_insights: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    priority_support: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    api_access: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    custom_branding: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    billing_intervals: {
      type: DataTypes.JSON,
      defaultValue: {
        monthly: { price: null, interval: "month", days: 30 },
        quarterly: { price: null, interval: "month", days: 90, discount: 0.05 },
        yearly: { price: null, interval: "year", days: 365, discount: 0.15 },
      },
    },
    features_list: {
      type: DataTypes.JSON,
      defaultValue: {},
    },
    trial_days: {
      type: DataTypes.INTEGER,
      defaultValue: 14,
    },
    sort_order: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    is_recommended: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
  },
  {
    tableName: "subscriptionplans",
    underscored: false,
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  },
);

SubscriptionPlan.prototype.toJSON = function () {
  const values = { ...this.get() };

  if (values.features) {
    if (typeof values.features === "string") {
      try {
        values.features = JSON.parse(values.features);
      } catch (e) {
        values.features = [];
      }
    }
  }

  return values;
};

export default SubscriptionPlan;
