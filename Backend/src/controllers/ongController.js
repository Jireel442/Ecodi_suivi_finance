import pool from '../config/db.js';
export const listerMembres = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT m.*, c.nom AS centre_nom, n.libelle AS niveau_libelle 
      FROM membre m
      JOIN centre c ON m.centre_id = c.id
      LEFT JOIN niveau n ON m.niveau_id = n.id
      WHERE m.statut = 'actif'
    `);
    res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Erreur listerMembres:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const creerMembre = async (req, res) => {
  const { nom, prenom, sexe, telephone, centre_id, niveau_id, est_moniteur, date_inscription } = req.body;
  try {
    const [result] = await pool.query(
      `INSERT INTO membre (nom, prenom, sexe, telephone, centre_id, niveau_id, est_moniteur, date_inscription) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [nom, prenom, sexe, telephone, centre_id, niveau_id || null, est_moniteur || 0, date_inscription]
    );
    res.status(201).json({ success: true, message: 'Membre créé avec succès', id: result.insertId });
  } catch (error) {
    console.error('Erreur creerMembre:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const listerOperationsCaisse = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT op.*, e.libelle AS exercice_libelle, u.email AS saisi_par_email
      FROM operation_caisse op
      JOIN exercice e ON op.exercice_id = e.id
      JOIN utilisateur u ON op.saisi_par = u.id
      ORDER BY op.date_operation DESC, op.id DESC
    `);
    res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Erreur listerOperationsCaisse:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const obtenirSoldeCaisse = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        SUM(CASE WHEN sens = 'entree' THEN montant ELSE 0 END) AS total_entrees,
        SUM(CASE WHEN sens = 'sortie' THEN montant ELSE 0 END) AS total_sorties,
        (SUM(CASE WHEN sens = 'entree' THEN montant ELSE 0 END) - 
         SUM(CASE WHEN sens = 'sortie' THEN montant ELSE 0 END)) AS solde_actuel
      FROM operation_caisse
    `);
    res.status(200).json({ success: true, data: rows[0] });
  } catch (error) {
    console.error('Erreur obtenirSoldeCaisse:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const listerMateriel = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT m.*, tm.libelle AS type_libelle
      FROM materiel m
      JOIN type_materiel tm ON m.type_materiel_id = tm.id
    `);
    res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Erreur listerMateriel:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const listerActivites = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT a.*, CONCAT(m.prenom, ' ', m.nom) AS responsable_nom
      FROM activite a
      JOIN membre m ON a.responsable_id = m.id
      ORDER BY a.date_prevue DESC
    `);
    res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Erreur listerActivites:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};