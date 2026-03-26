import Portfolio from "../models/Portfolio.js";
import { User } from "../models/index.js";
import multer from "multer";
import path from "path";
import fs from "fs";

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/portfolio';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `portfolio-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

export const uploadPortfolioImages = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 } 
}).array('images', 10); 


export const createPortfolio = async (req, res) => {
  try {
    const { title, description, project_url, github_url, technologies, completion_date } = req.body;
    
    const imageUrls = req.files ? req.files.map(file => `/uploads/portfolio/${file.filename}`) : [];
    
    const portfolio = await Portfolio.create({
      UserId: req.user.id,
      title,
      description,
      images: JSON.stringify(imageUrls),
      project_url,
      github_url,
      technologies: JSON.stringify(technologies || []),
      completion_date: completion_date || new Date(),
      featured: false
    });
    
    res.status(201).json({
      message: "✅ Portfolio item created successfully",
      portfolio
    });
  } catch (err) {
    console.error("Error creating portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getUserPortfolio = async (req, res) => {
  try {
    const { userId } = req.params;
    const portfolio = await Portfolio.findAll({
      where: { UserId: userId },
      order: [['completion_date', 'DESC'], ['featured', 'DESC']]
    });
    
    const parsedPortfolio = portfolio.map(item => ({
      ...item.toJSON(),
      images: JSON.parse(item.images || "[]"),
      technologies: JSON.parse(item.technologies || "[]")
    }));
    
    res.json(parsedPortfolio);
  } catch (err) {
    console.error("Error getting portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const updatePortfolio = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findOne({
      where: { id, UserId: req.user.id }
    });
    
    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }
    
    const updateData = { ...req.body };
    
    if (updateData.technologies && Array.isArray(updateData.technologies)) {
      updateData.technologies = JSON.stringify(updateData.technologies);
    }
    
    await portfolio.update(updateData);
    
    res.json({
      message: "✅ Portfolio updated successfully",
      portfolio
    });
  } catch (err) {
    console.error("Error updating portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const deletePortfolio = async (req, res) => {
  try {
    const { id } = req.params;
    const portfolio = await Portfolio.findOne({
      where: { id, UserId: req.user.id }
    });
    
    if (!portfolio) {
      return res.status(404).json({ message: "Portfolio item not found" });
    }
    
    const images = JSON.parse(portfolio.images || "[]");
    images.forEach(imageUrl => {
      const filePath = path.join(process.cwd(), imageUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    });
    
    await portfolio.destroy();
    
    res.json({ message: "✅ Portfolio item deleted successfully" });
  } catch (err) {
    console.error("Error deleting portfolio:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};