import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  getUserInvoices,
  getInvoice,
  downloadInvoice,
} from "../controllers/invoiceController.js";

const router = express.Router();

router.use(protect);

router.get("/", getUserInvoices);
router.get("/:id", getInvoice);
router.get("/:id/download", downloadInvoice);

export default router;
