// services/contractService.js
import {
  Contract,
  Project,
  User,
  Wallet,
  Transaction,
} from "../models/index.js";
import { Op } from "sequelize";
import NotificationService from "./notificationService.js";
import AIService from "./aiService.js";

class ContractService {
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
        where: { ProjectId: projectId },
      });

      if (existingContract) {
        throw new Error("Contract already exists for this project");
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
        status: "draft",
        terms: "Standard terms and conditions apply.",
        milestones: JSON.stringify(milestones),
        payment_status: "pending",
        escrow_status: "pending",
      });

      await NotificationService.createNotification({
        userId: freelancerId,
        type: "contract_created",
        title: "Contract Ready for Review",
        body: "The client has created a contract. Please review the milestones.",
        data: { contractId: contract.id, screen: "contract" },
      });

      await NotificationService.createNotification({
        userId: clientId,
        type: "contract_created",
        title: "Contract Created",
        body: "Contract has been created. Waiting for freelancer signature.",
        data: { contractId: contract.id, screen: "contract" },
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
    milestones = null,
  }) {
    const date = new Date().toLocaleDateString("en-US");
    const safeAmount = agreed_amount || 0;

    let milestonesHtml = "";
    let milestonesSection = "";

    if (milestones && milestones.length > 0) {
      milestonesHtml = milestones
        .map(
          (m, i) => `
        <li>
          <strong>Milestone ${i + 1}: ${m.title}</strong><br>
          Description: ${m.description}<br>
          Amount: $${m.amount}<br>
          Due Date: ${new Date(m.due_date).toLocaleDateString()}
        </li>
      `,
        )
        .join("");

      milestonesSection = `
        <h2>Milestones</h2>
        <div class="milestones">
          <ul>
            ${milestonesHtml}
          </ul>
        </div>
      `;
    }

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
        .milestones { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0; }
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
      
      ${
        milestonesSection ||
        `
      <h2>Payment Structure</h2>
      <div class="terms">
        <p><strong>Payment Schedule:</strong> The total amount of $${safeAmount} will be paid in milestones based on project progress.</p>
      </div>
      `
      }
      
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

  static async generateAIContract(
    projectId,
    freelancerId,
    clientId,
    agreedAmount,
    milestones,
  ) {
    try {
      const [project, freelancer, client] = await Promise.all([
        Project.findByPk(projectId, {
          include: [{ model: User, as: "client" }],
        }),
        User.findByPk(freelancerId, { attributes: ["id", "name", "email"] }),
        User.findByPk(clientId, { attributes: ["id", "name", "email"] }),
      ]);

      if (!project) throw new Error("Project not found");

      const projectSkills = this.parseSkills(project.skills);
      const projectCategory = project.category || "general";

      const prompt = `
Generate a professional freelance contract based on these details:

**Project:**
- Title: ${project.title}
- Description: ${project.description}
- Category: ${projectCategory}
- Required Skills: ${projectSkills.join(", ")}

**Parties:**
- Client: ${client?.name || "Client"} (${client?.email || "email"})
- Freelancer: ${freelancer?.name || "Freelancer"} (${freelancer?.email || "email"})

**Terms:**
- Total Amount: $${agreedAmount}
- Payment Milestones: ${JSON.stringify(milestones, null, 2)}

**Industry-Specific Clauses:**
${
  projectCategory === "software"
    ? "- Intellectual Property Rights for Software\n- Code Quality Standards\n- Testing and QA Requirements"
    : projectCategory === "design"
      ? "- Design Ownership and Usage Rights\n- Revision Limits\n- Source File Delivery"
      : "- Content Ownership\n- Publishing Rights\n- Revision Policy"
}

Generate a comprehensive, legally-sound contract in HTML format with:
1. Professional styling
2. All standard clauses (Scope, Payment, Timeline, IP, Confidentiality, Termination)
3. Industry-specific clauses based on category
4. Milestone breakdown with payment schedule
5. Signature sections for both parties
6. Date and contract number

Use professional legal language but make it clear and readable.
    `;

      const completion = await AIService.groqClient.chat.completions.create({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
        max_tokens: 4000,
      });

      const contractHtml = completion.choices[0].message.content;

      const cleanHtml = this.cleanContractHtml(
        contractHtml,
        project,
        freelancer,
        client,
        agreedAmount,
      );

      return cleanHtml;
    } catch (error) {
      console.error("❌ AI contract generation error:", error);
      return this.generateFallbackContract(
        project,
        freelancer,
        client,
        agreedAmount,
        milestones,
      );
    }
  }

  static cleanContractHtml(html, project, freelancer, client, amount) {
    const date = new Date().toLocaleDateString("en-US");
    const contractNumber = `CT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      line-height: 1.6;
      max-width: 900px;
      margin: 0 auto;
      padding: 40px;
      color: #333;
    }
    .header {
      text-align: center;
      margin-bottom: 40px;
      padding-bottom: 20px;
      border-bottom: 2px solid #14A800;
    }
    h1 { color: #14A800; margin: 0; font-size: 24px; }
    .contract-number { color: #666; font-size: 12px; margin-top: 5px; }
    h2 { color: #444; font-size: 18px; margin-top: 25px; border-left: 3px solid #14A800; padding-left: 12px; }
    .amount { font-size: 28px; font-weight: bold; color: #14A800; }
    .milestone {
      background: #f9f9f9;
      padding: 12px;
      margin: 10px 0;
      border-radius: 8px;
      border-left: 3px solid #14A800;
    }
    .signature-box {
      margin-top: 40px;
      padding: 20px;
      background: #f5f5f5;
      border-radius: 8px;
    }
    .signature-line {
      margin-top: 30px;
      border-top: 1px solid #ccc;
      padding-top: 10px;
      width: 250px;
    }
    .footer {
      margin-top: 50px;
      text-align: center;
      font-size: 11px;
      color: #999;
      border-top: 1px solid #eee;
      padding-top: 20px;
    }
    @media print {
      body { padding: 20px; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>FREELANCE SERVICES AGREEMENT</h1>
    <div class="contract-number">Contract No: ${contractNumber}</div>
    <div>Date: ${date}</div>
  </div>
  
  ${html.replace(/<body[^>]*>|<\/body>/gi, "").replace(/<html[^>]*>|<\/html>/gi, "")}
  
  <div class="footer">
    <p>This agreement is electronically generated and legally binding.</p>
    <p>© ${new Date().getFullYear()} Freelancer Platform - All rights reserved.</p>
  </div>
</body>
</html>
  `;
  }

  static generateFallbackContract(
    project,
    freelancer,
    client,
    amount,
    milestones,
  ) {
    const date = new Date().toLocaleDateString();
    const milestonesHtml = milestones
      .map(
        (m, i) => `
    <div class="milestone">
      <strong>Milestone ${i + 1}: ${m.title}</strong><br>
      Amount: $${m.amount}<br>
      ${m.description ? `Description: ${m.description}<br>` : ""}
    </div>
  `,
      )
      .join("");

    return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 40px; }
    h1 { color: #14A800; text-align: center; }
    .milestone { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
    .signature { margin-top: 40px; display: flex; justify-content: space-between; }
  </style>
</head>
<body>
  <h1>FREELANCE CONTRACT</h1>
  <p><strong>Date:</strong> ${date}</p>
  <p><strong>Client:</strong> ${client?.name || "Client"}</p>
  <p><strong>Freelancer:</strong> ${freelancer?.name || "Freelancer"}</p>
  <p><strong>Project:</strong> ${project.title}</p>
  <p><strong>Total Amount:</strong> $${amount}</p>
  
  <h2>Project Description</h2>
  <p>${project.description}</p>
  
  <h2>Payment Milestones</h2>
  ${milestonesHtml}
  
  <h2>Terms & Conditions</h2>
  <p>1. The freelancer agrees to complete all milestones as described.</p>
  <p>2. Payment will be released upon milestone completion and client approval.</p>
  <p>3. All work ownership transfers to client upon full payment.</p>
  <p>4. Both parties agree to maintain confidentiality.</p>
  
  <div class="signature">
    <div>Client Signature: _________________</div>
    <div>Freelancer Signature: _________________</div>
  </div>
</body>
</html>
  `;
  }

  static parseSkills(skillsField) {
    if (!skillsField) return [];
    if (Array.isArray(skillsField)) return skillsField;
    if (typeof skillsField === "string") {
      try {
        const parsed = JSON.parse(skillsField);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return skillsField.split(",").map((s) => s.trim());
      }
    }
    return [];
  }

  static detectProjectType(project) {
    const title = project.title?.toLowerCase() || "";
    const description = project.description?.toLowerCase() || "";
    const skills = project.skills || [];
    const skillsStr = JSON.stringify(skills).toLowerCase();

    if (
      title.includes("app") ||
      title.includes("web") ||
      title.includes("software") ||
      description.includes("flutter") ||
      description.includes("react") ||
      description.includes("node") ||
      description.includes("python") ||
      description.includes("java") ||
      description.includes("code") ||
      skillsStr.includes("flutter") ||
      skillsStr.includes("react") ||
      skillsStr.includes("node")
    ) {
      return "software";
    }

    if (
      title.includes("design") ||
      title.includes("ui") ||
      title.includes("ux") ||
      description.includes("figma") ||
      description.includes("adobe") ||
      description.includes("photoshop") ||
      skillsStr.includes("design") ||
      skillsStr.includes("ui") ||
      skillsStr.includes("ux")
    ) {
      return "design";
    }

    if (
      title.includes("content") ||
      title.includes("writing") ||
      title.includes("blog") ||
      description.includes("article") ||
      description.includes("copywriting") ||
      description.includes("seo") ||
      skillsStr.includes("writing") ||
      skillsStr.includes("content")
    ) {
      return "content";
    }

    if (
      title.includes("marketing") ||
      title.includes("seo") ||
      title.includes("social media") ||
      description.includes("digital marketing") ||
      description.includes("facebook")
    ) {
      return "marketing";
    }

    return "general";
  }

  static generateContractHtml({
    project,
    freelancer,
    client,
    agreedAmount,
    milestones,
    projectType,
  }) {
    const date = new Date().toLocaleDateString("en-US");
    const contractNumber = `CT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    let milestonesHtml = "";
    if (milestones && milestones.length > 0) {
      milestonesHtml = `
        <div class="milestones-section">
          <h2>Payment Milestones</h2>
          <div class="milestones-list">
            ${milestones
              .map(
                (m, i) => `
              <div class="milestone-card">
                <div class="milestone-header">
                  <span class="milestone-number">${i + 1}</span>
                  <span class="milestone-title">${this.escapeHtml(m.title || "Milestone")}</span>
                  <span class="milestone-amount">$${m.amount || 0}</span>
                </div>
                <div class="milestone-description">${this.escapeHtml(m.description || "")}</div>
                <div class="milestone-date">Due: ${m.due_date ? new Date(m.due_date).toLocaleDateString() : "To be determined"}</div>
                <div class="milestone-percentage">${m.percentage || 0}% of total</div>
              </div>
            `,
              )
              .join("")}
          </div>
        </div>
      `;
    } else {
      milestonesHtml = `
        <div class="milestones-section">
          <h2>Payment Terms</h2>
          <p>The total amount of <strong>$${agreedAmount}</strong> will be paid upon successful completion and delivery of all project requirements.</p>
        </div>
      `;
    }

    let industryClauses = this.getIndustryClauses(projectType);

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      line-height: 1.6;
      max-width: 1000px;
      margin: 0 auto;
      padding: 40px;
      background: #f5f5f5;
    }
    .contract-container {
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
      overflow: hidden;
    }
    .header {
      background: linear-gradient(135deg, #14A800 0%, #0F7A00 100%);
      padding: 30px;
      text-align: center;
      color: white;
    }
    .header h1 { margin: 0; font-size: 28px; }
    .contract-number { margin-top: 8px; font-size: 12px; opacity: 0.8; }
    .content { padding: 30px; }
    .section { margin-bottom: 30px; }
    .section h2 {
      color: #14A800;
      border-left: 4px solid #14A800;
      padding-left: 15px;
      margin-bottom: 20px;
      font-size: 20px;
    }
    .section h3 { color: #333; margin: 15px 0 10px 0; font-size: 16px; }
    .info-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      margin-bottom: 20px;
    }
    .info-card {
      background: #f8f9fa;
      padding: 15px;
      border-radius: 10px;
    }
    .info-card .label {
      font-size: 12px;
      color: #666;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .info-card .value {
      font-size: 18px;
      font-weight: bold;
      color: #333;
      margin-top: 5px;
    }
    .amount {
      font-size: 32px;
      font-weight: bold;
      color: #14A800;
    }
    .milestones-list { margin-top: 15px; }
    .milestone-card {
      background: #f8f9fa;
      border-radius: 12px;
      padding: 15px;
      margin-bottom: 12px;
      border-left: 4px solid #14A800;
    }
    .milestone-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .milestone-number {
      background: #14A800;
      color: white;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      font-weight: bold;
    }
    .milestone-title { font-weight: bold; flex: 1; margin-left: 12px; }
    .milestone-amount { font-weight: bold; color: #14A800; }
    .milestone-description { font-size: 13px; color: #666; margin: 8px 0 0 40px; }
    .milestone-date { font-size: 11px; color: #999; margin-top: 6px; margin-left: 40px; }
    .milestone-percentage { font-size: 11px; color: #14A800; margin-top: 4px; margin-left: 40px; }
    .clause {
      background: #f8f9fa;
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 15px;
    }
    .signature-section {
      margin-top: 40px;
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 30px;
    }
    .signature-box {
      text-align: center;
      padding: 20px;
      border-top: 2px dashed #ccc;
    }
    .signature-box .name { font-weight: bold; margin-bottom: 5px; }
    .signature-box .date { font-size: 11px; color: #999; }
    .footer {
      background: #f5f5f5;
      padding: 20px;
      text-align: center;
      font-size: 11px;
      color: #999;
      border-top: 1px solid #e0e0e0;
    }
    @media print {
      body { background: white; padding: 0; }
      .contract-container { box-shadow: none; }
      .header { background: #14A800; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <div class="contract-container">
    <div class="header">
      <h1>FREELANCE SERVICES AGREEMENT</h1>
      <div class="contract-number">Contract No: ${contractNumber}</div>
      <div>Date: ${date}</div>
    </div>
    <div class="content">
      <div class="section">
        <h2>Parties</h2>
        <div class="info-grid">
          <div class="info-card">
            <div class="label">Client</div>
            <div class="value">${this.escapeHtml(client?.name || "Client")}</div>
            <div class="email">${client?.email || ""}</div>
          </div>
          <div class="info-card">
            <div class="label">Freelancer</div>
            <div class="value">${this.escapeHtml(freelancer?.name || "Freelancer")}</div>
            <div class="email">${freelancer?.email || ""}</div>
          </div>
        </div>
      </div>
      <div class="section">
        <h2>Project Details</h2>
        <div class="info-card">
          <div class="label">Project Title</div>
          <div class="value">${this.escapeHtml(project?.title || "Untitled Project")}</div>
          <div style="margin-top: 10px;">
            <div class="label">Description</div>
            <div>${this.escapeHtml(project?.description || "No description provided")}</div>
          </div>
        </div>
      </div>
      <div class="section">
        <h2>Payment Terms</h2>
        <div class="info-card" style="text-align: center;">
          <div class="label">Total Contract Amount</div>
          <div class="amount">$${agreedAmount}</div>
        </div>
        ${milestonesHtml}
      </div>
      <div class="section">
        <h2>Terms & Conditions</h2>
        ${industryClauses}
        <div class="clause">
          <h3>Confidentiality</h3>
          <p>Both parties agree to keep all project-related information confidential. The Freelancer shall not disclose any proprietary information to third parties.</p>
        </div>
        <div class="clause">
          <h3>Termination</h3>
          <p>Either party may terminate this agreement with 7 days written notice. In case of termination, payment will be made for completed work.</p>
        </div>
        <div class="clause">
          <h3>Dispute Resolution</h3>
          <p>Any disputes arising from this agreement shall be resolved through the platform's dispute resolution process. Both parties agree to cooperate in good faith.</p>
        </div>
      </div>
      <div class="signature-section">
        <div class="signature-box">
          <div class="name">Client Signature</div>
          <div class="date">_________________________</div>
          <div class="date">Date: ___________________</div>
        </div>
        <div class="signature-box">
          <div class="name">Freelancer Signature</div>
          <div class="date">_________________________</div>
          <div class="date">Date: ___________________</div>
        </div>
      </div>
    </div>
    <div class="footer">
      <p>This agreement is generated electronically and is legally binding.</p>
      <p>© ${new Date().getFullYear()} Freelancer Platform - All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `;
  }

  static getIndustryClauses(projectType) {
    if (projectType === "software") {
      return `
        <div class="clause">
          <h3>Intellectual Property Rights</h3>
          <p>Upon full payment, all source code, documentation, and related materials become the exclusive property of the Client. The Freelancer retains the right to use the code in their portfolio.</p>
        </div>
        <div class="clause">
          <h3>Code Quality Standards</h3>
          <p>The Freelancer agrees to follow industry best practices including clean code principles, proper documentation, and Git version control.</p>
        </div>
        <div class="clause">
          <h3>Testing Requirements</h3>
          <p>Critical bugs identified within 14 days of delivery will be fixed at no additional cost.</p>
        </div>
      `;
    } else if (projectType === "design") {
      return `
        <div class="clause">
          <h3>Design Ownership</h3>
          <p>Upon final payment, the Client receives full ownership of all final designs, including source files (PSD, AI, Figma, etc.).</p>
        </div>
        <div class="clause">
          <h3>Revision Policy</h3>
          <p>The Freelancer will provide up to 3 rounds of revisions per milestone. Additional revisions may incur extra charges.</p>
        </div>
      `;
    } else if (projectType === "content") {
      return `
        <div class="clause">
          <h3>Content Ownership</h3>
          <p>All content created becomes the exclusive property of the Client upon full payment.</p>
        </div>
        <div class="clause">
          <h3>Plagiarism Policy</h3>
          <p>The Freelancer guarantees that all content is original. Any plagiarism will result in immediate contract termination.</p>
        </div>
      `;
    }
    return `
      <div class="clause">
        <h3>Work Ownership</h3>
        <p>Upon full payment, all deliverables become the property of the Client.</p>
      </div>
    `;
  }

  static escapeHtml(text) {
    if (!text) return "";
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  static generateFallbackContract(
    projectId,
    freelancerId,
    clientId,
    agreedAmount,
    milestones,
  ) {
    const date = new Date().toLocaleDateString();
    const milestonesHtml =
      milestones && milestones.length > 0
        ? `
      <h2>Payment Milestones</h2>
      ${milestones
        .map(
          (m, i) => `
        <div style="margin-bottom: 15px; padding: 10px; border-left: 3px solid #14A800; background: #f9f9f9;">
          <strong>Milestone ${i + 1}: ${m.title || "Milestone"}</strong><br>
          Amount: $${m.amount || 0}<br>
          ${m.description ? `Description: ${m.description}<br>` : ""}
        </div>
      `,
        )
        .join("")}
    `
        : `<p>Total Amount: $${agreedAmount}</p>`;

    return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 40px; }
    h1 { color: #14A800; text-align: center; }
    .signature { margin-top: 40px; display: flex; justify-content: space-between; }
  </style>
</head>
<body>
  <h1>FREELANCE CONTRACT</h1>
  <p><strong>Date:</strong> ${date}</p>
  <p><strong>Client ID:</strong> ${clientId}</p>
  <p><strong>Freelancer ID:</strong> ${freelancerId}</p>
  <p><strong>Project ID:</strong> ${projectId}</p>
  <p><strong>Total Amount:</strong> $${agreedAmount}</p>
  ${milestonesHtml}
  <h2>Terms & Conditions</h2>
  <p>1. The freelancer agrees to complete all deliverables as described in the project.</p>
  <p>2. Payment will be released upon milestone completion and client approval.</p>
  <p>3. All work ownership transfers to client upon full payment.</p>
  <p>4. Both parties agree to maintain confidentiality.</p>
  <div class="signature">
    <div>Client Signature: _________________</div>
    <div>Freelancer Signature: _________________</div>
  </div>
  <p><small>This contract was generated electronically.</small></p>
</body>
</html>
    `;
  }

  static async createContractDraft(
    projectId,
    freelancerId,
    clientId,
    agreed_amount,
    milestones = null,
  ) {
    try {
      console.log("📝 Creating contract draft for:", {
        projectId,
        freelancerId,
        clientId,
        agreed_amount,
      });

      const existingContract = await Contract.findOne({
        where: { ProjectId: projectId },
      });

      if (existingContract) {
        console.log("⚠️ Contract already exists:", existingContract.id);
        return existingContract;
      }

      const defaultMilestones = [
        {
          title: "Project Start",
          description: "Begin work on project",
          amount: Math.round(agreed_amount * 0.3),
          due_date: new Date(
            Date.now() + 7 * 24 * 60 * 60 * 1000,
          ).toISOString(),
          status: "pending",
          progress: 0,
        },
        {
          title: "Milestone 1",
          description: "First deliverable",
          amount: Math.round(agreed_amount * 0.4),
          due_date: new Date(
            Date.now() + 14 * 24 * 60 * 60 * 1000,
          ).toISOString(),
          status: "pending",
          progress: 0,
        },
        {
          title: "Final Delivery",
          description: "Complete project",
          amount: Math.round(agreed_amount * 0.3),
          due_date: new Date(
            Date.now() + 21 * 24 * 60 * 60 * 1000,
          ).toISOString(),
          status: "pending",
          progress: 0,
        },
      ];

      const chosenMilestones =
        Array.isArray(milestones) && milestones.length > 0
          ? milestones
          : defaultMilestones;

      const contractDocument = this.generateContractDocument({
        projectId,
        freelancerId,
        clientId,
        agreed_amount,
        milestones: chosenMilestones,
      });

      const contract = await Contract.create({
        ProjectId: projectId,
        FreelancerId: freelancerId,
        ClientId: clientId,
        agreed_amount: agreed_amount,
        contract_document: contractDocument,
        status: "draft",
        terms: "Standard terms and conditions apply.",
        milestones: JSON.stringify(chosenMilestones),
      });

      console.log("✅ Contract created with ID:", contract.id);

      await NotificationService.createNotification({
        userId: freelancerId,
        type: "contract_created",
        title: "New Contract Ready",
        body: "A contract has been created for you. Please review and sign.",
        data: { contractId: contract.id, screen: "contract" },
      });

      return contract;
    } catch (error) {
      console.error("❌ Error in createContractDraft:", error);
      throw error;
    }
  }

  static async signContractByClient(contractId, clientId) {
    const contract = await Contract.findOne({
      where: { id: contractId, ClientId: clientId },
    });
    if (!contract) throw new Error("Contract not found");
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
      await contract.update({ signed_at: new Date(), status: "active" });
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
    if (!contract) throw new Error("Contract not found");
    if (contract.status !== "draft" && contract.status !== "pending_client") {
      throw new Error("Contract cannot be signed at this stage");
    }

    await contract.update({
      freelancer_signed_at: new Date(),
      status: contract.client_signed_at ? "active" : "pending_client",
    });

    if (contract.client_signed_at) {
      await contract.update({ signed_at: new Date(), status: "active" });
      await Project.update(
        { status: "in_progress" },
        { where: { id: contract.ProjectId } },
      );
    }
    return contract;
  }
}

export default ContractService;
