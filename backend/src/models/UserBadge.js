import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const UserBadge = sequelize.define("UserBadge", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  
  user_id: { type: DataTypes.INTEGER, allowNull: false },
  badge_id: { type: DataTypes.INTEGER, allowNull: false },
  
  awarded_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  awarded_by: { type: DataTypes.INTEGER, allowNull: true }, // Admin user ID
  
  expires_at: { type: DataTypes.DATE, allowNull: true },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  
  achievement_context: { type: DataTypes.TEXT, defaultValue: "{}" },
  related_project_id: { type: DataTypes.INTEGER, allowNull: true },
  related_review_id: { type: DataTypes.INTEGER, allowNull: true },
  
  is_displayed: { type: DataTypes.BOOLEAN, defaultValue: true },
  display_priority: { type: DataTypes.INTEGER, defaultValue: 0 },
  
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default UserBadge;
