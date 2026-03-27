// models/Message.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Message = sequelize.define("Message", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  chat_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Chats',
      key: 'id'
    }
  },
  sender_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM("text", "image", "file"),
    defaultValue: "text",
  },
  media_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  read_by: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue('read_by');
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue('read_by', JSON.stringify(value));
    }
  },
  read_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  timestamps: true,
});

export default Message;