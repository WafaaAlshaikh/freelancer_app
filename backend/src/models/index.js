// src/models/index.js
import { sequelize } from "../config/db.js";

import User from "./User.js";
import FreelancerProfile from "./FreelancerProfile.js";
import Project from "./Project.js";
import Proposal from "./Proposal.js";
import Contract from "./Contract.js";
import Wallet from "./Wallet.js";
import Message from "./Message.js";
import Rating from "./Rating.js";
import Portfolio from "./Portfolio.js";
import Notification from "./Notification.js";
import Transaction from "./Transaction.js";
import Chat from "./Chat.js";
import ClientProfile from "./ClientProfile.js";
import SkillTest from "./SkillTest.js";
import UserSkillTest from "./UserSkillTest.js";
import Badge from "./Badge.js";
import UserBadge from "./UserBadge.js";
import SubscriptionPlan from "./SubscriptionPlan.js";
import UserSubscription from "./UserSubscription.js";
import Coupon from "./Coupon.js";
import Invoice from "./Invoice.js";
import SubscriptionLog from "./SubscriptionLog.js";
import ProjectAlert from "./ProjectAlert.js";
import SavedFilter from "./SavedFilter.js";
import WorkSubmission from "./WorkSubmission.js";
import UserFavorite from "./UserFavorite.js";
import FinancialTransaction from "./FinancialTransaction.js";

User.hasOne(UserSubscription, { foreignKey: "user_id" });
UserSubscription.belongsTo(User, { foreignKey: "user_id" });

SubscriptionPlan.hasMany(UserSubscription, { foreignKey: "plan_id" });
UserSubscription.belongsTo(SubscriptionPlan, { foreignKey: "plan_id" });

SkillTest.belongsTo(Badge, { foreignKey: "badge_id" });
Badge.hasMany(SkillTest, { foreignKey: "badge_id" });

UserSkillTest.belongsTo(User, { foreignKey: "user_id" });
User.hasMany(UserSkillTest, { foreignKey: "user_id" });

UserSkillTest.belongsTo(SkillTest, { foreignKey: "test_id" });
SkillTest.hasMany(UserSkillTest, { foreignKey: "test_id" });

User.hasOne(ClientProfile, { foreignKey: "UserId" });
ClientProfile.belongsTo(User, { foreignKey: "UserId" });

User.hasMany(Notification, { foreignKey: "userId" });
Notification.belongsTo(User, { foreignKey: "userId" });

User.hasOne(FreelancerProfile);
FreelancerProfile.belongsTo(User);

User.hasMany(Project, { as: "clientProjects", foreignKey: "UserId" });
Project.belongsTo(User, { as: "client", foreignKey: "UserId" });

User.hasMany(Proposal, {
  foreignKey: "UserId",
  as: "freelancerProposals",
});
Proposal.belongsTo(User, {
  foreignKey: "UserId",
  as: "freelancer",
});
Proposal.belongsTo(Project);

Project.hasOne(Contract);
Contract.belongsTo(Project);

Contract.belongsTo(User, { as: "freelancer", foreignKey: "FreelancerId" });
User.hasMany(Contract, {
  as: "freelancerContracts",
  foreignKey: "FreelancerId",
});

Contract.belongsTo(User, { as: "client", foreignKey: "ClientId" });
User.hasMany(Contract, { as: "clientContracts", foreignKey: "ClientId" });

User.hasOne(Wallet);
Wallet.belongsTo(User);

Wallet.hasMany(Transaction, { foreignKey: "wallet_id" });
Transaction.belongsTo(Wallet, { foreignKey: "wallet_id" });

Rating.belongsTo(Contract, { foreignKey: "contractId" });
Contract.hasMany(Rating, { foreignKey: "contractId" });

Rating.belongsTo(User, { as: "fromUser", foreignKey: "fromUserId" });
User.hasMany(Rating, { as: "ratingsGiven", foreignKey: "fromUserId" });

Rating.belongsTo(User, { as: "toUser", foreignKey: "toUserId" });
User.hasMany(Rating, { as: "ratingsReceived", foreignKey: "toUserId" });

Proposal.belongsTo(FreelancerProfile, {
  foreignKey: "UserId",
  as: "profile",
});

FreelancerProfile.hasMany(Proposal, {
  foreignKey: "UserId",
  as: "proposals",
});

User.hasMany(Portfolio, { foreignKey: "UserId" });
Portfolio.belongsTo(User, { foreignKey: "UserId" });

Chat.hasMany(Message, { foreignKey: "chat_id" });
Message.belongsTo(Chat, { foreignKey: "chat_id" });

UserFavorite.belongsTo(Project, { foreignKey: "project_id" });
Project.hasMany(UserFavorite, { foreignKey: "project_id" });

UserFavorite.belongsTo(User, { foreignKey: "user_id" });
User.hasMany(UserFavorite, { foreignKey: "user_id" });

export {
  sequelize,
  User,
  FreelancerProfile,
  Project,
  Proposal,
  Contract,
  Wallet,
  Message,
  Rating,
  Portfolio,
  Notification,
  Transaction,
  Chat,
  ClientProfile,
  SkillTest,
  UserSkillTest,
  Badge,
  UserBadge,
  SubscriptionPlan,
  UserSubscription,
  Coupon,
  Invoice,
  SubscriptionLog,
  ProjectAlert,
  SavedFilter,
  WorkSubmission,
  UserFavorite,
  FinancialTransaction,
};
