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
};
