import bcrypt from 'bcrypt';
import { UserModel } from '../models/userModel.js';
import { success, error } from '../utils/response.js';
import { removeIfExists } from '../utils/upload.js';

export async function me(req, res) {
  try {
    const u = await UserModel.findById(req.user.id);
    if (!u) return error(res, 'User not found', 404);
    const { id, name, email, role, avatar_url } = u;
    return success(res, { id, name, email, role, avatar_url });
  } catch (e) { return error(res, e.message); }
}

export async function updateMe(req, res) {
  try {
    const { name, email, password } = req.body;
    const current = await UserModel.findById(req.user.id);
    if (!current) return error(res, 'User not found', 404);
    const patch = {};
    if (name && name !== current.name) patch.name = name;
    if (email && email !== current.email) {
      const taken = await UserModel.findByEmail(email);
      if (taken && taken.id !== current.id) return error(res, 'Email already used');
      patch.email = email;
    }
    if (password && password.length >= 6) {
      const hash = await bcrypt.hash(password, 10);
      patch.password_hash = hash;
    }
    const updated = await UserModel.update(current.id, patch);
    const { id, role, avatar_url } = updated;
    return success(res, { id, name: updated.name, email: updated.email, role, avatar_url }, 'Profile updated');
  } catch (e) { return error(res, e.message); }
}

export async function changePassword(req, res) {
  try {
    const { current_password, new_password, confirm_password } = req.body;
    if (!current_password || !new_password || !confirm_password) return error(res, 'Missing fields');
    if (new_password !== confirm_password) return error(res, 'Password confirmation does not match');
    if (new_password.length < 6) return error(res, 'New password must be at least 6 characters');
    const current = await UserModel.findById(req.user.id);
    if (!current) return error(res, 'User not found', 404);
    const ok = await bcrypt.compare(current_password, current.password_hash || '');
    if (!ok) return error(res, 'Current password is incorrect', 400);
    const hash = await bcrypt.hash(new_password, 10);
    await UserModel.update(current.id, { password_hash: hash });
    return success(res, { id: current.id }, 'Password updated');
  } catch (e) { return error(res, e.message); }
}

export async function uploadAvatar(req, res) {
  try {
    const u = await UserModel.findById(req.user.id);
    if (!u) return error(res, 'User not found', 404);
    if (!req.file) return error(res, 'No file uploaded');
    if (u.avatar_url) removeIfExists(u.avatar_url);
    const rel = `/uploads/users/${req.file.filename}`;
    const updated = await UserModel.update(u.id, { avatar_url: rel });
    const { id, name, email, role, avatar_url } = updated;
    return success(res, { id, name, email, role, avatar_url }, 'Avatar updated');
  } catch (e) { return error(res, e.message); }
}
