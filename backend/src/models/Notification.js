// models/Notification.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Notification = sequelize.define("Notification", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM(
      "proposal_received",
      "proposal_accepted",
      "proposal_rejected",
      "contract_signed",
      "contract_created",
      "milestone_due",
      "milestone_completed",
      "payment_received",
      "payment_released",
      "message",
      "project_completed",
      "new_review",
      "reminder",
      "interview_invitation",
      "interview_response",
      "interview_reminder",
      "interview_rescheduled",
    ),
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  body: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  data: {
    type: DataTypes.TEXT,
    defaultValue: "{}",
  },
  isRead: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  readAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
});

export default Notification;
