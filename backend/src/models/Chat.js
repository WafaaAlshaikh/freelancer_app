// models/Chat.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Chat = sequelize.define("Chat", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  unique_id: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false,
  },
  participant_ids: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('participant_ids');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('participant_ids', JSON.stringify(value));
    }
  },
  last_message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  last_message_time: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  last_message_sender_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  unread_counts: {
    type: DataTypes.TEXT,
    defaultValue: "{}",
    get() {
      const rawValue = this.getDataValue('unread_counts');
      return rawValue ? JSON.parse(rawValue) : {};
    },
    set(value) {
      this.setDataValue('unread_counts', JSON.stringify(value));
    }
  },
  status: {
    type: DataTypes.ENUM("active", "archived", "blocked"),
    defaultValue: "active",
  },
}, {
  timestamps: true,
});

export default Chat;