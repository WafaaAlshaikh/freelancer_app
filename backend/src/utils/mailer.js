import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || "587"),
  secure: process.env.SMTP_SECURE === "true",
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

transporter.verify((error, success) => {
  if (error) {
    console.error("❌ SMTP connection error:", error);
  } else {
    console.log("✅ SMTP server is ready to send emails");
  }
});

export const sendVerificationEmail = async (to, code) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "Verify your email - iPal",
      html: `
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
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Verification email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send verification email:", err.message);
    throw err;
  }
};

export const sendAccountCreatedEmail = async (to, role, password) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "Your iPal account has been created",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #5B5BD6;">Your account is ready!</h2>
          <p>An administrator created your iPal account with the role <strong>${role}</strong>.</p>
          <p>Use the credentials below to sign in and then change your password.</p>
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
            <p><strong>Email:</strong> ${to}</p>
            <p><strong>Password:</strong> ${password}</p>
          </div>
          <p>Please change your password after first login for security.</p>
          <p>If you did not expect this email, contact your administrator.</p>
          <hr/>
          <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Account creation email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send account creation email:", err.message);
    throw err;
  }
};

export const sendResetPasswordEmail = async (email, resetUrl) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to: email,
      subject: "Reset Your Password - iPal",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #5B5BD6;">Reset Your Password</h2>
          <p>You requested to reset your password for your iPal account.</p>
          <p>Click the button below to reset your password:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetUrl}" style="display: inline-block; padding: 12px 30px; background-color: #5B5BD6; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">
              Reset Password
            </a>
          </div>
          <p>Or copy this link: <br/> <a href="${resetUrl}">${resetUrl}</a></p>
          <p>This link will expire in 1 hour.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr/>
          <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Reset password email sent to", email);
  } catch (err) {
    console.error("❌ Failed to send reset password email:", err.message);
    throw err;
  }
};

export const sendResetCodeEmail = async (email, code) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to: email,
      subject: "Reset Your Password - iPal",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #5B5BD6;">Reset Your Password</h2>
          <p>You requested to reset your password for your iPal account.</p>
          <p>Use the code below to reset your password:</p>
          <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; letter-spacing: 5px; border-radius: 8px; margin: 20px 0;">
            <b>${code}</b>
          </div>
          <p>This code will expire in <b>1 hour</b>.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr/>
          <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Reset code email sent to", email);
  } catch (err) {
    console.error("❌ Failed to send reset code email:", err.message);
  }
};

export const sendDisputeCreatedEmail = async (to, dispute) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "New Dispute Created - iPal",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #5B5BD6;">New Dispute Created</h2>
          <p>A new dispute has been created for contract #${dispute.ContractId}.</p>
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
            <p><strong>Title:</strong> ${dispute.title}</p>
            <p><strong>Description:</strong> ${dispute.description}</p>
            <p><strong>Initiated by:</strong> ${dispute.InitiatedBy}</p>
          </div>
          <p>Please review the dispute and take appropriate action.</p>
          <hr/>
          <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Dispute notification email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send dispute notification email:", err.message);
    throw err;
  }
};

export const sendDisputeResolvedEmail = async (to, dispute, resolution) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject: "Dispute Resolved - iPal",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #5B5BD6;">Dispute Resolved</h2>
          <p>Your dispute for contract #${dispute.ContractId} has been resolved.</p>
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
            <p><strong>Title:</strong> ${dispute.title}</p>
            <p><strong>Resolution:</strong> ${resolution}</p>
            ${dispute.refund_amount ? `<p><strong>Refund Amount:</strong> \$${dispute.refund_amount}</p>` : ''}
            ${dispute.admin_notes ? `<p><strong>Admin Notes:</strong> ${dispute.admin_notes}</p>` : ''}
          </div>
          <p>If you have any questions, please contact support.</p>
          <hr/>
          <p style="font-size: 12px; color: #666;">iPal - Your Freelancing Platform</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Dispute resolution email sent to", to);
  } catch (err) {
    console.error("❌ Failed to send dispute resolution email:", err.message);
    throw err;
  }
};
