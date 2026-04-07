// ===== backend/src/models/UserFavorite.js =====
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const UserFavorite = sequelize.define("UserFavorite", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: "المستخدم الذي أضاف المشروع للمفضلة",
  },
  project_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: "المشروع المضاف للمفضلة",
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  indexes: [
    {
      unique: true,
      fields: ['user_id', 'project_id'],
    },
  ],
});

export default UserFavorite;