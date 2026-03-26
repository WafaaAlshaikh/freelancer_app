// services/emailService.js
import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export const sendVerificationEmail = async (to, code) => {
  try {
    console.log(`📧 Preparing to send email to ${to} with code: ${code}`);
    
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "🔐 Verification Code for Contract Signing",
      html: `
        <div dir="ltr" style="font-family: Arial; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #14A800; text-align: center;">Electronic Contract Signing</h2>
          <p>Hello,</p>
          <p>You requested to sign a contract on the platform. Use the following code to complete the signing process:</p>
          <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 5px;">
            <h1 style="font-size: 48px; letter-spacing: 5px; color: #14A800; margin: 0;">${code}</h1>
          </div>
          <p>This code is valid for only <strong>10 minutes</strong>.</p>
          <p>If you didn't request this, please ignore this message.</p>
          <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
          <p style="color: #999; font-size: 12px; text-align: center;">This is an automated message, please do not reply.</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log("✅ Verification email sent to", to, "Message ID:", info.messageId);
    return true;
  } catch (err) {
    console.error("❌ Failed to send email:", err.message);
    console.error("Full error:", err);
    throw err;
  }
};