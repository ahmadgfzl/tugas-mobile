import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/userModel.js';
import { config } from '../config/env.js';
import { success, error } from '../utils/response.js';

export async function register(req, res) {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) return error(res, 'Missing fields');
    const existing = await UserModel.findByEmail(email);
    if (existing) return error(res, 'Email already used');
    const hash = await bcrypt.hash(password, 10);
    const user = await UserModel.create({ name, email, password_hash: hash });
    return success(res, user, 'Registered');
  } catch (e) {
    return error(res, e.message);
  }
}

export async function login(req, res) {
  try {
    const { email, password } = req.body;
    const user = await UserModel.findByEmail(email);
    if (!user) return error(res, 'Invalid credentials', 401);
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return error(res, 'Invalid credentials', 401);
    const token = jwt.sign({ id: user.id, role: user.role, email: user.email }, config.jwt.secret, { expiresIn: config.jwt.expires });
    return success(res, { token, user: { id: user.id, name: user.name, email: user.email, role: user.role } }, 'Logged in');
  } catch (e) {
    return error(res, e.message);
  }
}
