// services/contractService.js
import { Contract, Project, User, Wallet, Transaction } from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "./notificationService.js";
class ContractService {
  static async createContractDraft(
    projectId,
    freelancerId,
    clientId,
    agreed_amount,
  ) {
    try {
      const existingContract = await Contract.findOne({
        where: { ProjectId: projectId },
      });

      if (existingContract) {
        throw new Error("Contract already exists for this project");
      }

      const contractDocument = this.generateContractDocument({
        projectId,
        freelancerId,
        clientId,
        agreed_amount,
      });

      const contract = await Contract.create({
        ProjectId: projectId,
        FreelancerId: freelancerId,
        ClientId: clientId,
        agreed_amount,
        contract_document: contractDocument,
        status: "draft",
        terms: "Standard terms and conditions apply.",
        milestones: JSON.stringify([
          {
            title: "Project Start",
            description: "Begin work on project",
            amount: Math.round(agreed_amount * 0.3),
            due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            status: "pending",
          },
          {
            title: "Milestone 1",
            description: "First deliverable",
            amount: Math.round(agreed_amount * 0.4),
            due_date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
            status: "pending",
          },
          {
            title: "Final Delivery",
            description: "Complete project",
            amount: Math.round(agreed_amount * 0.3),
            due_date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
            status: "pending",
          },
        ]),
      });

      await NotificationService.createNotification({
        userId: freelancerId,
        type: "contract_created",
        title: "New Contract Ready",
        body: "A contract has been created for you. Please review and sign.",
        data: {
          contractId: contract.id,
          projectId: projectId,
          screen: "contract",
        },
      });

      await NotificationService.createNotification({
        userId: clientId,
        type: "contract_created",
        title: "Contract Ready for Signature",
        body: "Your contract is ready. Please review and sign.",
        data: {
          contractId: contract.id,
          projectId: projectId,
          screen: "contract",
        },
      });

      return contract;
    } catch (error) {
      throw error;
    }
  }


