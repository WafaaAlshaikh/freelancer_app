// services/esignatureService.js
import { User, Contract, Project } from "../models/index.js";
import { sendVerificationEmail } from "./emailService.js";
import crypto from 'crypto';

class ESignatureService {
  
  static async generateVerificationCode(userId, contractId) {
    const code = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); 
    
    if (!global.verificationCodes) global.verificationCodes = new Map();
    
    global.verificationCodes.set(`${userId}_${contractId}`, {
      code,
      expiresAt,
      attempts: 0
    });
    
    console.log(`✅ Verification code generated for user ${userId}: ${code}`);
    
    return code;
  }

  static async sendVerificationCodes(user, contract) {
    try {
      const code = await this.generateVerificationCode(user.id, contract.id);
      
      await sendVerificationEmail(user.email, code);
      
      console.log(`📧 Verification email sent to ${user.email}`);

      return { 
        success: true, 
        message: "Verification code sent to your email",
        expiresIn: 600 
      };
      
    } catch (error) {
      console.error("❌ Error sending verification code:", error);
      throw error;
    }
  }

  static async verifyAndSign(contractId, userId, inputCode) {
    const key = `${userId}_${contractId}`;
    const storedData = global.verificationCodes?.get(key);
    
    if (!storedData) {
      return { 
        success: false, 
        message: "No verification code requested or code expired" 
      };
    }

    if (storedData.attempts >= 5) {
      global.verificationCodes.delete(key);
      return { 
        success: false, 
        message: "Maximum attempts exceeded. Please request a new code" 
      };
    }

    storedData.attempts++;
    global.verificationCodes.set(key, storedData);

    if (new Date() > storedData.expiresAt) {
      global.verificationCodes.delete(key);
      return { 
        success: false, 
        message: "Code expired. Please request a new code" 
      };
    }

    if (storedData.code !== inputCode) {
      return { 
        success: false, 
        message: `Invalid code. You have ${5 - storedData.attempts} attempts remaining` 
      };
    }

    const contract = await Contract.findByPk(contractId);
    
    if (!contract) {
      return { success: false, message: "Contract not found" };
    }

    if (contract.ClientId === userId) {
      await contract.update({
        client_signed_at: new Date(),
        client_verification_method: 'otp',
        client_verification_data: JSON.stringify({
          ip: 'user_ip',
          user_agent: 'user_agent',
          verified_at: new Date()
        }),
        status: contract.freelancer_signed_at ? 'active' : 'pending_freelancer'
      });
    } else if (contract.FreelancerId === userId) {
      await contract.update({
        freelancer_signed_at: new Date(),
        freelancer_verification_method: 'otp',
        freelancer_verification_data: JSON.stringify({
          ip: 'user_ip',
          user_agent: 'user_agent',
          verified_at: new Date()
        }),
        status: contract.client_signed_at ? 'active' : 'pending_client'
      });
    }

    global.verificationCodes.delete(key);

    if (contract.client_signed_at && contract.freelancer_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: 'active'
      });
      
      await Project.update(
        { status: 'in_progress' },
        { where: { id: contract.ProjectId } }
      );
    }

    return { 
      success: true, 
      message: "Contract signed successfully", 
      contract 
    };
  }
}

export default ESignatureService;