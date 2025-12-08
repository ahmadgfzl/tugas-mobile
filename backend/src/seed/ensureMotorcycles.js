import { pool } from '../db/index.js';

export async function ensureMotorcycles() {
  if (process.env.DISABLE_MOTO_SEED === '1') {
    console.log('[seed] Skip motorcycle seed (DISABLE_MOTO_SEED=1)');
    return;
  }
  const [rows] = await pool.query('SELECT COUNT(*) as c FROM motorcycles');
  if (rows[0].c > 0) {
    console.log('[seed] Motorcycles already present');
    return;
  }
  const samples = [
    ['Honda', 'Vario 125', 'B1234AA', 65000, 1],
    ['Yamaha', 'NMAX 155', 'B5678BB', 90000, 1],
    ['Suzuki', 'Satria F150', 'B2468CC', 75000, 1]
  ];
  await pool.query('INSERT INTO motorcycles (brand, model, plate_number, price_per_day, available) VALUES ?',[samples]);
  console.log('[seed] Inserted default motorcycles:', samples.length);
}
