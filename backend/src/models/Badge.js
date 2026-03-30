import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Badge = sequelize.define("Badge", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  name: { type: DataTypes.STRING, allowNull: false },
  slug: { type: DataTypes.STRING, allowNull: false, unique: true },
  description: { type: DataTypes.TEXT, allowNull: true },

  icon: { type: DataTypes.STRING, allowNull: true },
  color: { type: DataTypes.STRING, defaultValue: "#1DB954" },
  badge_type: {
    type: DataTypes.ENUM(
      "achievement",
      "verification",
      "status",
      "performance",
      "special",
    ),
    defaultValue: "achievement",
  },

  criteria: { type: DataTypes.TEXT, defaultValue: "{}" },
  minimum_requirements: { type: DataTypes.TEXT, defaultValue: "{}" },

  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  is_featured: { type: DataTypes.BOOLEAN, defaultValue: false },
  is_permanent: { type: DataTypes.BOOLEAN, defaultValue: true },
  expires_after_days: { type: DataTypes.INTEGER, allowNull: true },

  display_priority: { type: DataTypes.INTEGER, defaultValue: 0 },
  show_on_profile: { type: DataTypes.BOOLEAN, defaultValue: true },

  target_roles: { type: DataTypes.TEXT, defaultValue: "[]" },

  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default Badge;
