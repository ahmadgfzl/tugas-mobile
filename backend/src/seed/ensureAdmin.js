import bcrypt from 'bcrypt';
import { pool } from '../db/index.js';

export async function ensureAdmin() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  if(!email || !password) {
    console.log('[seed] Skip admin seed (missing ADMIN_EMAIL or ADMIN_PASSWORD)');
    return;
  }
  const [rows] = await pool.query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
  if (rows.length) {
    console.log('[seed] Admin already exists');
    return;
  }
  const hash = await bcrypt.hash(password, 10);
  await pool.query('INSERT INTO users (name,email,password_hash,role) VALUES (?,?,?,"admin")', ['Admin', email, hash]);
  console.log('[seed] Admin user created:', email);
}
