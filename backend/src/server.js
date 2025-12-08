import express from 'express';
import cors from 'cors';
import { config } from './config/env.js';
import { testConnection } from './db/index.js';
import { ensureAdmin } from './seed/ensureAdmin.js';
import { ensureMotorcycles } from './seed/ensureMotorcycles.js';
import { ensureSchema } from './seed/ensureSchema.js';
import authRoutes from './routes/authRoutes.js';
import motorcycleRoutes from './routes/motorcycleRoutes.js';
import rentalRoutes from './routes/rentalRoutes.js';
import userRoutes from './routes/userRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(cors());
app.use(express.json());
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads')));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/motorcycles', motorcycleRoutes);
app.use('/api/rentals', rentalRoutes);
app.use('/api/users', userRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/settings', settingsRoutes);

// Centralized error handler to return JSON for errors (including Multer)
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  const status = err.status || 400;
  const message = err.message || 'Error';
  res.status(status).json({ success: false, message });
});

app.use((req, res) => {
  res.status(404).json({ success:false, message: 'Not Found' });
});

// Utility to find an available port starting from desired
import net from 'net';

function findAvailablePort(startPort, maxTries = 10) {
  return new Promise((resolve, reject) => {
    let port = startPort;
    let attempts = 0;
    const tryPort = () => {
      const server = net.createServer();
      server.unref();
      server.on('error', () => {
        attempts++;
        if (attempts >= maxTries) {
          reject(new Error('No available port found'));
        } else {
          port++;
          tryPort();
        }
      });
      server.listen(port, () => {
        server.close(() => resolve(port));
      });
    };
    tryPort();
  });
}

(async () => {
  try {
    await testConnection();
  await ensureSchema();
    await ensureAdmin();
    await ensureMotorcycles();
    const desiredPort = Number(config.port) || 3000;
    const actualPort = await findAvailablePort(desiredPort);
    if (actualPort !== desiredPort) {
      console.warn(`[port] ${desiredPort} in use, switched to ${actualPort}`);
    }
    app.listen(actualPort, () => console.log('Server running on port ' + actualPort));
  } catch (e) {
    console.error('Failed to start server', e);
    process.exit(1);
  }
})();
