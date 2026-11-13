import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pool from './src/config/db.js';
import ongRoutes from './src/routes/ongRoutes.js';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());


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

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(` Serveur backend démarré et à l'écoute sur le port ${PORT}`);
});