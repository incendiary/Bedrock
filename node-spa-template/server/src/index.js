import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Serve uploaded files
app.use('/uploads', express.static(join(__dirname, '../../uploads')));

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', project: 'PROJECT_NAME' });
});

// TODO: import and mount your route modules here
// import itemsRouter from './routes/items.js';
// app.use('/api/items', itemsRouter);

// SPA fallback — serve built client in production
app.use(express.static(join(__dirname, '../public')));
app.get('*', (_req, res) => {
  res.sendFile(join(__dirname, '../public/index.html'));
});

app.listen(PORT, () => {
  console.log(`PROJECT_NAME server running on http://localhost:${PORT}`);
});
