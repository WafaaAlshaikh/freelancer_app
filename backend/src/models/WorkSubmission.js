// ===== backend/src/models/WorkSubmission.js =====
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const WorkSubmission = sequelize.define("WorkSubmission", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  contract_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  milestone_index: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: "إذا كان التسليم لميلستون محدد",
  },
  freelancer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  client_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  files: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const raw = this.getDataValue('files');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('files', JSON.stringify(val));
    },
  },
  links: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const raw = this.getDataValue('links');
      return raw ? JSON.parse(raw) : [];
    },
    set(val) {
      this.setDataValue('links', JSON.stringify(val));
    },
  },
  status: {
    type: DataTypes.ENUM("pending", "approved", "rejected", "revision_requested"),
    defaultValue: "pending",
  },
  client_feedback: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  revision_request_message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  approved_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  submitted_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  timestamps: true,
});

export default WorkSubmission;