import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Portfolio = sequelize.define("Portfolio", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  UserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
  },
  images: {
    type: DataTypes.TEXT, 
    defaultValue: "[]",
  },
  project_url: {
    type: DataTypes.STRING,
  },
  github_url: {
    type: DataTypes.STRING,
  },
  technologies: {
    type: DataTypes.TEXT, 
    defaultValue: "[]",
  },
  completion_date: {
    type: DataTypes.DATE,
  },
  featured: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  likes: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  views: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
});

export default Portfolio;