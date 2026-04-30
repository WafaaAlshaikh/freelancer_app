import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { User } from "../models/index.js";
import { FreelancerProfile } from "../models/index.js";
import { Wallet } from "../models/index.js";
import {
  sendVerificationEmail,
  sendResetPasswordEmail,
  sendResetCodeEmail,
} from "../utils/mailer.js";

dotenv.config();

const router = express.Router();

router.post("/signup", async (req, res) => {
  const { name, email, password, role } = req.body;

  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const verificationCode = Math.floor(100000 + Math.random() * 900000);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      role: role || "client",
      is_verified: false,
      verification_code: verificationCode,
    });

    if (role === "freelancer") {
      await FreelancerProfile.create({
        UserId: newUser.id,
        title: "",
        bio: "",
        location: "",
        experience_years: 0,
        skills: "[]",
        rating: 0,
      });

      await Wallet.create({
        UserId: newUser.id,
        balance: 0,
      });
    }

    await sendVerificationEmail(email, verificationCode);

    res.status(201).json({
      message: "✅ User created! Verification code sent to email",
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/verify", async (req, res) => {
  const { email, code } = req.body;

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (user.is_verified) return res.json({ message: "User already verified" });

    if (user.verification_code != code) {
      return res.status(400).json({ message: "Invalid verification code" });
    }

    user.is_verified = true;
    user.verification_code = null;
    await user.save();

    res.json({ message: "✅ Email verified successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res
      .status(400)
      .json({ message: "❌ Email and password are required" });
  }

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: "❌ Invalid credentials" });
    }

    if (!user.is_verified) {
      return res
        .status(403)
        .json({ message: "Please verify your email first" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "❌ Invalid credentials" });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    res.json({
      message: "✅ Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "❌ Server error" });
  }
});

router.post("/forgot-password", async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(200).json({
        message: "If your email is registered, you will receive a reset code",
      });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    user.reset_password_code = resetCode;
    user.reset_password_expires = new Date(Date.now() + 3600000);

    await user.save();

    const checkUser = await User.findOne({ where: { email } });
    console.log("✅ Saved code:", checkUser.reset_password_code);
    console.log("✅ Expires at:", checkUser.reset_password_expires);

    await sendResetCodeEmail(email, resetCode);

    res.status(200).json({
      message: "Reset code sent to your email",
      hasCode: true,
    });
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/verify-reset-code", async (req, res) => {
  const { email, code } = req.body;

  console.log("=== VERIFY RESET CODE ===");
  console.log("Email:", email);
  console.log("Code received:", code);
  console.log("Code type:", typeof code);

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    console.log("Code in DB:", user.reset_password_code);
    console.log("Code in DB type:", typeof user.reset_password_code);
    console.log("Expires at:", user.reset_password_expires);
    console.log("Current time:", new Date());

    if (!user.reset_password_code) {
      return res
        .status(400)
        .json({
          message: "No reset request found. Please request a new code.",
        });
    }

    if (new Date() > new Date(user.reset_password_expires)) {
      return res
        .status(400)
        .json({ message: "Reset code has expired. Please request a new one." });
    }

    if (String(user.reset_password_code).trim() !== String(code).trim()) {
      console.log("Code mismatch:", user.reset_password_code, "!=", code);
      return res.status(400).json({ message: "Invalid reset code" });
    }

    console.log("✅ Code verified successfully");

    res.status(200).json({
      message: "Code verified successfully",
      valid: true,
    });
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/reset-password", async (req, res) => {
  const { email, code, newPassword, confirmPassword } = req.body;

  if (!email || !code || !newPassword || !confirmPassword) {
    return res.status(400).json({ message: "All fields are required" });
  }

  if (newPassword !== confirmPassword) {
    return res.status(400).json({ message: "Passwords do not match" });
  }

  if (newPassword.length < 6) {
    return res
      .status(400)
      .json({ message: "Password must be at least 6 characters" });
  }

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.reset_password_code !== code) {
      return res.status(400).json({ message: "Invalid reset code" });
    }

    if (new Date() > user.reset_password_expires) {
      return res.status(400).json({ message: "Reset code has expired" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    user.password = hashedPassword;
    user.reset_password_code = null;
    user.reset_password_expires = null;
    await user.save();

    res.status(200).json({
      message: "Password reset successfully!",
      success: true,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});
export default router;
