// backend/src/models/UserSkillTest.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const UserSkillTest = sequelize.define("UserSkillTest", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  test_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  score: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  percentage: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  answers: {
    type: DataTypes.TEXT, // JSON array of user answers
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('answers');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('answers', JSON.stringify(value));
    }
  },
  passed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  started_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  completed_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  attempt_number: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  badge_awarded: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  certificate_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  timestamps: true,
});

export default UserSkillTest;