import { Router } from 'express';
import { auth } from '../middleware/auth.js';
import { createPayment, uploadProof, listPayments, updatePaymentStatus, listMyPayments } from '../controllers/paymentController.js';
import { paymentProofUpload } from '../utils/upload.js';

const router = Router();
// User creates payment record after making transfer
router.post('/', auth(), createPayment);
// User uploads proof image for a payment id
router.post('/:id/proof', auth(), paymentProofUpload.single('proof'), uploadProof);
// Admin views all payments
router.get('/', auth('admin'), listPayments);
// User views their payments
router.get('/my', auth(), listMyPayments);
// Admin updates payment status
router.patch('/:id/status', auth('admin'), updatePaymentStatus);

export default router;
