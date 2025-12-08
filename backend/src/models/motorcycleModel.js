import { pool } from '../db/index.js';

export const MotorcycleModel = {
  async all() {
    const [rows] = await pool.query('SELECT * FROM motorcycles');
    return rows;
  },
  async find(id) {
    const [rows] = await pool.query('SELECT * FROM motorcycles WHERE id = ?', [id]);
    return rows[0];
  },
  async create({ brand, model, plate_number, price_per_day, available = 1 }) {
    const [res] = await pool.query(
      'INSERT INTO motorcycles (brand, model, plate_number, price_per_day, available) VALUES (?,?,?,?,?)',
      [brand, model, plate_number, price_per_day, available]
    );
    return { id: res.insertId, brand, model, plate_number, price_per_day, available, image_url: null };
  },
  async update(id, data) {
    const fields = [];
    const values = [];
    Object.entries(data).forEach(([k, v]) => {
      fields.push(`${k} = ?`);
      values.push(v);
    });
    if (!fields.length) return this.find(id);
    values.push(id);
    await pool.query(`UPDATE motorcycles SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.find(id);
  },
  async remove(id) {
    await pool.query('DELETE FROM motorcycles WHERE id = ?', [id]);
    return true;
  }
};
