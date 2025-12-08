import { Router } from 'express';
import { list, create, update, remove, uploadImage, uploadImages, deleteImage } from '../controllers/motorcycleController.js';
import { auth } from '../middleware/auth.js';
import { motorcycleImageUpload } from '../utils/upload.js';

const router = Router();
router.get('/', list);
router.post('/', auth('admin'), create);
router.put('/:id', auth('admin'), update);
router.delete('/:id', auth('admin'), remove);
router.post('/:id/image', auth('admin'), motorcycleImageUpload.single('image'), uploadImage);
router.post('/:id/images', auth('admin'), motorcycleImageUpload.array('images', 10), uploadImages);
router.delete('/:id/images/:imageId', auth('admin'), deleteImage);
export default router;
