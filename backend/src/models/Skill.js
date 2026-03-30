import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Skill = sequelize.define("Skill", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  name: { type: DataTypes.STRING, allowNull: false, unique: true },
  slug: { type: DataTypes.STRING, allowNull: false, unique: true },
  description: { type: DataTypes.TEXT, allowNull: true },

  category: { type: DataTypes.STRING, allowNull: true },
  subcategory: { type: DataTypes.STRING, allowNull: true },

  proficiency_levels: {
    type: DataTypes.TEXT,
    defaultValue: JSON.stringify([
      "beginner",
      "intermediate",
      "advanced",
      "expert",
    ]),
  },

  demand_score: { type: DataTypes.FLOAT, defaultValue: 0 },
  popularity_score: { type: DataTypes.FLOAT, defaultValue: 0 },

  has_test: { type: DataTypes.BOOLEAN, defaultValue: false },
  test_duration_minutes: { type: DataTypes.INTEGER, allowNull: true },
  test_questions_count: { type: DataTypes.INTEGER, allowNull: true },

  related_skills: { type: DataTypes.TEXT, defaultValue: "[]" },

  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  is_featured: { type: DataTypes.BOOLEAN, defaultValue: false },

  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
});

export default Skill;
