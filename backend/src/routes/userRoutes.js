import { Router } from 'express';
import { auth } from '../middleware/auth.js';
import { me, updateMe, changePassword, uploadAvatar } from '../controllers/userController.js';
import { userAvatarUpload } from '../utils/upload.js';

const router = Router();
router.get('/me', auth(), me);
router.put('/me', auth(), updateMe);
router.put('/me/password', auth(), changePassword);
router.post('/me/avatar', auth(), userAvatarUpload.single('avatar'), uploadAvatar);
export default router;
