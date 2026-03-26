import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const User = sequelize.define("User", {

  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },

  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },

  email: {
    type: DataTypes.STRING,
    unique: true,
  },

  password: {
    type: DataTypes.STRING,
  },

  role: {
    type: DataTypes.ENUM("admin", "client", "freelancer"),
  },

  avatar: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  verification_code: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  is_verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },

  reset_password_token: {
    type: DataTypes.STRING,
    allowNull: true
  },

  reset_password_expires: {
    type: DataTypes.DATE,
    allowNull: true
  }

});
export default User;