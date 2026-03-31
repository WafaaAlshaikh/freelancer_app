// controllers/landingController.js
import PageContent from "../models/PageContent.js";
import Testimonial from "../models/Testimonial.js";
import PlatformStat from "../models/PlatformStat.js";
import { User, Project, Contract } from "../models/index.js";
import { Op } from "sequelize";

// ==================== Helper Functions ====================
const parseContent = (content) => {
  try {
    return content ? JSON.parse(content) : null;
  } catch {
    return content;
  }
};

// ==================== Public Routes ====================
export const getLandingPage = async (req, res) => {
  try {
    console.log("📱 Fetching landing page data...");

    const sections = await PageContent.findAll({
      where: { isActive: true },
      order: [["order", "ASC"]],
    });

    const testimonials = await Testimonial.findAll({
      where: { isActive: true },
      order: [["order", "ASC"]],
    });

    const [totalUsers, totalProjects, totalContracts, totalEarnings] =
      await Promise.all([
        User.count(),
        Project.count(),
        Contract.count(),
        Contract.sum("agreed_amount", { where: { status: "completed" } }),
      ]);

    const staticStats = await PlatformStat.findAll({
      where: { isActive: true },
    });

    const sectionsData = {};
    sections.forEach((section) => {
      sectionsData[section.section] = {
        title: section.title,
        subtitle: section.subtitle,
        description: section.description,
        content: parseContent(section.content),
        mediaUrl: section.mediaUrl,
        settings: parseContent(section.settings),
      };
    });

    const stats = {
      users: totalUsers,
      projects: totalProjects,
      contracts: totalContracts,
      earnings: totalEarnings || 0,
      staticStats: staticStats.reduce((acc, stat) => {
        acc[stat.key] = {
          value: stat.value,
          icon: stat.icon,
        };
        return acc;
      }, {}),
    };

    console.log("✅ Landing page data fetched successfully");

    res.json({
      success: true,
      data: {
        sections: sectionsData,
        testimonials,
        stats,
      },
    });
  } catch (err) {
    console.error("❌ Error in getLandingPage:", err);
    res.status(500).json({
      success: false,
      message: "Server error",
      data: {
        sections: {},
        testimonials: [],
        stats: {
          users: 0,
          projects: 0,
          contracts: 0,
          earnings: 0,
          staticStats: {},
        },
      },
    });
  }
};

export const getTestimonials = async (req, res) => {
  try {
    const testimonials = await Testimonial.findAll({
      order: [["order", "ASC"]],
    });
    res.json({ success: true, data: testimonials });
  } catch (err) {
    console.error("❌ Error in getTestimonials:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getStats = async (req, res) => {
  try {
    const stats = await PlatformStat.findAll();
    res.json({ success: true, data: stats });
  } catch (err) {
    console.error("❌ Error in getStats:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ==================== Admin Routes ====================
export const getAllSections = async (req, res) => {
  try {
    const sections = await PageContent.findAll({
      order: [["order", "ASC"]],
    });
    res.json({ success: true, data: sections });
  } catch (err) {
    console.error("❌ Error in getAllSections:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const updateSection = async (req, res) => {
  try {
    const { section } = req.params;
    const {
      title,
      subtitle,
      description,
      content,
      mediaUrl,
      settings,
      isActive,
      order,
    } = req.body;

    console.log(`📝 Updating section: ${section}`);

    let pageContent = await PageContent.findOne({ where: { section } });

    const updateData = {
      title,
      subtitle,
      description,
      content: content
        ? typeof content === "string"
          ? content
          : JSON.stringify(content)
        : null,
      mediaUrl,
      settings: settings ? JSON.stringify(settings) : "{}",
      isActive: isActive !== undefined ? isActive : true,
      order: order || 0,
    };

    if (pageContent) {
      await pageContent.update(updateData);
      console.log(`✅ Section ${section} updated`);
    } else {
      pageContent = await PageContent.create({
        section,
        ...updateData,
      });
      console.log(`✅ Section ${section} created`);
    }

    res.json({
      success: true,
      message: "Section updated successfully",
      data: pageContent,
    });
  } catch (err) {
    console.error("❌ Error in updateSection:", err);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
};

export const createTestimonial = async (req, res) => {
  try {
    const { name, role, avatar, content, rating, order } = req.body;

    const testimonial = await Testimonial.create({
      name,
      role,
      avatar,
      content,
      rating: rating || 5,
      order: order || 0,
      isActive: true,
    });

    console.log(`✅ New testimonial created: ${name}`);

    res.json({
      success: true,
      message: "Testimonial created successfully",
      data: testimonial,
    });
  } catch (err) {
    console.error("❌ Error in createTestimonial:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const updateTestimonial = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, role, avatar, content, rating, order, isActive } = req.body;

    const testimonial = await Testimonial.findByPk(id);
    if (!testimonial) {
      return res
        .status(404)
        .json({ success: false, message: "Testimonial not found" });
    }

    await testimonial.update({
      name: name || testimonial.name,
      role: role !== undefined ? role : testimonial.role,
      avatar: avatar !== undefined ? avatar : testimonial.avatar,
      content: content || testimonial.content,
      rating: rating || testimonial.rating,
      order: order !== undefined ? order : testimonial.order,
      isActive: isActive !== undefined ? isActive : testimonial.isActive,
    });

    console.log(`✅ Testimonial ${id} updated`);

    res.json({
      success: true,
      message: "Testimonial updated successfully",
      data: testimonial,
    });
  } catch (err) {
    console.error("❌ Error in updateTestimonial:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const deleteTestimonial = async (req, res) => {
  try {
    const { id } = req.params;

    const testimonial = await Testimonial.findByPk(id);
    if (!testimonial) {
      return res
        .status(404)
        .json({ success: false, message: "Testimonial not found" });
    }

    await testimonial.destroy();

    console.log(`✅ Testimonial ${id} deleted`);

    res.json({
      success: true,
      message: "Testimonial deleted successfully",
    });
  } catch (err) {
    console.error("❌ Error in deleteTestimonial:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const updateStat = async (req, res) => {
  try {
    const { key } = req.params;
    const { value, icon, isActive } = req.body;

    let stat = await PlatformStat.findOne({ where: { key } });

    if (stat) {
      await stat.update({ value, icon, isActive });
      console.log(`✅ Stat ${key} updated`);
    } else {
      stat = await PlatformStat.create({ key, value, icon, isActive });
      console.log(`✅ Stat ${key} created`);
    }

    res.json({
      success: true,
      message: "Stat updated successfully",
      data: stat,
    });
  } catch (err) {
    console.error("❌ Error in updateStat:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
