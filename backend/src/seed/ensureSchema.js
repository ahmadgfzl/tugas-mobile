import { pool } from '../db/index.js';

export async function ensureSchema() {
  // Tambah kolom image_url kalau belum ada
  try {
    const [rows] = await pool.query("SHOW COLUMNS FROM motorcycles LIKE 'image_url'");
    if(rows.length === 0) {
      await pool.query('ALTER TABLE motorcycles ADD COLUMN image_url VARCHAR(255) NULL');
      console.log('[schema] Added motorcycles.image_url');
    }
  } catch(e) {
    console.error('[schema] Failed ensure image_url column', e.message);
  }

  // Tabel motorcycle_images untuk multi gambar per motor
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS motorcycle_images (
        id INT AUTO_INCREMENT PRIMARY KEY,
        motorcycle_id INT NOT NULL,
        image_url VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_mi_motorcycle FOREIGN KEY (motorcycle_id)
          REFERENCES motorcycles(id) ON DELETE CASCADE
      ) ENGINE=InnoDB;
    `);
    // index sederhana untuk lookup per motor
    await pool.query('CREATE INDEX IF NOT EXISTS idx_mi_motorcycle_id ON motorcycle_images(motorcycle_id)');
  } catch (e) {
    // Beberapa MySQL versi lama tidak mendukung "IF NOT EXISTS" pada CREATE INDEX
    // Abaikan error index jika tabel sudah ada / index sudah ada
    if (!/ER_DUP_KEYNAME|exists/i.test(e.message)) {
      console.error('[schema] Failed ensure motorcycle_images', e.message);
    }
  }

  // Kolom avatar_url pada users
  try {
    const [cols] = await pool.query("SHOW COLUMNS FROM users LIKE 'avatar_url'");
    if (cols.length === 0) {
      await pool.query('ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) NULL');
      console.log('[schema] Added users.avatar_url');
    }
  } catch (e) {
    console.error('[schema] Failed ensure users.avatar_url', e.message);
  }

  // Payments table for bank transfer proof and status
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        rental_id INT NOT NULL,
        order_id VARCHAR(32) UNIQUE,
        amount DECIMAL(10,2) NOT NULL,
        bank_account VARCHAR(100) NOT NULL,
        proof_url VARCHAR(255) NULL,
        status ENUM('pending','confirmed','rejected') DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_pay_rental FOREIGN KEY (rental_id)
          REFERENCES rentals(id) ON DELETE CASCADE
      ) ENGINE=InnoDB;
    `);
    console.log('[schema] Ensured payments table');
  } catch (e) {
    console.error('[schema] Failed ensure payments', e.message);
  }

  // Ensure order_id column exists (for older tables without it)
  try {
    const [cols] = await pool.query("SHOW COLUMNS FROM payments LIKE 'order_id'");
    if (cols.length === 0) {
      await pool.query('ALTER TABLE payments ADD COLUMN order_id VARCHAR(32) UNIQUE');
      console.log('[schema] Added payments.order_id');
    }
  } catch (e) {
    console.error('[schema] Failed ensure payments.order_id', e.message);
  }

  // Backfill missing order_id for existing payments
  try {
    const [rows] = await pool.query("SELECT id, created_at FROM payments WHERE order_id IS NULL OR order_id = ''");
    if (rows.length > 0) {
      for (const row of rows) {
        const dt = new Date(row.created_at || Date.now());
        const y = dt.getFullYear();
        const m = String(dt.getMonth() + 1).padStart(2, '0');
        const d = String(dt.getDate()).padStart(2, '0');
        const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
        const orderId = `PM-${y}${m}${d}-${rand}`;
        await pool.query('UPDATE payments SET order_id = ? WHERE id = ?', [orderId, row.id]);
      }
      console.log(`[schema] Backfilled order_id for ${rows.length} payments`);
    }
  } catch (e) {
    console.error('[schema] Failed backfill payments.order_id', e.message);
  }
}
