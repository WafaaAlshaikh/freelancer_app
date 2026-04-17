// backend/src/controllers/skillTestController.js
import SkillTestService from "../services/skillTestService.js";

export const getAvailableTests = async (req, res) => {
  try {
    const { skillCategory } = req.query;
    const tests = await SkillTestService.getAvailableTests(
      req.user.id,
      skillCategory,
    );
    res.json({ success: true, tests });
  } catch (error) {
    console.error("Error getting tests:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getTest = async (req, res) => {
  try {
    const { testId } = req.params;
    const test = await SkillTestService.getTest(testId, req.user.id);
    if (!test) {
      return res
        .status(404)
        .json({ success: false, message: "Test not found" });
    }
    res.json({ success: true, test });
  } catch (error) {
    console.error("Error getting test:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const startTest = async (req, res) => {
  try {
    const { testId } = req.params;
    const result = await SkillTestService.startTest(testId, req.user.id);

    if (!result.userTestId) {
      return res.status(400).json({
        success: false,
        message: "Failed to create test session",
      });
    }

    res.json({ success: true, ...result });
  } catch (error) {
    console.error("Error starting test:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Failed to start test",
    });
  }
};

export const submitTest = async (req, res) => {
  try {
    const { userTestId } = req.params;
    const { answers } = req.body;
    const result = await SkillTestService.submitTest(userTestId, answers);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error("Error submitting test:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUserTestResults = async (req, res) => {
  try {
    const results = await SkillTestService.getUserTestResults(req.user.id);
    res.json({ success: true, results });
  } catch (error) {
    console.error("Error getting results:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUserTestStats = async (req, res) => {
  try {
    const stats = await SkillTestService.getUserTestStats(req.user.id);
    res.json({ success: true, stats });
  } catch (error) {
    console.error("Error getting stats:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createTest = async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ success: false, message: "Admin only" });
    }
    const test = await SkillTestService.createTest(req.body);
    res.json({ success: true, test });
  } catch (error) {
    console.error("Error creating test:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
