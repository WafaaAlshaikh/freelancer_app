// models/Admin.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Admin = sequelize.define("Admin", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: "Users",
      key: "id",
    },
  },
  role: {
    type: DataTypes.ENUM("super_admin", "moderator", "support"),
    defaultValue: "moderator",
  },
  permissions: {
    type: DataTypes.TEXT,
    defaultValue: "[]", 
  },
  lastLogin: {
    type: DataTypes.DATE,
    allowNull: true,
  },
});

export default Admin;