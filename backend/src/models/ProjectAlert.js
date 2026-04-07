// ===== backend/src/models/ProjectAlert.js =====
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const ProjectAlert = sequelize.define("ProjectAlert", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  keywords: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const raw = this.getDataValue('keywords');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('keywords', JSON.stringify(val));
    },
  },
  skills: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const raw = this.getDataValue('skills');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('skills', JSON.stringify(val));
    },
  },
  min_budget: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  max_budget: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  categories: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const raw = this.getDataValue('categories');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('categories', JSON.stringify(val));
    },
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  notification_methods: {
    type: DataTypes.TEXT,
    defaultValue: '["email", "push"]',
    get() {
      const raw = this.getDataValue('notification_methods');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('notification_methods', JSON.stringify(val));
    },
  },
  last_notified_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  timestamps: true,
});

export default ProjectAlert;