import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const ClientProfile = sequelize.define("ClientProfile", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },

  company_name: { type: DataTypes.STRING, allowNull: true },
  company_size: {
    type: DataTypes.ENUM("1", "2-10", "11-50", "51-200", "201-1000", "1000+"),
    allowNull: true,
  },
  company_website: { type: DataTypes.STRING, allowNull: true },
  industry: { type: DataTypes.STRING, allowNull: true },
  company_description: { type: DataTypes.TEXT, allowNull: true },
  company_logo: { type: DataTypes.STRING, allowNull: true },
  founded_year: { type: DataTypes.INTEGER, allowNull: true },
  company_type: {
    type: DataTypes.ENUM(
      "startup",
      "small_business",
      "medium_business",
      "enterprise",
      "individual",
    ),
    defaultValue: "individual",
  },

  tagline: { type: DataTypes.STRING(160), allowNull: true },
  bio: { type: DataTypes.TEXT, allowNull: true },
  location: { type: DataTypes.STRING, allowNull: true },
  country: { type: DataTypes.STRING, allowNull: true },
  timezone: { type: DataTypes.STRING, allowNull: true },
  phone: { type: DataTypes.STRING, allowNull: true },

  preferred_skills: { type: DataTypes.TEXT, defaultValue: "[]" },
  hiring_for: { type: DataTypes.TEXT, defaultValue: "[]" },
  preferred_contract_type: {
    type: DataTypes.ENUM("hourly", "fixed", "both"),
    defaultValue: "both",
  },
  budget_range_min: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
  budget_range_max: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
  avg_project_budget: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },

  total_spent: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  total_projects: { type: DataTypes.INTEGER, defaultValue: 0 },
  active_contracts: { type: DataTypes.INTEGER, defaultValue: 0 },
  completed_contracts: { type: DataTypes.INTEGER, defaultValue: 0 },
  cancelled_contracts: { type: DataTypes.INTEGER, defaultValue: 0 },
  hire_rate: { type: DataTypes.INTEGER, defaultValue: 0 },
  avg_contract_duration: { type: DataTypes.INTEGER, defaultValue: 0 },
  repeat_hire_rate: { type: DataTypes.FLOAT, defaultValue: 0 },

  client_rating: { type: DataTypes.FLOAT, defaultValue: 0 },
  total_reviews_received: { type: DataTypes.INTEGER, defaultValue: 0 },
  payment_verification_score: { type: DataTypes.INTEGER, defaultValue: 0 },

  payment_verified: { type: DataTypes.BOOLEAN, defaultValue: false },
  id_verified: { type: DataTypes.BOOLEAN, defaultValue: false },
  company_verified: { type: DataTypes.BOOLEAN, defaultValue: false },
  verification_level: {
    type: DataTypes.ENUM("basic", "verified", "trusted", "premium"),
    defaultValue: "basic",
  },

  linkedin: { type: DataTypes.STRING, allowNull: true },
  twitter: { type: DataTypes.STRING, allowNull: true },
  facebook: { type: DataTypes.STRING, allowNull: true },
  instagram: { type: DataTypes.STRING, allowNull: true },

  preferred_communication_methods: { type: DataTypes.TEXT, defaultValue: "[]" },
  response_time_preference: { type: DataTypes.INTEGER, defaultValue: 24 },
  meeting_availability: { type: DataTypes.TEXT, defaultValue: "[]" },

  project_management_tools: { type: DataTypes.TEXT, defaultValue: "[]" },
  team_collaboration_tools: { type: DataTypes.TEXT, defaultValue: "[]" },

  profile_views: { type: DataTypes.INTEGER, defaultValue: 0 },
  jobs_posted: { type: DataTypes.INTEGER, defaultValue: 0 },
  invitations_sent: { type: DataTypes.INTEGER, defaultValue: 0 },
  applications_received: { type: DataTypes.INTEGER, defaultValue: 0 },

  preferred_freelancer_level: {
    type: DataTypes.ENUM("entry", "intermediate", "expert", "any"),
    defaultValue: "any",
  },
  preferred_location_type: {
    type: DataTypes.ENUM("local", "remote", "hybrid", "any"),
    defaultValue: "any",
  },

  badges: { type: DataTypes.TEXT, defaultValue: "[]" },
  is_top_client: { type: DataTypes.BOOLEAN, defaultValue: false },
  is_featured_client: { type: DataTypes.BOOLEAN, defaultValue: false },

  profile_strength: { type: DataTypes.INTEGER, defaultValue: 0 },
  profile_completion_percentage: { type: DataTypes.INTEGER, defaultValue: 0 },

  last_profile_update: { type: DataTypes.DATE, allowNull: true },
  member_since: { type: DataTypes.DATE, allowNull: true },
  verification_document_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  client_type: {
    type: DataTypes.ENUM("individual", "small_business", "enterprise"),
    defaultValue: "individual",
  },
  commercial_register_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  commercial_register_image: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  tax_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
});

export default ClientProfile;
