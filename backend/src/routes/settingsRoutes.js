import { Router } from 'express';
import { getPaymentSettings, updatePaymentSettings } from '../controllers/settingsController.js';
import { auth } from '../middleware/auth.js';
import { validatePaymentSettings } from '../middleware/validateSettings.js';

const router = Router();
router.get('/payment', getPaymentSettings);
router.patch('/payment', auth('admin'), validatePaymentSettings, updatePaymentSettings);
export default router;
