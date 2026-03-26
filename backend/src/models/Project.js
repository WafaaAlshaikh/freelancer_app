// models/Project.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Project = sequelize.define("Project", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },

  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },

  budget: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },

  duration: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: "Duration in days",
  },

  category: {
    type: DataTypes.STRING,
    defaultValue: "other",
  },

  skills: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('skills');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('skills', JSON.stringify(value));
    }
  },

  status: {
    type: DataTypes.ENUM(
      "open",
      "in_progress",
      "completed",
      "cancelled"
    ),
    defaultValue: "open",
  },

  attachments: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('attachments');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('attachments', JSON.stringify(value));
    }
  },

  views: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  proposals_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

}, {
  timestamps: true,
});

export default Project;