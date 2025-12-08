import { Router } from 'express';
import { getPaymentSettings, updatePaymentSettings } from '../controllers/settingsController.js';
import { auth } from '../middleware/auth.js';

const router = Router();
router.get('/payment', getPaymentSettings);
router.patch('/payment', auth('admin'), updatePaymentSettings);
export default router;