  static generateContractDocument({
    projectId,
    freelancerId,
    clientId,
    agreed_amount,
  }) {
    const date = new Date().toLocaleDateString("en-US");
    const safeAmount = agreed_amount || 0;

    return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
        h1 { color: #14A800; text-align: center; }
        h2 { color: #333; margin-top: 20px; }
        .signature { margin-top: 50px; }
        .terms { margin: 20px 0; }
        .terms p { margin: 10px 0; }
      </style>
    </head>
    <body>
      <h1>FREELANCE CONTRACT AGREEMENT</h1>
      
      <p><strong>Date:</strong> ${date}</p>
      
      <h2>Parties</h2>
      <p><strong>Client ID:</strong> ${clientId}</p>
      <p><strong>Freelancer ID:</strong> ${freelancerId}</p>
      
      <h2>Project Details</h2>
      <p><strong>Project ID:</strong> ${projectId}</p>
      <p><strong>Contract Amount:</strong> $${safeAmount}</p>
      
      <h2>Terms and Conditions</h2>
      <div class="terms">
        <p><strong>1. Scope of Work:</strong> The Freelancer agrees to complete the project as described in the project details.</p>
        <p><strong>2. Payment:</strong> The Client agrees to pay the total amount of $${safeAmount} according to the milestone schedule.</p>
        <p><strong>3. Delivery:</strong> The Freelancer agrees to deliver the work according to the agreed timeline.</p>
        <p><strong>4. Intellectual Property:</strong> Upon full payment, all rights transfer to the Client.</p>
        <p><strong>5. Confidentiality:</strong> Both parties agree to keep all project information confidential.</p>
      </div>
      
      <h2>Signatures</h2>
      <div class="signature">
        <p>_________________________ : Client Signature</p>
        <p>_________________________ : Freelancer Signature</p>
      </div>
      
      <p><small>This contract was generated electronically on the platform.</small></p>
    </body>
    </html>
  `;
  }


  static async signContractByClient(contractId, clientId) {
    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: clientId },
    });

    if (!contract) {
      throw new Error("Contract not found");
    }

    if (
      contract.status !== "draft" &&
      contract.status !== "pending_freelancer"
    ) {
      throw new Error("Contract cannot be signed at this stage");
    }

    await contract.update({
      client_signed_at: new Date(),
      status: contract.freelancer_signed_at ? "active" : "pending_freelancer",
    });

    if (contract.freelancer_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: "active",
      });

      await Project.update(
        { status: "in_progress" },
        { where: { id: contract.ProjectId } },
      );
    }

    return contract;
  }

  
  static async signContractByFreelancer(contractId, freelancerId) {
    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: freelancerId },
    });

    if (!contract) {
      throw new Error("Contract not found");
    }

    if (contract.status !== "draft" && contract.status !== "pending_client") {
      throw new Error("Contract cannot be signed at this stage");
    }

    await contract.update({
      freelancer_signed_at: new Date(),
      status: contract.client_signed_at ? "active" : "pending_client",
    });

    if (contract.client_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: "active",
      });

      await Project.update(
        { status: "in_progress" },
        { where: { id: contract.ProjectId } },
      );
    }

    return contract;
  }


  static async createContractFromNegotiation({
    proposalId,
    freelancerId,
    clientId,
    agreedAmount,
    milestones,
    projectId,
  }) {
    try {
      const existingContract = await Contract.findOne({
        where: { ProjectId: projectId }
      });

      if (existingContract) {
        throw new Error('Contract already exists for this project');
      }

      const contractDocument = this.generateContractDocument({
        projectId,
        freelancerId,
        clientId,
        agreedAmount,
        milestones,
      });

      const contract = await Contract.create({
        ProjectId: projectId,
        FreelancerId: freelancerId,
        ClientId: clientId,
        agreed_amount: agreedAmount,
        contract_document: contractDocument,
        status: 'draft',
        terms: 'Standard terms and conditions apply.',
        milestones: JSON.stringify(milestones),
        payment_status: 'pending',
        escrow_status: 'pending',
      });

      await NotificationService.createNotification({
        userId: freelancerId,
        type: 'contract_created',
        title: 'Contract Ready for Review',
        body: 'The client has created a contract. Please review the milestones.',
        data: { contractId: contract.id, screen: 'contract' },
      });

      await NotificationService.createNotification({
        userId: clientId,
        type: 'contract_created',
        title: 'Contract Created',
        body: 'Contract has been created. Waiting for freelancer signature.',
        data: { contractId: contract.id, screen: 'contract' },
      });

      return contract;
    } catch (error) {
      throw error;
    }
  }


  static generateContractDocument({ projectId, freelancerId, clientId, agreedAmount, milestones }) {
    const date = new Date().toLocaleDateString('en-US');
    
    const milestonesHtml = milestones.map((m, i) => `
      <li>
        <strong>Milestone ${i + 1}: ${m.title}</strong><br>
        Description: ${m.description}<br>
        Amount: $${m.amount}<br>
        Due Date: ${new Date(m.due_date).toLocaleDateString()}
      </li>
    `).join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
          h1 { color: #14A800; text-align: center; }
          h2 { color: #333; margin-top: 20px; }
          .milestones { background: #f5f5f5; padding: 15px; border-radius: 8px; }
          .signature { margin-top: 50px; }
        </style>
      </head>
      <body>
        <h1>FREELANCE CONTRACT AGREEMENT</h1>
        
        <p><strong>Date:</strong> ${date}</p>
        
        <h2>Parties</h2>
        <p><strong>Client ID:</strong> ${clientId}</p>
        <p><strong>Freelancer ID:</strong> ${freelancerId}</p>
        
        <h2>Project Details</h2>
        <p><strong>Project ID:</strong> ${projectId}</p>
        <p><strong>Total Contract Amount:</strong> $${agreedAmount}</p>
        
        <h2>Milestones</h2>
        <div class="milestones">
          <ul>
            ${milestonesHtml}
          </ul>
        </div>
        
        <h2>Payment Terms</h2>
        <p>Payments will be released from escrow upon approval of each milestone.</p>
        
        <h2>Signatures</h2>
        <div class="signature">
          <p>_________________________ : Client Signature</p>
          <p>_________________________ : Freelancer Signature</p>
        </div>
        
        <p><small>This contract was generated electronically.</small></p>
      </body>
      </html>
    `;
  }
}



export default ContractService;
