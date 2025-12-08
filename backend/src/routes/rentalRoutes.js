import { Router } from 'express';
import { auth } from '../middleware/auth.js';
import { createRental, listUserRentals, listAllRentals, updateStatus } from '../controllers/rentalController.js';

const router = Router();
router.post('/', auth(), createRental);
router.get('/me', auth(), listUserRentals);
router.get('/', auth('admin'), listAllRentals);
router.patch('/:id/status', auth('admin'), updateStatus);
export default router;
