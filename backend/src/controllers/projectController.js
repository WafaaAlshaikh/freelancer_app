// controllers/projectController.js
import { Project, User } from "../models/index.js";


export const getAllProjects = async (req, res) => {
  try {
    console.log('📥 Fetching all projects...');
    
    const projects = await Project.findAll({
      where: { status: 'open' },
      include: [{
        model: User,
        as: 'client',
        attributes: ['id', 'name', 'avatar', 'email']
      }],
      order: [['createdAt', 'DESC']],
      limit: 50
    });
    
    console.log(`✅ Found ${projects.length} projects`);
    res.json(projects);
    
  } catch (err) {
    console.error('❌ Error in getAllProjects:', err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getProjectById = async (req, res) => {
  try {
    console.log('📥 Fetching project by ID:', req.params.id);
    
    const project = await Project.findByPk(req.params.id, {
      include: [
        { 
          model: User, 
          as: 'client', 
          attributes: ['id', 'name', 'avatar', 'email'] 
        }
      ]
    });
    
    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }
    
    console.log('✅ Project found:', project.title);
    console.log('👤 Client:', project.client?.name);
    
    res.json(project);
  } catch (err) {
    console.error('❌ Error in getProjectById:', err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};