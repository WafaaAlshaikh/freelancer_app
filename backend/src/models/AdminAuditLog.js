// backend/src/models/AdminAuditLog.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const AdminAuditLog = sequelize.define("AdminAuditLog", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  admin_id: { type: DataTypes.INTEGER, allowNull: false },
  admin_name: { type: DataTypes.STRING, allowNull: false },

  action: {
    type: DataTypes.ENUM(
      "create",
      "update",
      "delete",
      "suspend",
      "activate",
      "verify",
      "export",
      "view_sensitive",
      "change_settings",
    ),
    allowNull: false,
  },

  target_type: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },

  target_id: { type: DataTypes.INTEGER, allowNull: true },
  target_name: { type: DataTypes.STRING, allowNull: true },

  changes: { type: DataTypes.TEXT, defaultValue: "{}" },
  ip_address: { type: DataTypes.STRING, allowNull: true },
  user_agent: { type: DataTypes.TEXT, allowNull: true },

  severity: {
    type: DataTypes.ENUM("low", "medium", "high", "critical"),
    defaultValue: "low",
  },

  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default AdminAuditLog;
