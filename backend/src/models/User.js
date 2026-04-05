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
  cover_image: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  proposal_count_this_month: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  proposal_reset_date: {
    type: DataTypes.DATE,
    defaultValue: () => new Date(new Date().setDate(1)),
  },
  active_projects_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  tagline: {
    type: DataTypes.STRING(160),
    allowNull: true,
  },
  bio: {
    type: DataTypes.TEXT,
    allowNull: true,
  },

  location: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  country: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  timezone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  website: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  linkedin: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  github: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  twitter: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  is_verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  is_profile_public: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  verification_level: {
    type: DataTypes.ENUM("basic", "verified", "trusted", "premium"),
    defaultValue: "basic",
  },

  verification_code: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  reset_password_token: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  reset_password_expires: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  two_factor_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },

  last_seen: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  profile_views: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  last_login: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  login_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  email_notifications: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  push_notifications: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  marketing_emails: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },

  preferred_language: {
    type: DataTypes.STRING,
    defaultValue: "en",
  },
  currency: {
    type: DataTypes.STRING,
    defaultValue: "USD",
  },

  account_status: {
    type: DataTypes.ENUM("active", "inactive", "suspended", "deleted"),
    defaultValue: "active",
  },
  is_available: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },

  member_since: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  profile_completion_percentage: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },

  google_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  facebook_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  linkedin_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },

  referral_code: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  referred_by: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
});

export default User;
