import { pool } from '../db/index.js'

export const MotorcycleImageModel = {
	async add(motorcycle_id, image_url) {
		const [res] = await pool.query(
			'INSERT INTO motorcycle_images (motorcycle_id, image_url) VALUES (?, ?)',
			[motorcycle_id, image_url]
		);
		return { id: res.insertId, motorcycle_id, image_url };
	},
	async listByMotorcycle(motorcycle_id) {
		const [rows] = await pool.query(
			'SELECT id, motorcycle_id, image_url, created_at FROM motorcycle_images WHERE motorcycle_id = ? ORDER BY id ASC',
			[motorcycle_id]
		);
		return rows;
	},
	async findById(id) {
		const [rows] = await pool.query(
			'SELECT id, motorcycle_id, image_url, created_at FROM motorcycle_images WHERE id = ?',
			[id]
		);
		return rows[0];
	},
	async removeById(id) {
		await pool.query('DELETE FROM motorcycle_images WHERE id = ?', [id]);
		return true;
	}
}
