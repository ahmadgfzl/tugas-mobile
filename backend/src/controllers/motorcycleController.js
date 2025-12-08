import { MotorcycleModel } from '../models/motorcycleModel.js';
import { MotorcycleImageModel } from '../models/motorcycleImageModel.js';
import { success, error } from '../utils/response.js';
import { removeIfExists } from '../utils/upload.js';

export async function list(req, res) {
  try {
    const data = await MotorcycleModel.all();
    // Attach images array for each motorcycle
    const withImages = await Promise.all(
      data.map(async (m) => {
        const images = await MotorcycleImageModel.listByMotorcycle(m.id);
        return { ...m, images };
      })
    );
    return success(res, withImages);
  } catch (e) { return error(res, e.message); }
}

export async function create(req, res) {
  try {
    const { brand, model, plate_number, price_per_day } = req.body;
    if (!brand || !model || !plate_number || !price_per_day) return error(res, 'Missing fields');
    const moto = await MotorcycleModel.create({ brand, model, plate_number, price_per_day });
    return success(res, moto, 'Created');
  } catch (e) { return error(res, e.message); }
}

export async function update(req, res) {
  try {
    const { id } = req.params;
    const moto = await MotorcycleModel.update(id, req.body);
    return success(res, moto, 'Updated');
  } catch (e) { return error(res, e.message); }
}

export async function remove(req, res) {
  try {
    const { id } = req.params;
    // Clean up files: cover + all gallery images
    const moto = await MotorcycleModel.find(id);
    if (!moto) return error(res, 'Motorcycle not found', 404);
    if (moto.image_url) removeIfExists(moto.image_url);
    const gallery = await MotorcycleImageModel.listByMotorcycle(id);
    for (const img of gallery) {
      removeIfExists(img.image_url);
    }
    await MotorcycleModel.remove(id);
    return success(res, {}, 'Deleted');
  } catch (e) { return error(res, e.message); }
}

export async function uploadImage(req, res) {
  try {
    const { id } = req.params;
    const moto = await MotorcycleModel.find(id);
    if(!moto) return error(res, 'Motorcycle not found', 404);
    if(!req.file) return error(res, 'No file uploaded');
    // Hapus file lama jika ada
    if(moto.image_url) removeIfExists(moto.image_url);
    const relative = `/uploads/motorcycles/${req.file.filename}`;
    // simpan juga ke tabel motorcycle_images agar tampil di galeri
    try { await MotorcycleImageModel.add(id, relative); } catch (_) {}
    await MotorcycleModel.update(id, { image_url: relative });
    const updated = await MotorcycleModel.find(id);
    return success(res, updated, 'Image uploaded');
  } catch (e) { return error(res, e.message); }
}

export async function uploadImages(req, res) {
  try {
    const { id } = req.params;
    const moto = await MotorcycleModel.find(id);
    if (!moto) return error(res, 'Motorcycle not found', 404);
    const files = req.files || [];
    if (!files.length) return error(res, 'No files uploaded');
    const rels = files.map(f => `/uploads/motorcycles/${f.filename}`);
    // insert all into gallery
    for (const rel of rels) {
      await MotorcycleImageModel.add(id, rel);
    }
    // if no cover yet, set to first uploaded
    if (!moto.image_url && rels.length) {
      await MotorcycleModel.update(id, { image_url: rels[0] });
    }
    const images = await MotorcycleImageModel.listByMotorcycle(id);
    return success(res, { id: Number(id), images }, 'Images uploaded');
  } catch (e) { return error(res, e.message); }
}
export async function deleteImage(req, res) {
  try {
    const { id, imageId } = req.params;
    // Pastikan motor ada
    const moto = await MotorcycleModel.find(id);
    if (!moto) return error(res, 'Motorcycle not found', 404);
    // Ambil image
    const img = await MotorcycleImageModel.findById(imageId);
    if (!img || String(img.motorcycle_id) !== String(id)) {
      return error(res, 'Image not found', 404);
    }
    // Hapus file fisik
    removeIfExists(img.image_url);
    // Hapus dari DB
    await MotorcycleImageModel.removeById(imageId);
    // Jika gambar yang dihapus adalah cover saat ini, update cover ke gambar pertama yang tersisa (atau null)
    if (moto.image_url && moto.image_url === img.image_url) {
      const remaining = await MotorcycleImageModel.listByMotorcycle(id);
      const newCover = remaining.length ? remaining[0].image_url : null;
      await MotorcycleModel.update(id, { image_url: newCover });
    }
    return success(res, {}, 'Image deleted');
  } catch (e) { return error(res, e.message); }
}
