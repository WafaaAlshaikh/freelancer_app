import InvoiceService from "../services/InvoiceService.js";

export const getUserInvoices = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const result = await InvoiceService.getUserInvoices(
      req.user.id,
      parseInt(page),
      parseInt(limit),
    );
    res.json({ success: true, ...result });
  } catch (error) {
    console.error("Error getting invoices:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export const getInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    const invoice = await InvoiceService.getInvoice(parseInt(id), req.user.id);
    res.json({ success: true, invoice });
  } catch (error) {
    console.error("Error getting invoice:", error);
    res.status(404).json({ success: false, message: error.message });
  }
};

export const downloadInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    const invoice = await InvoiceService.getInvoice(parseInt(id), req.user.id);

    if (!invoice.pdf_url) {
      return res.status(404).json({ success: false, message: "PDF not found" });
    }

    res.redirect(invoice.pdf_url);
  } catch (error) {
    console.error("Error downloading invoice:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
