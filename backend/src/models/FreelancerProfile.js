import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const FreelancerProfile = sequelize.define("FreelancerProfile", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  title: { type: DataTypes.STRING, allowNull: true },
  bio: { type: DataTypes.TEXT, allowNull: true },
  tagline: { type: DataTypes.STRING(160), allowNull: true },

  skills: { type: DataTypes.TEXT, defaultValue: "[]" },
  top_skills: { type: DataTypes.TEXT, defaultValue: "[]" },
  experience_years: { type: DataTypes.INTEGER, defaultValue: 0 },
  hourly_rate: { type: DataTypes.FLOAT, allowNull: true },
  availability: {
    type: DataTypes.ENUM(
      "full_time",
      "part_time",
      "not_available",
      "as_needed",
    ),
    defaultValue: "full_time",
  },
  weekly_hours: { type: DataTypes.INTEGER, defaultValue: 40 },

  rating: { type: DataTypes.FLOAT, defaultValue: 0 },
  total_reviews: { type: DataTypes.INTEGER, defaultValue: 0 },
  completed_projects_count: { type: DataTypes.INTEGER, defaultValue: 0 },
  total_earnings: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  job_success_score: { type: DataTypes.INTEGER, defaultValue: 0 },
  response_time: { type: DataTypes.INTEGER, defaultValue: 0 },
  on_time_delivery_rate: { type: DataTypes.FLOAT, defaultValue: 0 },
  on_budget_rate: { type: DataTypes.FLOAT, defaultValue: 0 },
  repeat_hire_rate: { type: DataTypes.FLOAT, defaultValue: 0 },

  location: { type: DataTypes.STRING, allowNull: true },
  location_coordinates: { type: DataTypes.STRING, allowNull: true },
  timezone: { type: DataTypes.STRING, allowNull: true },
  languages: { type: DataTypes.TEXT, defaultValue: "[]" },

  education: { type: DataTypes.TEXT, defaultValue: "[]" },
  certifications: { type: DataTypes.TEXT, defaultValue: "[]" },
  work_experience: { type: DataTypes.TEXT, defaultValue: "[]" },

  portfolio_items_count: { type: DataTypes.INTEGER, defaultValue: 0 },
  video_intro_url: { type: DataTypes.STRING, allowNull: true },
  cv_url: { type: DataTypes.STRING, allowNull: true },
  cv_text: { type: DataTypes.TEXT, allowNull: true },

  social_links: { type: DataTypes.TEXT, defaultValue: "{}" },
  website: { type: DataTypes.STRING, allowNull: true },
  github: { type: DataTypes.STRING, allowNull: true },
  linkedin: { type: DataTypes.STRING, allowNull: true },
  behance: { type: DataTypes.STRING, allowNull: true },
  dribbble: { type: DataTypes.STRING, allowNull: true },
  stackoverflow: { type: DataTypes.STRING, allowNull: true },

  is_available: { type: DataTypes.BOOLEAN, defaultValue: true },
  is_featured: { type: DataTypes.BOOLEAN, defaultValue: false },
  is_top_rated: { type: DataTypes.BOOLEAN, defaultValue: false },
  is_rising_talent: { type: DataTypes.BOOLEAN, defaultValue: false },
  is_verified: { type: DataTypes.BOOLEAN, defaultValue: false },

  profile_strength: { type: DataTypes.INTEGER, defaultValue: 0 },
  profile_completion_percentage: { type: DataTypes.INTEGER, defaultValue: 0 },

  categories: { type: DataTypes.TEXT, defaultValue: "[]" },
  subcategories: { type: DataTypes.TEXT, defaultValue: "[]" },
  specialization: { type: DataTypes.TEXT, defaultValue: "[]" },

  profile_views: { type: DataTypes.INTEGER, defaultValue: 0 },
  search_appearances: { type: DataTypes.INTEGER, defaultValue: 0 },
  invitations_sent: { type: DataTypes.INTEGER, defaultValue: 0 },
  invitations_accepted: { type: DataTypes.INTEGER, defaultValue: 0 },

  preferred_project_types: { type: DataTypes.TEXT, defaultValue: "[]" },
  preferred_project_sizes: { type: DataTypes.TEXT, defaultValue: "[]" },
  min_project_budget: { type: DataTypes.DECIMAL(10, 2), allowNull: true },

  team_size: { type: DataTypes.INTEGER, allowNull: true },
  is_agency: { type: DataTypes.BOOLEAN, defaultValue: false },
  agency_id: { type: DataTypes.INTEGER, allowNull: true },

  skills_verified: { type: DataTypes.TEXT, defaultValue: "[]" },
  test_scores: { type: DataTypes.TEXT, defaultValue: "[]" },

  preferred_communication_channels: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
  },
  response_rate: { type: DataTypes.FLOAT, defaultValue: 0 },

  badges: { type: DataTypes.TEXT, defaultValue: "[]" },
  achievements: { type: DataTypes.TEXT, defaultValue: "[]" },

  last_profile_update: { type: DataTypes.DATE, allowNull: true },
  member_since: { type: DataTypes.DATE, allowNull: true },
});

export default FreelancerProfile;
