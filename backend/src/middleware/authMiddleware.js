import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { User } from "../models/index.js";

dotenv.config();


export const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({ message: "❌ Not authorized, token missing" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    req.user = await User.findByPk(decoded.id, { attributes: { exclude: ["password"] } });

    if (!req.user) {
      return res.status(401).json({ message: "❌ User not found" });
    }

    next();
  } catch (error) {
    console.error(error);
    return res.status(401).json({ message: "❌ Not authorized, token failed" });
  }
};

/**
 * @param  {...string} roles 
 */
export const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: "❌ Forbidden: You don't have permission" });
    }
    next();
  };
};