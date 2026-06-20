import dotenv from "dotenv";
dotenv.config();
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const SibApiV3Sdk = require("sib-api-v3-sdk");

console.log("🔑 BREVO KEY:", process.env.BREVO_API_KEY?.substring(0, 20));

const defaultClient = SibApiV3Sdk.ApiClient.instance;
defaultClient.authentications["api-key"].apiKey = process.env.BREVO_API_KEY;
const apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();

const sendEmail = async (to, subject, html) => {
  const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
  sendSmtpEmail.to = Array.isArray(to) ? to.map(e => ({ email: e })) : [{ email: to }];
  sendSmtpEmail.sender = { email: "wafaj2017@gmail.com", name: "iPal" };
  sendSmtpEmail.subject = subject;
  sendSmtpEmail.htmlContent = html;
  await apiInstance.sendTransacEmail(sendSmtpEmail);
};

export const sendVerificationEmail = async (to, code) => {
  try {
    await sendEmail(to, "Verify your email - iPal", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">Welcome to iPal!</h2>
        <p>Thank you for signing up. Please verify your email address using the code below:</p>
        <div style="background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 32px; letter-spacing: 5px; border-radius: 8px; margin: 20px 0;">
          <b>${code}</b>
        </div>
        <p>This code will expire in 10 minutes.</p>
        <p>If you didn't create an account with iPal, please ignore this email.</p>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Verification email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send verification email:", err.message);
    throw err;
  }
};

export const sendAccountCreatedEmail = async (to, role, password) => {
  try {
    await sendEmail(to, "Your iPal account has been created", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">Your account is ready!</h2>
        <p>An administrator created your iPal account with the role <strong>${role}</strong>.</p>
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Email:</strong> ${to}</p>
          <p><strong>Password:</strong> ${password}</p>
        </div>
        <p>Please change your password after first login for security.</p>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Account creation email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send account creation email:", err.message);
    throw err;
  }
};

export const sendResetPasswordEmail = async (email, resetUrl) => {
  try {
    await sendEmail(email, "Reset Your Password - iPal", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">Reset Your Password</h2>
        <p>You requested to reset your password for your iPal account.</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="display: inline-block; padding: 12px 30px; background-color: #5B5BD6; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">
            Reset Password
          </a>
        </div>
        <p>Or copy this link: <br/> <a href="${resetUrl}">${resetUrl}</a></p>
        <p>This link will expire in 1 hour.</p>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Reset password email sent to", email);
  } catch (err) {
    console.error("❌ Failed to send reset password email:", err.message);
    throw err;
  }
};

export const sendResetCodeEmail = async (email, code) => {
  try {
    await sendEmail(email, "Reset Your Password - iPal", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">Reset Your Password</h2>
        <p>Use the code below to reset your password:</p>
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; letter-spacing: 5px; border-radius: 8px; margin: 20px 0;">
          <b>${code}</b>
        </div>
        <p>This code will expire in <b>1 hour</b>.</p>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Reset code email sent to", email);
  } catch (err) {
    console.error("❌ Failed to send reset code email:", err.message);
  }
};

export const sendDisputeCreatedEmail = async (to, dispute) => {
  try {
    await sendEmail(to, "New Dispute Created - iPal", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">New Dispute Created</h2>
        <p>A new dispute has been created for contract #${dispute.ContractId}.</p>
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Title:</strong> ${dispute.title}</p>
          <p><strong>Description:</strong> ${dispute.description}</p>
          <p><strong>Initiated by:</strong> ${dispute.InitiatedBy}</p>
        </div>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Dispute notification email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send dispute notification email:", err.message);
    throw err;
  }
};

export const sendDisputeResolvedEmail = async (to, dispute, resolution) => {
  try {
    await sendEmail(to, "Dispute Resolved - iPal", `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #5B5BD6;">Dispute Resolved</h2>
        <p>Your dispute for contract #${dispute.ContractId} has been resolved.</p>
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Title:</strong> ${dispute.title}</p>
          <p><strong>Resolution:</strong> ${resolution}</p>
          ${dispute.refund_amount ? `<p><strong>Refund Amount:</strong> $${dispute.refund_amount}</p>` : ""}
          ${dispute.admin_notes ? `<p><strong>Admin Notes:</strong> ${dispute.admin_notes}</p>` : ""}
        </div>
        <hr/>
        <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
      </div>
    `);
    console.log("✅ Dispute resolution email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send dispute resolution email:", err.message);
    throw err;
  }
};