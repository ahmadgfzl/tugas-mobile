import { pool } from '../db/index.js';

export const UserModel = {
  async findById(id) {
    const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    return rows[0];
  },
  async findByEmail(email) {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0];
  },
  async create({ name, email, password_hash, role = 'user' }) {
    const [res] = await pool.query(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)',
      [name, email, password_hash, role]
    );
    return { id: res.insertId, name, email, role };
  },
  async update(id, data) {
    const fields = [];
    const values = [];
    Object.entries(data).forEach(([k, v]) => { fields.push(`${k} = ?`); values.push(v); });
    if (!fields.length) return this.findById(id);
    values.push(id);
    await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);
    const u = await this.findById(id);
    // Do not return password hash in result
    if (u) delete u.password_hash;
    return u;
  }
};
