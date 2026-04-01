// backend/src/models/SkillTest.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const SkillTest = sequelize.define("SkillTest", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
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
  skill_category: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  difficulty: {
    type: DataTypes.ENUM("beginner", "intermediate", "advanced", "expert"),
    defaultValue: "intermediate",
  },
  questions: {
    type: DataTypes.TEXT, // JSON array of questions
    allowNull: false,
    get() {
      const rawValue = this.getDataValue('questions');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('questions', JSON.stringify(value));
    }
  },
  passing_score: {
    type: DataTypes.INTEGER,
    defaultValue: 70, // percentage
  },
  time_limit_minutes: {
    type: DataTypes.INTEGER,
    defaultValue: 30,
  },
  max_attempts: {
    type: DataTypes.INTEGER,
    defaultValue: 3,
  },
  badge_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Badges',
      key: 'id',
    },
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  attempts_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
});

export default SkillTest;