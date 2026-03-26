// models/FreelancerProfile.js 
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";
import User from "./User.js";

const FreelancerProfile = sequelize.define("FreelancerProfile", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  title: DataTypes.STRING,
  bio: DataTypes.TEXT,
  skills: DataTypes.TEXT,
  experience_years: DataTypes.INTEGER,
  location: DataTypes.STRING,
  location_coordinates: {
    type: DataTypes.STRING, 
    allowNull: true
  },
  portfolio_links: DataTypes.TEXT, 
  cv_url: DataTypes.STRING,
  cv_text: DataTypes.TEXT, 
  rating: { type: DataTypes.FLOAT, defaultValue: 0 },
  completed_projects_count: { type: DataTypes.INTEGER, defaultValue: 0 },
  hourly_rate: { type: DataTypes.FLOAT, allowNull: true },
  languages: { type: DataTypes.TEXT, defaultValue: "[]" },
  education: { type: DataTypes.TEXT, defaultValue: "[]" }, 
  certifications: { type: DataTypes.TEXT, defaultValue: "[]" }, 
  social_links: { type: DataTypes.TEXT, defaultValue: "{}" }, 
  is_available: { type: DataTypes.BOOLEAN, defaultValue: true },
website: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  github: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  linkedin: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  behance: {
    type: DataTypes.STRING,
    allowNull: true,
  },

certifications: {
  type: DataTypes.TEXT, 
  defaultValue: "[]",
},
education: {
  type: DataTypes.TEXT, 
  defaultValue: "[]",
},
total_earnings: {
  type: DataTypes.DECIMAL(10, 2),
  defaultValue: 0,
},
job_success_score: {
  type: DataTypes.INTEGER,
  defaultValue: 0,
},
response_time: {
  type: DataTypes.INTEGER, 
  defaultValue: 0,
},
});

FreelancerProfile.belongsTo(User);
User.hasOne(FreelancerProfile);

export default FreelancerProfile;