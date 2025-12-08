import { pool } from '../db/index.js';

export const RentalModel = {
  async create({ user_id, motorcycle_id, start_date, end_date, total_price }) {
    const [res] = await pool.query(
      'INSERT INTO rentals (user_id, motorcycle_id, start_date, end_date, total_price) VALUES (?,?,?,?,?)',
      [user_id, motorcycle_id, start_date, end_date, total_price]
    );
    return { id: res.insertId, user_id, motorcycle_id, start_date, end_date, total_price };
  },
  async byUser(user_id) {
    const [rows] = await pool.query(
      'SELECT r.*, m.brand, m.model, m.plate_number FROM rentals r JOIN motorcycles m ON r.motorcycle_id = m.id WHERE r.user_id = ? ORDER BY r.id DESC',
      [user_id]
    );
    return rows;
  },
  async all() {
    const [rows] = await pool.query(
      'SELECT r.*, u.name as user_name, m.brand, m.model FROM rentals r JOIN users u ON r.user_id = u.id JOIN motorcycles m ON r.motorcycle_id = m.id ORDER BY r.id DESC'
    );
    return rows;
  },
  async updateStatus(id, status) {
    await pool.query('UPDATE rentals SET status = ? WHERE id = ?', [status, id]);
    const [rows] = await pool.query('SELECT * FROM rentals WHERE id = ?', [id]);
    return rows[0];
  }
};
