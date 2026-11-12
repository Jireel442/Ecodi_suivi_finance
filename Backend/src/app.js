import express from 'express';
import cors from 'cors';
import ongRoutes from './routes/ongRoutes.js';

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API de gestion financière et patrimoniale de l’ONG en ligne',
    timestamp: new Date().toISOString()
  });
});

app.use('/api', ongRoutes);

app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: "L'endpoint demandé est introuvable."
  });
});
app.use((err, req, res, next) => {
  console.error('Erreur interne du serveur :', err.stack);
  res.status(500).json({
    success: false,
    message: 'Erreur interne du serveur',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

export default app;