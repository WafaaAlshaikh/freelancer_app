// services/contractService.js
import { Contract, Project, User, Wallet, Transaction } from "../models/index.js";
import { Op } from "sequelize";

class ContractService {

  static async createContractDraft(projectId, freelancerId, clientId, agreed_amount) {
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
        agreed_amount
      });

      const contract = await Contract.create({
        ProjectId: projectId,
        FreelancerId: freelancerId,
        ClientId: clientId,
        agreed_amount,
        contract_document: contractDocument,
        status: 'draft',
        terms: 'Standard terms and conditions apply.',
        milestones: JSON.stringify([
          {
            title: 'Project Start',
            description: 'Begin work on project',
            amount: agreed_amount * 0.3,
            due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            status: 'pending'
          },
          {
            title: 'Milestone 1',
            description: 'First deliverable',
            amount: agreed_amount * 0.4,
            due_date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
            status: 'pending'
          },
          {
            title: 'Final Delivery',
            description: 'Complete project',
            amount: agreed_amount * 0.3,
            due_date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
            status: 'pending'
          }
        ])
      });

      return contract;
    } catch (error) {
      throw error;
    }
  }


  static generateContractDocument({ projectId, freelancerId, clientId, agreed_amount }) {
    const date = new Date().toLocaleDateString('ar-SA');
    
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; }
          h1 { color: #14A800; text-align: center; }
          h2 { color: #333; }
          .signature { margin-top: 50px; }
          .terms { margin: 20px 0; }
        </style>
      </head>
      <body>
        <h1>اتفاقية تعاقد بين عميل ومستقل</h1>
        
        <p><strong>تاريخ الاتفاقية:</strong> ${date}</p>
        
        <h2>أطراف الاتفاقية</h2>
        <p><strong>الطرف الأول (العميل):</strong> Client ID: ${clientId}</p>
        <p><strong>الطرف الثاني (المستقل):</strong> Freelancer ID: ${freelancerId}</p>
        
        <h2>بنود الاتفاقية</h2>
        <div class="terms">
          <p><strong>أولاً: موضوع العقد</strong><br>
          يتعهد الطرف الثاني بتنفيذ المشروع رقم ${projectId} وفقاً للمواصفات المتفق عليها.</p>
          
          <p><strong>ثانياً: المقابل المالي</strong><br>
          قيمة العقد: $${agreed_amount} (فقط ${agreed_amount} دولار أمريكي).</p>
          
          <p><strong>ثالثاً: طريقة الدفع</strong><br>
          يتم الدفع عبر محفظة المنصة الإلكترونية على دفعات مرتبطة بالمهام المنجزة.</p>
          
          <p><strong>رابعاً: التزامات الطرف الأول (العميل)</strong><br>
          - توفير جميع المواد والمستندات اللازمة للعمل.<br>
          - الرد على استفسارات المستقل في الوقت المناسب.<br>
          - دفع الدفعات المستحقة عند إنجاز المهام.</p>
          
          <p><strong>خامساً: التزامات الطرف الثاني (المستقل)</strong><br>
          - تنفيذ العمل بجودة عالية وفقاً للمواصفات المتفق عليها.<br>
          - الالتزام بالجدول الزمني المتفق عليه.<br>
          - تقديم تقارير دورية عن تقدم العمل.</p>
          
          <p><strong>سادساً: ملكية العمل</strong><br>
          تنتقل ملكية العمل النهائي إلى العميل بعد استلامه واستكمال الدفعات المالية.</p>
          
          <p><strong>سابعاً: confidentiality</strong><br>
          يلتزم الطرف الثاني بعدم الإفصاح عن أي معلومات خاصة بالمشروع.</p>
          
          <p><strong>ثامناً: حل النزاعات</strong><br>
          في حال نشوب أي نزاع، يتم اللجوء إلى إدارة المنصة للتحكيم.</p>
        </div>
        
        <h2>توقيع الأطراف</h2>
        <div class="signature">
          <p>_________________________ :توقيع العميل</p>
          <p>_________________________ :توقيع المستقل</p>
        </div>
        
        <p><small>تم إنشاء هذه الاتفاقية إلكترونياً عبر المنصة.</small></p>
      </body>
      </html>
    `;
  }

 
  static async signContractByClient(contractId, clientId) {
    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: clientId }
    });

    if (!contract) {
      throw new Error('Contract not found');
    }

    if (contract.status !== 'draft' && contract.status !== 'pending_freelancer') {
      throw new Error('Contract cannot be signed at this stage');
    }

    await contract.update({
      client_signed_at: new Date(),
      status: contract.freelancer_signed_at ? 'active' : 'pending_freelancer'
    });

    if (contract.freelancer_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: 'active'
      });
      
      await Project.update(
        { status: 'in_progress' },
        { where: { id: contract.ProjectId } }
      );
    }

    return contract;
  }


  static async signContractByFreelancer(contractId, freelancerId) {
    const contract = await Contract.findOne({
      where: { id: contractId, FreelancerId: freelancerId }
    });

    if (!contract) {
      throw new Error('Contract not found');
    }

    if (contract.status !== 'draft' && contract.status !== 'pending_client') {
      throw new Error('Contract cannot be signed at this stage');
    }

    await contract.update({
      freelancer_signed_at: new Date(),
      status: contract.client_signed_at ? 'active' : 'pending_client'
    });

    if (contract.client_signed_at) {
      await contract.update({
        signed_at: new Date(),
        status: 'active'
      });
      
      await Project.update(
        { status: 'in_progress' },
        { where: { id: contract.ProjectId } }
      );
    }

    return contract;
  }


  static async addMilestone(contractId, milestoneData) {
    const contract = await Contract.findByPk(contractId);
    
    if (!contract) {
      throw new Error('Contract not found');
    }

    const milestones = contract.milestones;
    milestones.push({
      ...milestoneData,
      status: 'pending'
    });

    await contract.update({ milestones: JSON.stringify(milestones) });
    return contract;
  }


  static async updateMilestoneStatus(contractId, milestoneIndex, status) {
    const contract = await Contract.findByPk(contractId);
    
    if (!contract) {
      throw new Error('Contract not found');
    }

    const milestones = contract.milestones;
    if (milestones[milestoneIndex]) {
      milestones[milestoneIndex].status = status;
      
      if (status === 'completed') {
        milestones[milestoneIndex].completed_at = new Date();
      }
      
      await contract.update({ milestones: JSON.stringify(milestones) });
    }

    return contract;
  }


  static async addReview(contractId, userId, rating, review) {
    const contract = await Contract.findByPk(contractId);
    
    if (!contract) {
      throw new Error('Contract not found');
    }

    const updateData = {};
    
    if (userId === contract.ClientId) {
      updateData.client_rating = rating;
      updateData.client_review = review;
    } else if (userId === contract.FreelancerId) {
      updateData.freelancer_rating = rating;
      updateData.freelancer_review = review;
    } else {
      throw new Error('User not authorized');
    }

    await contract.update(updateData);
    return contract;
  }
}

export default ContractService;