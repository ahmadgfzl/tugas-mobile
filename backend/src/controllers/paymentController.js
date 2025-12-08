import { PaymentModel } from '../models/paymentModel.js';
import { RentalModel } from '../models/rentalModel.js';
import { success, error } from '../utils/response.js';

export async function createPayment(req, res) {
  try {
    const { rental_id, amount, bank_account } = req.body;
    if (!rental_id || !amount || !bank_account) return error(res, 'Missing fields');
    const payment = await PaymentModel.create({ rental_id, amount, bank_account, proof_url: null });
    return success(res, payment, 'Payment created');
  } catch (e) { return error(res, e.message); }
}

export async function uploadProof(req, res) {
  try {
    const { id } = req.params;
    if (!req.file) return error(res, 'No file uploaded');
    const rel = `/uploads/payments/${req.file.filename}`;
    const updated = await PaymentModel.attachProof(id, rel);
    return success(res, updated, 'Proof uploaded');
  } catch (e) { return error(res, e.message); }
}

export async function listPayments(req, res) {
  try {
    const items = await PaymentModel.listAll();
    return success(res, items);
  } catch (e) { return error(res, e.message); }
}

export async function listMyPayments(req, res) {
  try {
    const items = await PaymentModel.listByUser(req.user.id);
    return success(res, items);
  } catch (e) { return error(res, e.message); }
}

export async function updatePaymentStatus(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!['pending','confirmed','rejected'].includes(status)) return error(res, 'Invalid status');
    const updated = await PaymentModel.updateStatus(id, status);
    if (updated && status === 'confirmed') {
      // When payment is confirmed, mark the related rental as approved
      const rentalId = updated.rental_id;
      if (rentalId) {
        await RentalModel.updateStatus(rentalId, 'approved');
      }
    }
    return success(res, updated, 'Payment status updated');
  } catch (e) { return error(res, e.message); }
}
