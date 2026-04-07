// ===== backend/src/routes/favoriteRoutes.js =====
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  addToFavorites,
  removeFromFavorites,
  getUserFavorites,
  checkFavorite,
  getRecentProjects,
} from "../controllers/favoriteController.js";

const router = express.Router();

router.use(protect);

router.post("/:projectId", addToFavorites);
router.delete("/:projectId", removeFromFavorites);
router.get("/", getUserFavorites);
router.get("/check/:projectId", checkFavorite);
router.get("/recent/projects", getRecentProjects);

export default router;