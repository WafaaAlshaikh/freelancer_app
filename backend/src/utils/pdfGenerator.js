// backend/src/utils/pdfGenerator.js
import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class PDFGenerator {
  constructor() {
    this.invoicesDir = path.join(__dirname, "../../invoices");
    this.sowsDir = path.join(__dirname, "../../sows");

    if (!fs.existsSync(this.invoicesDir)) {
      fs.mkdirSync(this.invoicesDir, { recursive: true });
    }
    if (!fs.existsSync(this.sowsDir)) {
      fs.mkdirSync(this.sowsDir, { recursive: true });
    }
  }

  /**
   * (Statement of Work)
   * @param {Object} data
   * @param {string} data.html
   * @param {string} data.sowNumber
   * @returns {Promise<string>}
   */
  async generateSOWPDF(data) {
    return new Promise(async (resolve, reject) => {
      try {
        const fileName = `sow_${data.sowNumber}_${Date.now()}.pdf`;
        const filePath = path.join(this.sowsDir, fileName);

        const doc = new PDFDocument({
          size: "A4",
          margins: { top: 50, bottom: 50, left: 50, right: 50 },
        });

        const stream = fs.createWriteStream(filePath);
        doc.pipe(stream);

        doc
          .fontSize(20)
          .font("Helvetica-Bold")
          .fillColor("#14A800")
          .text("FREELANCER PLATFORM", { align: "center" });

        doc.moveDown(0.5);
        doc
          .fontSize(12)
          .font("Helvetica")
          .fillColor("#666666")
          .text("Statement of Work (SOW)", { align: "center" });

        doc.moveDown(0.5);
        doc
          .fontSize(10)
          .text(`Document ID: ${data.sowNumber}`, { align: "center" })
          .text(`Generated: ${new Date().toLocaleDateString()}`, {
            align: "center",
          });

        doc.moveDown(1);

        this._drawDivider(doc);

        doc.moveDown(0.5);
        doc
          .fontSize(14)
          .font("Helvetica-Bold")
          .fillColor("#333333")
          .text("1. PARTIES INVOLVED");

        doc.moveDown(0.5);
        doc.fontSize(10).font("Helvetica").fillColor("#444444");

        doc.text(`Client: ${data.clientName || "Client"}`);
        doc.text(`Email: ${data.clientEmail || "N/A"}`);
        doc.moveDown(0.5);

        doc.text(`Service Provider: ${data.freelancerName || "Freelancer"}`);
        doc.text(`Email: ${data.freelancerEmail || "N/A"}`);

        doc.moveDown(1);
        this._drawDivider(doc);

        doc.moveDown(0.5);
        doc.fontSize(14).font("Helvetica-Bold").text("2. PROJECT OVERVIEW");

        doc.moveDown(0.5);
        doc.fontSize(10).font("Helvetica");

        doc.text(`Project Title: ${data.projectTitle || "Untitled"}`, {
          underline: true,
        });
        doc.moveDown(0.3);
        doc.text(`Category: ${data.projectCategory || "General"}`);
        doc.moveDown(0.3);
        doc.text(`Budget: $${data.agreedAmount?.toLocaleString() || "0"}`);
        doc.moveDown(0.5);

        doc.fontSize(10).font("Helvetica-Bold").text("Description:");
        doc.font("Helvetica");

        const description =
          data.projectDescription || "No description provided";
        this._wrapText(doc, description, 450, 12);

        doc.moveDown(1);
        this._drawDivider(doc);

        if (data.skills && data.skills.length > 0) {
          doc.moveDown(0.5);
          doc.fontSize(14).font("Helvetica-Bold").text("3. REQUIRED SKILLS");

          doc.moveDown(0.5);
          doc.fontSize(10).font("Helvetica");

          let skillsText = "";
          data.skills.forEach((skill, index) => {
            skillsText += `• ${skill}`;
            if (index < data.skills.length - 1) skillsText += "\n";
          });

          doc.text(skillsText);
          doc.moveDown(1);
          this._drawDivider(doc);
        }

        doc.moveDown(0.5);
        doc
          .fontSize(14)
          .font("Helvetica-Bold")
          .text("4. MILESTONES & PAYMENT SCHEDULE");

        doc.moveDown(0.5);

        if (data.milestones && data.milestones.length > 0) {
          let totalAmount = 0;

          data.milestones.forEach((milestone, index) => {
            const amount = milestone.amount || 0;
            totalAmount += amount;

            doc
              .fontSize(11)
              .font("Helvetica-Bold")
              .fillColor("#14A800")
              .text(`Milestone ${index + 1}: ${milestone.title || "Untitled"}`);

            doc.fontSize(9).font("Helvetica").fillColor("#333333");

            doc.text(
              `Amount: $${amount.toLocaleString()} (${milestone.percentage || 0}%)`,
            );

            if (milestone.description) {
              doc.text(`Description: ${milestone.description}`);
            }

            if (milestone.due_date) {
              const dueDate = new Date(milestone.due_date);
              doc.text(`Due Date: ${dueDate.toLocaleDateString()}`);
            }

            doc.moveDown(0.5);
          });

          doc.moveDown(0.5);
          this._drawDivider(doc, true);

          doc
            .fontSize(12)
            .font("Helvetica-Bold")
            .fillColor("#14A800")
            .text(`TOTAL CONTRACT VALUE: $${totalAmount.toLocaleString()}`, {
              align: "center",
            });

          doc
            .fontSize(9)
            .font("Helvetica")
            .fillColor("#666666")
            .text(
              "Payment will be held in escrow and released upon milestone approval",
              { align: "center" },
            );

          doc.moveDown(1);
          this._drawDivider(doc);
        }

        if (data.marketInsights) {
          doc.moveDown(0.5);
          doc.fontSize(14).font("Helvetica-Bold").text("5. AI MARKET ANALYSIS");

          doc.moveDown(0.5);
          doc.fontSize(9).font("Helvetica");

          doc.text(
            `🤖 Based on analysis of ${data.marketInsights.similar_projects_count || 0} similar projects:`,
          );
          doc.moveDown(0.3);
          doc.text(
            `• Market Average Cost: $${data.marketInsights.market_average_cost?.toLocaleString() || "N/A"}`,
          );
          doc.text(
            `• Market Average Duration: ${data.marketInsights.market_average_duration || "N/A"} days`,
          );
          doc.text(
            `• Success Rate: ${data.marketInsights.success_rate || 85}%`,
          );
          doc.text(
            `• AI Confidence Score: ${data.marketInsights.confidence_score || 85}%`,
          );

          doc.moveDown(0.5);
          doc
            .fontSize(9)
            .font("Helvetica-Bold")
            .text("Difficulty Assessment:", { underline: true });
          doc
            .font("Helvetica")
            .text(
              `${data.difficultyLevel || "Intermediate"} - ${this._getDifficultyDescription(data.difficultyLevel)}`,
            );

          doc.moveDown(1);
          this._drawDivider(doc);
        }

        doc.moveDown(0.5);
        doc.fontSize(14).font("Helvetica-Bold").text("6. TERMS & CONDITIONS");

        doc.moveDown(0.5);
        doc.fontSize(9).font("Helvetica");

        const terms = [
          "1. INTELLECTUAL PROPERTY: Upon full payment, all intellectual property rights, including source code, designs, and documentation, shall transfer to the Client.",
          "",
          "2. CONFIDENTIALITY: Both parties agree to keep all project-related information confidential. The Service Provider shall not disclose any proprietary information to third parties.",
          "",
          "3. PAYMENT TERMS: All payments are processed through the platform's secure escrow system. Milestone payments are released only after client approval of deliverables.",
          "",
          "4. TIMELINE & DELIVERY: The Service Provider agrees to deliver milestones according to the schedule above. Any delays must be communicated 48 hours in advance.",
          "",
          "5. QUALITY ASSURANCE: All deliverables must meet industry standards and the specifications outlined in this document.",
          "",
          "6. TERMINATION: Either party may terminate this agreement with 7 days written notice. In case of termination, payment will be made for completed work.",
          "",
          "7. DISPUTE RESOLUTION: Any disputes arising from this agreement shall be resolved through the platform's dispute resolution process.",
        ];

        terms.forEach((term) => {
          this._wrapText(doc, term, 450, 9);
          doc.moveDown(0.2);
        });

        doc.moveDown(1);
        this._drawDivider(doc);

        if (data.additionalTerms) {
          doc.moveDown(0.5);
          doc.fontSize(14).font("Helvetica-Bold").text("7. ADDITIONAL TERMS");

          doc.moveDown(0.5);
          doc.fontSize(9).font("Helvetica");

          this._wrapText(doc, data.additionalTerms, 450, 9);

          doc.moveDown(1);
          this._drawDivider(doc);
        }

        doc.moveDown(1);
        doc.fontSize(14).font("Helvetica-Bold").text("8. SIGNATURES");

        doc.moveDown(1);

        const signatureY = doc.y;

        doc.fontSize(10).font("Helvetica");

        doc.text("Client Signature:", 50, signatureY);
        doc.text("_________________________", 50, signatureY + 20);
        doc.text(`Date: _____________`, 50, signatureY + 35);

        doc.text("Service Provider Signature:", 300, signatureY);
        doc.text("_________________________", 300, signatureY + 20);
        doc.text(`Date: _____________`, 300, signatureY + 35);

        doc.moveDown(3);

        doc.moveDown(1);
        this._drawDivider(doc);

        doc
          .fontSize(8)
          .font("Helvetica")
          .fillColor("#999999")
          .text(
            "This Statement of Work is generated by AI and is legally binding.",
            { align: "center" },
          );
        doc.text(
          `© ${new Date().getFullYear()} Freelancer Platform - All rights reserved.`,
          { align: "center" },
        );
        doc.text(`Document ID: ${data.sowNumber}`, { align: "center" });

        doc.end();

        stream.on("finish", () => {
          console.log(`✅ PDF generated: ${filePath}`);
          resolve(`/sows/${fileName}`);
        });

        stream.on("error", (error) => {
          reject(error);
        });
      } catch (error) {
        console.error("❌ PDF generation error:", error);
        reject(error);
      }
    });
  }

  _drawDivider(doc, dashed = false) {
    const y = doc.y;
    doc.save();
    if (dashed) {
      doc.dash(5, { space: 5 });
    }
    doc.moveTo(50, y).lineTo(550, y).strokeColor("#CCCCCC").stroke();
    doc.restore();
    doc.moveDown(0.5);
  }

  _wrapText(doc, text, maxWidth, fontSize) {
    const words = text.split(" ");
    let line = "";
    let lines = [];

    for (let word of words) {
      const testLine = line + (line ? " " : "") + word;
      const testWidth = this._getTextWidth(testLine, fontSize);

      if (testWidth <= maxWidth) {
        line = testLine;
      } else {
        if (line) lines.push(line);
        line = word;
      }
    }
    if (line) lines.push(line);

    lines.forEach((line) => {
      doc.text(line);
    });
  }

  _getTextWidth(text, fontSize) {
    return text.length * (fontSize * 0.5);
  }

  _getDifficultyDescription(level) {
    switch (level?.toLowerCase()) {
      case "beginner":
        return "Simple project suitable for entry-level freelancers";
      case "intermediate":
        return "Standard complexity, requires moderate experience";
      case "expert":
        return "Complex project requiring specialized expertise";
      case "enterprise":
        return "Large-scale project requiring team collaboration";
      default:
        return "Standard project with moderate complexity";
    }
  }
}

export default new PDFGenerator();
