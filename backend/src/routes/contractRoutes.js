// routes/contractRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { Contract, Project, User } from "../models/index.js";
import ESignatureService from "../services/esignatureService.js";
import NotificationService from "../services/notificationService.js";

const router = express.Router();

router.get("/:contractId", protect, async (req, res) => {
  try {
    console.log(`📥 Fetching contract ${req.params.contractId} for user ${req.user.id}`);
    
    const contract = await Contract.findByPk(req.params.contractId, {
      include: [
        { 
          model: Project,
          include: [
            {
              model: User,
              as: 'client',
              attributes: ['id', 'name', 'avatar']
            }
          ]
        },
        { 
          model: User, 
          as: 'freelancer', 
          attributes: ['id', 'name', 'avatar'] 
        },
        { 
          model: User, 
          as: 'client', 
          attributes: ['id', 'name', 'avatar'] 
        }
      ]
    });
    
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }
    
    if (contract.ClientId !== req.user.id && contract.FreelancerId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }
    
    res.json(contract);
  } catch (error) {
    console.error("❌ Error in getContract:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.post("/:contractId/sign", protect, async (req, res) => {
  try {
    console.log(`📝 Signing contract ${req.params.contractId} for user ${req.user.id}`);
    
    const contract = await Contract.findByPk(req.params.contractId);
    
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }
    
    let updatedContract;
    
    if (contract.ClientId === req.user.id) {
      await contract.update({
        client_signed_at: new Date(),
        status: contract.freelancer_signed_at ? 'active' : 'pending_freelancer'
      });
    } else if (contract.FreelancerId === req.user.id) {
      await contract.update({
        freelancer_signed_at: new Date(),
        status: contract.client_signed_at ? 'active' : 'pending_client'
      });
    } else {
      return res.status(403).json({ message: "Unauthorized" });
    }

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

    res.json({
      message: "Contract signed successfully",
      contract
    });
  } catch (error) {
    console.error("❌ Error signing contract:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.post("/:contractId/request-code", protect, async (req, res) => {
  try {
    console.log(`📱 Requesting verification code for contract ${req.params.contractId}`);
    
    const contract = await Contract.findByPk(req.params.contractId);
    
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    if (contract.ClientId !== req.user.id && contract.FreelancerId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    const user = await User.findByPk(req.user.id);
    
    const result = await ESignatureService.sendVerificationCodes(user, contract);
    
    res.json({
      success: true,
      message: "تم إرسال رمز التحقق إلى بريدك الإلكتروني",
      ...result
    });
    
  } catch (error) {
    console.error("❌ Error requesting code:", error);
    res.status(500).json({ 
      success: false, 
      message: "Server error", 
      error: error.message 
    });
  }
});

router.post("/:contractId/verify-and-sign", protect, async (req, res) => {
  try {
    const { code } = req.body;
    
    console.log(`🔐 Verifying code for contract ${req.params.contractId}`);
    
    const result = await ESignatureService.verifyAndSign(
      req.params.contractId,
      req.user.id,
      code
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    if (result.contract) {
      const contract = result.contract;
      
      const otherPartyId = contract.ClientId === req.user.id 
        ? contract.FreelancerId 
        : contract.ClientId;
      
      const user = await User.findByPk(req.user.id);
      
      await NotificationService.createNotification({
        userId: otherPartyId,
        type: 'contract_signed',
        title: 'Contract Signed',
        body: `${user.name} has signed the contract`,
        data: {
          contractId: contract.id,
          screen: 'contract',
        },
      });
      
      if (contract.client_signed_at && contract.freelancer_signed_at) {
        await NotificationService.createNotification({
          userId: contract.ClientId,
          type: 'contract_created',
          title: 'Contract Active',
          body: 'The contract is now active. You can start working!',
          data: {
            contractId: contract.id,
            screen: 'contract',
          },
        });
        
        await NotificationService.createNotification({
          userId: contract.FreelancerId,
          type: 'contract_created',
          title: 'Contract Active',
          body: 'The contract is now active. Start working on the project!',
          data: {
            contractId: contract.id,
            screen: 'contract',
          },
        });
      }
    }

    res.json(result);
    
  } catch (error) {
    console.error("❌ Error verifying code:", error);
    res.status(500).json({ 
      success: false, 
      message: "Server error", 
      error: error.message 
    });
  }
});


export default router;