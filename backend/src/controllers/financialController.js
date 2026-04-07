// ===== backend/src/controllers/financialController.js =====
import {
  FinancialTransaction,
  Wallet,
  Contract,
  User,
  Project
} from "../models/index.js";
import { Op, Sequelize } from "sequelize";
import { sequelize } from "../config/db.js";

export const getFinancialStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { period = "monthly", startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        transaction_date: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
      };
    }

    const earnings = await FinancialTransaction.sum("amount", {
      where: {
        user_id: userId,
        user_role: userRole,
        type: userRole === "freelancer" ? "payment_received" : "payment_sent",
        status: "completed",
        ...dateFilter,
      },
    });

    const fees = await FinancialTransaction.sum("amount", {
      where: {
        user_id: userId,
        type: "platform_fee",
        status: "completed",
        ...dateFilter,
      },
    });

    const withdrawals = await FinancialTransaction.sum("amount", {
      where: {
        user_id: userId,
        type: "withdrawal",
        status: "completed",
        ...dateFilter,
      },
    });

    let stats = {};

    if (period === "monthly") {
      const monthlyStats = await FinancialTransaction.findAll({
        attributes: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%m",
            ),
            "month",
          ],
          [Sequelize.fn("SUM", Sequelize.col("amount")), "total"],
        ],
        where: {
          user_id: userId,
          status: "completed",
          ...dateFilter,
        },
        group: [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%m",
          ),
        ],
        order: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%m",
            ),
            "ASC",
          ],
        ],
        raw: true,
      });
      stats = monthlyStats;
    } else if (period === "weekly") {
      const weeklyStats = await FinancialTransaction.findAll({
        attributes: [
          [
            Sequelize.fn(
              "DATE_FORMAT",
              Sequelize.col("transaction_date"),
              "%Y-%u",
            ),
            "week",
          ],
          [Sequelize.fn("SUM", Sequelize.col("amount")), "total"],
        ],
        where: {
          user_id: userId,
          status: "completed",
          ...dateFilter,
        },
        group: [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%u",
          ),
        ],
        raw: true,
      });
      stats = weeklyStats;
    }

    const recentTransactions = await FinancialTransaction.findAll({
      where: {
        user_id: userId,
        status: "completed",
      },
      order: [["transaction_date", "DESC"]],
      limit: 10,
    });

    res.json({
      success: true,
      stats: {
        totalEarnings: earnings || 0,
        totalFees: fees || 0,
        totalWithdrawals: withdrawals || 0,
        netEarnings: (earnings || 0) - (fees || 0) - (withdrawals || 0),
      },
      periodStats: stats,
      recentTransactions,
    });
  } catch (error) {
    console.error("Error getting financial stats:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const generateFinancialReport = async (req, res) => {
  try {
    const userId = req.user.id;
    const { startDate, endDate, format = "pdf" } = req.query;

    const transactions = await FinancialTransaction.findAll({
      where: {
        user_id: userId,
        transaction_date: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
        status: "completed",
      },
      order: [["transaction_date", "ASC"]],
    });

    const summary = {
      totalIncome: transactions
        .filter((t) => t.type === "payment_received" || t.type === "deposit")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
      totalExpenses: transactions
        .filter((t) => t.type === "payment_sent" || t.type === "withdrawal")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
      totalFees: transactions
        .filter((t) => t.type === "platform_fee")
        .reduce((sum, t) => sum + parseFloat(t.amount), 0),
    };
    summary.netIncome =
      summary.totalIncome - summary.totalExpenses - summary.totalFees;

    // TODO: إنشاء PDF حقيقي باستخدام مكتبة مثل pdfkit
    const reportData = {
      userId,
      period: { startDate, endDate },
      summary,
      transactions,
      generatedAt: new Date(),
    };

    res.json({
      success: true,
      report: reportData,
      downloadUrl: `/reports/financial_${userId}_${Date.now()}.pdf`,
    });
  } catch (error) {
    console.error("Error generating financial report:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const requestWithdrawalV2 = async (req, res) => {
  try {
    const { amount, method, accountDetails } = req.body;
    const userId = req.user.id;

    const wallet = await Wallet.findOne({ where: { UserId: userId } });
    if (!wallet || wallet.balance < amount) {
      return res
        .status(400)
        .json({ success: false, message: "Insufficient balance" });
    }

    const transaction = await FinancialTransaction.create({
      user_id: userId,
      user_role: req.user.role,
      amount: -amount,
      type: "withdrawal",
      status: "pending",
      description: `Withdrawal request via ${method}`,
      metadata: {
        method,
        accountDetails: accountDetails ? JSON.parse(accountDetails) : null,
        requested_at: new Date(),
      },
    });

    await wallet.update({
      pending_balance: (wallet.pending_balance || 0) + amount,
      balance: wallet.balance - amount,
    });

    // TODO: معالجة السحب حسب الطريقة (PayPal, Stripe, Bank Transfer)

    res.json({
      success: true,
      message: "Withdrawal request submitted successfully",
      transaction,
    });
  } catch (error) {
    console.error("Error requesting withdrawal:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getAdvancedFinancialAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    const topProjects = await Contract.findAll({
      where:
        userRole === "freelancer"
          ? { FreelancerId: userId, status: "completed" }
          : { ClientId: userId, status: "completed" },
      attributes: ["id", "agreed_amount", "createdAt"],
      include: [{ model: Project, attributes: ["title"] }],
      order: [["agreed_amount", "DESC"]],
      limit: 5,
    });

    const categoryDistribution = await sequelize.query(
      `
      SELECT 
        p.category,
        SUM(c.agreed_amount) as total
      FROM Contracts c
      JOIN Projects p ON c.ProjectId = p.id
      WHERE c.${userRole === "freelancer" ? "FreelancerId" : "ClientId"} = ${userId}
        AND c.status = 'completed'
      GROUP BY p.category
      ORDER BY total DESC
    `,
      { type: sequelize.QueryTypes.SELECT },
    );

    const monthlyAverage = await FinancialTransaction.findAll({
      attributes: [
        [
          Sequelize.fn(
            "DATE_FORMAT",
            Sequelize.col("transaction_date"),
            "%Y-%m",
          ),
          "month",
        ],
        [Sequelize.fn("AVG", Sequelize.col("amount")), "average"],
      ],
      where: {
        user_id: userId,
        status: "completed",
        type: userRole === "freelancer" ? "payment_received" : "payment_sent",
      },
      group: [
        Sequelize.fn("DATE_FORMAT", Sequelize.col("transaction_date"), "%Y-%m"),
      ],
      raw: true,
    });

    res.json({
      success: true,
      analytics: {
        topProjects,
        categoryDistribution,
        monthlyAverage,
        projectedEarnings: await calculateProjectedEarnings(userId, userRole),
      },
    });
  } catch (error) {
    console.error("Error getting advanced analytics:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

async function calculateProjectedEarnings(userId, userRole) {
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

  const transactions = await FinancialTransaction.findAll({
    where: {
      user_id: userId,
      transaction_date: { [Op.gte]: threeMonthsAgo },
      status: "completed",
      type: userRole === "freelancer" ? "payment_received" : "payment_sent",
    },
    attributes: ["amount"],
  });

  if (transactions.length === 0) return 0;

  const average =
    transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0) /
    transactions.length;
  return average * 3;
}
