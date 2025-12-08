import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const uploadDir = path.join(__dirname, '../../public/uploads/motorcycles');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const userUploadDir = path.join(__dirname, '../../public/uploads/users');
if (!fs.existsSync(userUploadDir)) {
  fs.mkdirSync(userUploadDir, { recursive: true });
}
const paymentsUploadDir = path.join(__dirname, '../../public/uploads/payments');
if (!fs.existsSync(paymentsUploadDir)) {
  fs.mkdirSync(paymentsUploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    const ts = Date.now();
    cb(null, `${req.params.id}_${ts}${ext}`);
  }
});

function fileFilter (req, file, cb) {
  const allowedMimes = ['image/jpeg','image/jpg','image/png','image/webp','image/heic','image/heif'];
  const ext = (path.extname(file.originalname) || '').toLowerCase();
  const allowedExts = ['.jpeg','.jpg','.png','.webp','.heic','.heif'];
  const mimeOk = allowedMimes.includes((file.mimetype || '').toLowerCase());
  const extOk = allowedExts.includes(ext);
  // Accept if either mime is a known image OR extension is allowed
  if (!(mimeOk || extOk)) {
    console.warn('[upload] Rejected file:', { mimetype: file.mimetype, originalname: file.originalname });
    return cb(new Error('Invalid image type'));
  }
  cb(null, true);
}

export const motorcycleImageUpload = multer({ storage, fileFilter, limits: { fileSize: 2 * 1024 * 1024 } });

// User avatar upload config (auth middleware must run before this to set req.user)
const userStorage = multer.diskStorage({
  destination: function (req, file, cb) { cb(null, userUploadDir); },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    const ts = Date.now();
    const uid = (req.user && req.user.id) ? req.user.id : 'user';
    cb(null, `${uid}_${ts}${ext}`);
  }
});
export const userAvatarUpload = multer({ storage: userStorage, fileFilter, limits: { fileSize: 2 * 1024 * 1024 } });

// Payment proof upload
const paymentStorage = multer.diskStorage({
  destination: function (req, file, cb) { cb(null, paymentsUploadDir); },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    const ts = Date.now();
    const pid = req.params.id || 'payment';
    cb(null, `${pid}_${ts}${ext}`);
  }
});
export const paymentProofUpload = multer({ storage: paymentStorage, fileFilter, limits: { fileSize: 4 * 1024 * 1024 } });

export function removeIfExists(relPath) {
  if(!relPath) return;
  try {
    const p = path.join(__dirname, '../../', relPath.replace(/^\/+/, ''));
    if(fs.existsSync(p)) fs.unlinkSync(p);
  } catch(e) {
    console.warn('Failed remove old image', e.message);
  }
}
