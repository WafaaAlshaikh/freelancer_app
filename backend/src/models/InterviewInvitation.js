import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const InterviewInvitation = sequelize.define(
  "InterviewInvitation",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    proposal_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Proposals",
        key: "id",
      },
    },
    client_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Users",
        key: "id",
      },
    },
    freelancer_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Users",
        key: "id",
      },
    },
    project_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Projects",
        key: "id",
      },
    },
    status: {
      type: DataTypes.ENUM(
        "pending",
        "accepted",
        "declined",
        "expired",
        "completed",
        "rescheduled",
      ),
      defaultValue: "pending",
    },
    suggested_times: {
      type: DataTypes.TEXT,
      defaultValue: "[]",
      get() {
        return this.getDataValue("suggested_times") || [];
      },
      set(val) {
        this.setDataValue("suggested_times", JSON.stringify(val));
      },
    },
    selected_time: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    meeting_link: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    response_message: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    responded_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    meeting_notes: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    feedback: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    reschedule_reason: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    duration_minutes: {
      type: DataTypes.INTEGER,
      defaultValue: 30,
    },
    group_interview: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    participant_ids: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    feedback_rating: {
      type: DataTypes.INTEGER,
      validate: { min: 1, max: 5 },
    },
    feedback_comment: DataTypes.TEXT,
    feedback_improvements: DataTypes.TEXT,
    calendar_event_id: DataTypes.STRING,
    reminder_sent_24h: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    reminder_sent_1h: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    preparation_checklist_sent: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    timestamps: true,
  },
);

export default InterviewInvitation;
