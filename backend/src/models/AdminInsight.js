// backend/src/models/AdminInsight.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const AdminInsight = sequelize.define("AdminInsight", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  type: {
    type: DataTypes.ENUM(
      "prediction",
      "anomaly",
      "recommendation",
      "alert",
      "insight",
    ),
    allowNull: false,
  },

  title: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.TEXT, allowNull: false },

  severity: {
    type: DataTypes.ENUM("info", "warning", "critical", "success"),
    defaultValue: "info",
  },

  category: {
    type: DataTypes.ENUM(
      "revenue",
      "users",
      "contracts",
      "disputes",
      "performance",
      "system",
    ),
    allowNull: false,
  },

  data: { type: DataTypes.TEXT, defaultValue: "{}" },
  action_url: { type: DataTypes.STRING, allowNull: true },
  action_text: { type: DataTypes.STRING, allowNull: true },

  is_resolved: { type: DataTypes.BOOLEAN, defaultValue: false },
  resolved_at: { type: DataTypes.DATE, allowNull: true },
  resolved_by: { type: DataTypes.INTEGER, allowNull: true },

  expires_at: { type: DataTypes.DATE, allowNull: true },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default AdminInsight;
