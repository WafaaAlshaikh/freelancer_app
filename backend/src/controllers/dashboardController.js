// controllers/dashboardController.js
import {
  Project,
  Proposal,
  User,
  FreelancerProfile,
  Contract,
  Wallet,
  Transaction,
  Notification,
  Rating,
} from "../models/index.js";
import { Op, fn, col, literal } from "sequelize";
import { sequelize } from "../config/db.js";

export const getDashboardOverview = async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();

    const [
      totalProjects,
      openProjects,
      inProgressProjects,
      completedProjects,
      cancelledProjects,
    ] = await Promise.all([
      Project.count({ where: { UserId: userId } }),
      Project.count({ where: { UserId: userId, status: "open" } }),
      Project.count({ where: { UserId: userId, status: "in_progress" } }),
      Project.count({ where: { UserId: userId, status: "completed" } }),
      Project.count({ where: { UserId: userId, status: "cancelled" } }),
    ]);

    const myProjectIds = (
      await Project.findAll({
        where: { UserId: userId },
        attributes: ["id"],
      })
    ).map((p) => p.id);

    const [
      totalProposals,
      pendingProposals,
      acceptedProposals,
      rejectedProposals,
    ] = await Promise.all([
      Proposal.count({ where: { ProjectId: { [Op.in]: myProjectIds } } }),
      Proposal.count({
        where: { ProjectId: { [Op.in]: myProjectIds }, status: "pending" },
      }),
      Proposal.count({
        where: { ProjectId: { [Op.in]: myProjectIds }, status: "accepted" },
      }),
      Proposal.count({
        where: { ProjectId: { [Op.in]: myProjectIds }, status: "rejected" },
      }),
    ]);

    const completedContracts = await Contract.findAll({
      where: { ClientId: userId, status: "completed" },
      attributes: ["agreed_amount", "released_amount"],
    });

    const activeContracts = await Contract.findAll({
      where: { ClientId: userId, status: "active" },
      attributes: ["agreed_amount", "released_amount", "escrow_status"],
    });

    const totalSpent = completedContracts.reduce(
      (s, c) => s + parseFloat(c.agreed_amount || 0),
      0,
    );
    const escrowHeld = activeContracts
      .filter((c) => c.escrow_status === "funded")
      .reduce((s, c) => s + parseFloat(c.agreed_amount || 0), 0);
    const totalReleased = [...completedContracts, ...activeContracts].reduce(
      (s, c) => s + parseFloat(c.released_amount || 0),
      0,
    );

    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    sixMonthsAgo.setDate(1);
    sixMonthsAgo.setHours(0, 0, 0, 0);

    const wallet = await Wallet.findOne({ where: { UserId: userId } });
    let monthlySpending = [];
    if (wallet) {
      const raw = await Transaction.findAll({
        where: {
          wallet_id: wallet.id,
          type: "deposit",
          status: "completed",
          createdAt: { [Op.gte]: sixMonthsAgo },
        },
        attributes: [
          [fn("YEAR", col("createdAt")), "year"],
          [fn("MONTH", col("createdAt")), "month"],
          [fn("SUM", col("amount")), "total"],
        ],
        group: [fn("YEAR", col("createdAt")), fn("MONTH", col("createdAt"))],
        order: [
          [fn("YEAR", col("createdAt")), "ASC"],
          [fn("MONTH", col("createdAt")), "ASC"],
        ],
        raw: true,
      });

      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        const y = d.getFullYear();
        const m = d.getMonth() + 1;
        const found = raw.find(
          (r) => Number(r.year) === y && Number(r.month) === m,
        );
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          year: y,
          month: m,
          total: found ? parseFloat(found.total) : 0,
        });
      }
    } else {
      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        monthlySpending.push({
          label: d.toLocaleString("en", { month: "short" }),
          total: 0,
        });
      }
    }

    let spendingTrend = 0;
    let trendDirection = "up";

    if (monthlySpending.length >= 2) {
      const currentMonth = monthlySpending[monthlySpending.length - 1];
      const previousMonth = monthlySpending[monthlySpending.length - 2];

      const currentTotal = currentMonth.total;
      const previousTotal = previousMonth.total;

      if (previousTotal > 0) {
        spendingTrend = ((currentTotal - previousTotal) / previousTotal) * 100;
        trendDirection = spendingTrend >= 0 ? "up" : "down";
      } else if (currentTotal > 0) {
        spendingTrend = 100;
        trendDirection = "up";
      }
    }

    const recentProposals = await Proposal.findAll({
      where: { ProjectId: { [Op.in]: myProjectIds.slice(0, 20) } },
      include: [
        { model: Project, attributes: ["id", "title"] },
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
        {
          model: FreelancerProfile,
          as: "profile",
          required: false,
          attributes: ["title", "rating", "experience_years", "skills"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 6,
    });

    const activeContractsFull = await Contract.findAll({
      where: {
        ClientId: userId,
        status: {
          [Op.in]: ["active", "draft", "pending_client", "pending_freelancer"],
        },
      },
      include: [
        { model: Project, attributes: ["id", "title", "category"] },
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
      ],
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

    const contractsWithProgress = activeContractsFull.map((c) => {
      const milestones = Array.isArray(c.milestones) ? c.milestones : [];
      const total = milestones.length;
      const done = milestones.filter((m) =>
        ["completed", "approved"].includes(m.status),
      ).length;
      const progress = total > 0 ? Math.round((done / total) * 100) : 0;
      const nextMs = milestones.find(
        (m) => !["completed", "approved"].includes(m.status),
      );
      return {
        id: c.id,
        status: c.status,
        escrowStatus: c.escrow_status,
        agreedAmount: parseFloat(c.agreed_amount || 0),
        releasedAmount: parseFloat(c.released_amount || 0),
        progress,
        milestonesTotal: total,
        milestonesDone: done,
        nextMilestone: nextMs
          ? { title: nextMs.title, dueDate: nextMs.due_date }
          : null,
        project: c.Project
          ? {
              id: c.Project.id,
              title: c.Project.title,
              category: c.Project.category,
            }
          : null,
        freelancer: c.freelancer
          ? {
              id: c.freelancer.id,
              name: c.freelancer.name,
              avatar: c.freelancer.avatar,
            }
          : null,
      };
    });

    const recentActivity = await Notification.findAll({
      where: { userId },
      order: [["createdAt", "DESC"]],
      limit: 8,
      attributes: ["id", "type", "title", "body", "isRead", "createdAt"],
    });

    const pastContracts = await Contract.findAll({
      where: { ClientId: userId, status: "completed" },
      include: [
        { model: User, as: "freelancer", attributes: ["id", "name", "avatar"] },
        {
          model: Rating,
          where: { role: "client" },
          required: false,
          attributes: ["rating", "comment"],
        },
      ],
      limit: 4,
    });

    const topFreelancers = pastContracts
      .filter((c) => c.freelancer)
      .map((c) => ({
        id: c.freelancer.id,
        name: c.freelancer.name,
        avatar: c.freelancer.avatar,
        rating: c.Ratings?.[0]?.rating ?? null,
      }));

    const statusBreakdown = [
      { label: "Open", value: openProjects, color: "#378ADD" },
      { label: "In Progress", value: inProgressProjects, color: "#639922" },
      { label: "Completed", value: completedProjects, color: "#1D9E75" },
      { label: "Cancelled", value: cancelledProjects, color: "#E24B4A" },
    ].filter((s) => s.value > 0);

    res.json({
      stats: {
        totalProjects,
        openProjects,
        inProgressProjects,
        completedProjects,
        cancelledProjects,
        totalProposals,
        pendingProposals,
        acceptedProposals,
        rejectedProposals,
        totalSpent,
        escrowHeld,
        totalReleased,
        proposalAcceptRate:
          totalProposals > 0
            ? Math.round((acceptedProposals / totalProposals) * 100)
            : 0,
      },
      monthlySpending,
      spending_trend: {
        percentage: Math.abs(Math.round(spendingTrend)),
        direction: trendDirection,
      },
      statusBreakdown,
      recentProposals: recentProposals.map((p) => ({
        id: p.id,
        status: p.status,
        price: parseFloat(p.price || 0),
        deliveryTime: p.delivery_time,
        proposalText: p.proposal_text,
        createdAt: p.createdAt,
        project: p.Project
          ? { id: p.Project.id, title: p.Project.title }
          : null,
        freelancer: p.freelancer
          ? {
              id: p.freelancer.id,
              name: p.freelancer.name,
              avatar: p.freelancer.avatar,
            }
          : null,
        freelancerProfile: p.profile
          ? {
              title: p.profile.title,
              rating: p.profile.rating,
              experienceYears: p.profile.experience_years,
              skills: (() => {
                try {
                  return JSON.parse(p.profile.skills || "[]");
                } catch {
                  return [];
                }
              })(),
            }
          : null,
      })),
      activeContracts: contractsWithProgress,
      recentActivity: recentActivity.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        isRead: n.isRead,
        createdAt: n.createdAt,
      })),
      topFreelancers,
    });
  } catch (err) {
    console.error("❌ getDashboardOverview:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectsSummary = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 10, offset = 0 } = req.query;

    const where = { UserId: userId };
    if (status && status !== "all") where.status = status;

    const projects = await Project.findAll({
      where,
      order: [["createdAt", "DESC"]],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    const enriched = await Promise.all(
      projects.map(async (p) => {
        const [proposalCount, contract] = await Promise.all([
          Proposal.count({ where: { ProjectId: p.id } }),
          Contract.findOne({
            where: { ProjectId: p.id },
            attributes: [
              "id",
              "status",
              "agreed_amount",
              "escrow_status",
              "milestones",
            ],
            include: [
              {
                model: User,
                as: "freelancer",
                attributes: ["id", "name", "avatar"],
              },
            ],
          }),
        ]);

        let milestoneProgress = 0;
        if (contract?.milestones) {
          const ms = Array.isArray(contract.milestones)
            ? contract.milestones
            : [];
          const done = ms.filter((m) =>
            ["completed", "approved"].includes(m.status),
          ).length;
          milestoneProgress =
            ms.length > 0 ? Math.round((done / ms.length) * 100) : 0;
        }

        return {
          id: p.id,
          title: p.title,
          description: p.description,
          budget: p.budget,
          duration: p.duration,
          category: p.category,
          skills: (() => {
            try {
              return JSON.parse(p.skills || "[]");
            } catch {
              return [];
            }
          })(),
          status: p.status,
          createdAt: p.createdAt,
          proposalCount,
          contract: contract
            ? {
                id: contract.id,
                status: contract.status,
                agreedAmount: parseFloat(contract.agreed_amount || 0),
                escrowStatus: contract.escrow_status,
                milestoneProgress,
                freelancer: contract.freelancer,
              }
            : null,
        };
      }),
    );

    const total = await Project.count({ where });
    res.json({
      projects: enriched,
      total,
      hasMore: offset + projects.length < total,
    });
  } catch (err) {
    console.error("❌ getProjectsSummary:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};
