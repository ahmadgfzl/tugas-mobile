import { pool } from '../db/index.js';

export const PaymentModel = {
  async create({ rental_id, amount, bank_account, proof_url }) {
    // Generate simple order_id: PM-YYYYMMDD-XXXX (random suffix)
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
    const order_id = `PM-${y}${m}${d}-${rand}`;

    const [res] = await pool.query(
      'INSERT INTO payments (rental_id, order_id, amount, bank_account, proof_url) VALUES (?,?,?,?,?)',
      [rental_id, order_id, amount, bank_account, proof_url || null]
    );
    return this.findById(res.insertId);
  },
  async findById(id) {
    const [rows] = await pool.query('SELECT * FROM payments WHERE id = ? LIMIT 1', [id]);
    return rows[0];
  },
  async findByRental(rental_id) {
    const [rows] = await pool.query('SELECT * FROM payments WHERE rental_id = ? ORDER BY id DESC', [rental_id]);
    return rows;
  },
  async listAll() {
    const [rows] = await pool.query('SELECT p.*, r.user_id, r.motorcycle_id FROM payments p JOIN rentals r ON r.id = p.rental_id ORDER BY p.created_at DESC');
    return rows;
  },
  async listByUser(user_id) {
    const [rows] = await pool.query(
      'SELECT p.* FROM payments p JOIN rentals r ON r.id = p.rental_id WHERE r.user_id = ? ORDER BY p.created_at DESC',
      [user_id]
    );
    return rows;
  },
  async updateStatus(id, status) {
    await pool.query('UPDATE payments SET status = ? WHERE id = ?', [status, id]);
    return this.findById(id);
  },
  async attachProof(id, proof_url) {
    await pool.query('UPDATE payments SET proof_url = ? WHERE id = ?', [proof_url, id]);
    return this.findById(id);
  }
};
