// models/Project.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Project = sequelize.define(
  "Project",
  {
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
        const rawValue = this.getDataValue("skills");
        return rawValue ? JSON.parse(rawValue) : [];
      },
      set(value) {
        this.setDataValue("skills", JSON.stringify(value));
      },
    },

    status: {
      type: DataTypes.ENUM("open", "in_progress", "completed", "cancelled"),
      defaultValue: "open",
    },

    attachments: {
      type: DataTypes.TEXT,
      defaultValue: "[]",
      get() {
        const rawValue = this.getDataValue("attachments");
        return rawValue ? JSON.parse(rawValue) : [];
      },
      set(value) {
        this.setDataValue("attachments", JSON.stringify(value));
      },
    },

    views: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },

    proposals_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },

    favorites_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    views_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    applications_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    is_featured: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    featured_until: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    tags: {
      type: DataTypes.TEXT,
      defaultValue: "[]",
      get() {
        const raw = this.getDataValue("tags");
        return raw ? JSON.parse(raw) : [];
      },
      set(val) {
        this.setDataValue("tags", JSON.stringify(val));
      },
    },
    deadline: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    timestamps: true,
  },
);

export default Project;
