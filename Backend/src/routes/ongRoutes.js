import express from 'express';
import {
  listerMembres,
  creerMembre,
  listerOperationsCaisse,
  obtenirSoldeCaisse,
  listerMateriel,
  listerActivites
} from '../controllers/ongController.js';
import { verifierToken, verifierRole } from '../middlewares/auth.js';

const router = express.Router();

router.get('/activites', listerActivites);

router.get('/membres', verifierToken, verifierRole(['admin', 'moniteur']), listerMembres);
router.post('/membres', verifierToken, verifierRole(['admin']), creerMembre);

router.get('/caisse/operations', verifierToken, verifierRole(['admin', 'moniteur']), listerOperationsCaisse);
router.get('/caisse/solde', verifierToken, verifierRole(['admin', 'moniteur']), obtenirSoldeCaisse);

router.get('/materiel', verifierToken, verifierRole(['admin', 'moniteur']), listerMateriel);

export default router;