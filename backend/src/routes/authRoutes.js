import express from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { User } from "../models/index.js";
import { FreelancerProfile } from "../models/index.js";
import { Wallet } from "../models/index.js";
import { sendVerificationEmail } from "../utils/mailer.js";

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

export default router;
