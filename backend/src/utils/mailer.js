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
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "Verify your email",
      html: `<p>Your verification code is: <b>${code}</b></p>`,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Verification email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send email:", err.message);
  }
};