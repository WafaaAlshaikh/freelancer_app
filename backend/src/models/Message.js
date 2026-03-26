import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Message = sequelize.define("Message", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  senderId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  receiverId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },

  message: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
});

export default Message;