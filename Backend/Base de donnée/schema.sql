CREATE DATABASE IF NOT EXISTS `ong_gestion_financiere`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `ong_gestion_financiere`;

CREATE TABLE `centre` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(100) NOT NULL COMMENT 'Ex: Centre temple, Mont-sinai, Gloire-de-Dieu, Bethanie, FranceVille, Mayama, Kimpondzou',
  `actif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_centre_nom` (`nom`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `niveau` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `libelle` VARCHAR(50) NOT NULL COMMENT 'Niveau1 à Niveau4',
  `centre_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_niveau_centre_libelle` (`centre_id`, `libelle`),
  CONSTRAINT `fk_niveau_centre` FOREIGN KEY (`centre_id`) REFERENCES `centre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `membre` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `sexe` ENUM('M', 'F') NOT NULL,
  `telephone` VARCHAR(30) NULL,
  `centre_id` INT UNSIGNED NOT NULL,
  `niveau_id` INT UNSIGNED NULL COMMENT 'Nullable pour les adultes et encadreurs',
  `est_moniteur` TINYINT(1) NOT NULL DEFAULT 0,
  `statut` ENUM('actif', 'inactif') NOT NULL DEFAULT 'actif',
  `date_inscription` DATE NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_membre_centre` (`centre_id`),
  KEY `idx_membre_niveau` (`niveau_id`),
  CONSTRAINT `fk_membre_centre` FOREIGN KEY (`centre_id`) REFERENCES `centre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_membre_niveau` FOREIGN KEY (`niveau_id`) REFERENCES `niveau` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `groupe` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `contact` VARCHAR(150) NULL COMMENT 'Téléphone ou email',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_groupe_nom` (`nom`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` ENUM('directrice', 'directrice_adjointe', 'secretaire_generale', 'charge_finance', 'charge_patrimoine') NOT NULL,
  `libelle` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `utilisateur` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `membre_id` INT UNSIGNED NOT NULL,
  `email` VARCHAR(150) NOT NULL,
  `mot_de_passe_hash` VARCHAR(255) NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `actif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_utilisateur_email` (`email`),
  UNIQUE KEY `uk_utilisateur_membre` (`membre_id`),
  KEY `idx_utilisateur_role` (`role_id`),
  CONSTRAINT `fk_utilisateur_membre` FOREIGN KEY (`membre_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_utilisateur_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_permission` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` INT UNSIGNED NOT NULL,
  `module` ENUM('finance', 'programmation', 'archives', 'patrimoine', 'bilans') NOT NULL,
  `droit` ENUM('lecture', 'ecriture') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_module` (`role_id`, `module`),
  CONSTRAINT `fk_permission_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `exercice` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `libelle` VARCHAR(50) NOT NULL COMMENT 'Ex: 2026',
  `date_debut` DATE NOT NULL,
  `date_fin` DATE NOT NULL,
  `cloture` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Empêche les modifications après bilan',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_exercice_libelle` (`libelle`),
  CONSTRAINT `ck_exercice_dates` CHECK (`date_fin` > `date_debut`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `evenement` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `titre` VARCHAR(150) NOT NULL,
  `type` ENUM('fete_fermeture', 'occasion_speciale') NOT NULL,
  `date_evenement` DATE NOT NULL,
  `budget_prevu` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `exercice_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_evenement_exercice` (`exercice_id`),
  CONSTRAINT `ck_evenement_budget` CHECK (`budget_prevu` >= 0),
  CONSTRAINT `fk_evenement_exercice` FOREIGN KEY (`exercice_id`) REFERENCES `exercice` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `operation_caisse` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sens` ENUM('entree', 'sortie') NOT NULL,
  `categorie` ENUM('collecte', 'don', 'vente', 'cotisation', 'subvention', 'depense') NOT NULL,
  `montant` DECIMAL(12, 2) NOT NULL,
  `date_operation` DATE NOT NULL,
  `exercice_id` INT UNSIGNED NOT NULL,
  `evenement_id` INT UNSIGNED NULL COMMENT 'Nullable : rattache l operation à une fête',
  `operation_origine_id` INT UNSIGNED NULL COMMENT 'Renseigné quand cette ligne annule une autre opération',
  `saisi_par` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_op_exercice` (`exercice_id`),
  KEY `idx_op_evenement` (`evenement_id`),
  UNIQUE KEY `uk_op_origine` (`operation_origine_id`),
  KEY `idx_op_saisi_par` (`saisi_par`),
  KEY `idx_op_date` (`date_operation`),
  CONSTRAINT `ck_op_montant` CHECK (`montant` > 0),
  CONSTRAINT `ck_op_sens_categorie` CHECK (
    `operation_origine_id` IS NOT NULL
    OR `categorie` = 'vente'
    OR (`categorie` = 'depense' AND `sens` = 'sortie')
    OR (`categorie` NOT IN ('depense', 'vente') AND `sens` = 'entree')
  ),
  CONSTRAINT `fk_op_exercice` FOREIGN KEY (`exercice_id`) REFERENCES `exercice` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_op_evenement` FOREIGN KEY (`evenement_id`) REFERENCES `evenement` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_op_origine` FOREIGN KEY (`operation_origine_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_op_utilisateur` FOREIGN KEY (`saisi_par`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `collecte` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `date_dimanche` DATE NOT NULL,
  `centre_id` INT UNSIGNED NOT NULL,
  `niveau_id` INT UNSIGNED NULL COMMENT 'Nullable si suivi global par centre',
  `niveau_cle` INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`niveau_id`, 0)) STORED COMMENT 'Sert à bloquer les doublons même quand niveau_id est vide',
  `montant` DECIMAL(12, 2) NOT NULL,
  `operation_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_collecte_dimanche_centre_niveau` (`date_dimanche`, `centre_id`, `niveau_cle`),
  UNIQUE KEY `uk_collecte_operation` (`operation_id`),
  KEY `idx_collecte_centre` (`centre_id`),
  KEY `idx_collecte_niveau` (`niveau_id`),
  CONSTRAINT `ck_collecte_montant` CHECK (`montant` > 0),
  CONSTRAINT `fk_collecte_centre` FOREIGN KEY (`centre_id`) REFERENCES `centre` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_collecte_niveau` FOREIGN KEY (`niveau_id`) REFERENCES `niveau` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_collecte_operation` FOREIGN KEY (`operation_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `don` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `donateur_nom` VARCHAR(150) NULL COMMENT 'Nom libre si donateur externe',
  `membre_id` INT UNSIGNED NULL COMMENT 'Nullable si le donateur est un membre',
  `montant` DECIMAL(12, 2) NOT NULL,
  `destination` ENUM('fete_fermeture', 'occasion_speciale', 'general') NOT NULL DEFAULT 'general',
  `evenement_id` INT UNSIGNED NULL,
  `mode_paiement` VARCHAR(50) NOT NULL COMMENT 'espèces, mobile money, virement, etc.',
  `date_don` DATE NOT NULL,
  `operation_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_don_operation` (`operation_id`),
  KEY `idx_don_membre` (`membre_id`),
  KEY `idx_don_evenement` (`evenement_id`),
  CONSTRAINT `ck_don_montant` CHECK (`montant` > 0),
  CONSTRAINT `ck_don_donateur` CHECK (`donateur_nom` IS NOT NULL OR `membre_id` IS NOT NULL),
  CONSTRAINT `fk_don_membre` FOREIGN KEY (`membre_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_don_evenement` FOREIGN KEY (`evenement_id`) REFERENCES `evenement` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_don_operation` FOREIGN KEY (`operation_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vente` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `date_vente` DATE NOT NULL,
  `centre_id` INT UNSIGNED NOT NULL,
  `cout_achat` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `recette` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `benefice` DECIMAL(12, 2) GENERATED ALWAYS AS (`recette` - `cout_achat`) STORED,
  `operation_entree_id` INT UNSIGNED NOT NULL,
  `operation_sortie_id` INT UNSIGNED NULL COMMENT 'Nullable si coût achat avancé hors caisse',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_vente_date` (`date_vente`),
  UNIQUE KEY `uk_vente_op_entree` (`operation_entree_id`),
  UNIQUE KEY `uk_vente_op_sortie` (`operation_sortie_id`),
  KEY `idx_vente_centre` (`centre_id`),
  CONSTRAINT `ck_vente_montants` CHECK (`cout_achat` >= 0 AND `recette` >= 0),
  CONSTRAINT `fk_vente_centre` FOREIGN KEY (`centre_id`) REFERENCES `centre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_vente_op_entree` FOREIGN KEY (`operation_entree_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_vente_op_sortie` FOREIGN KEY (`operation_sortie_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vente_moniteur` (
  `vente_id` INT UNSIGNED NOT NULL,
  `moniteur_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`vente_id`, `moniteur_id`),
  KEY `idx_vm_moniteur` (`moniteur_id`),
  CONSTRAINT `fk_vm_vente` FOREIGN KEY (`vente_id`) REFERENCES `vente` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_vm_moniteur` FOREIGN KEY (`moniteur_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rotation_vente` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `date_dimanche` DATE NOT NULL,
  `centre_id` INT UNSIGNED NOT NULL,
  `statut` ENUM('prevu', 'effectue') NOT NULL DEFAULT 'prevu',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rotation_dimanche` (`date_dimanche`),
  KEY `idx_rotation_centre` (`centre_id`),
  CONSTRAINT `fk_rotation_centre` FOREIGN KEY (`centre_id`) REFERENCES `centre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `type_cotisation` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `libelle` VARCHAR(150) NOT NULL,
  `montant_defaut` DECIMAL(12, 2) NULL COMMENT '1000, 500, 2500, etc. ; NULL si variable',
  `montant_libre` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Vrai pour fête de fermeture et achat matériel',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_cotisation_libelle` (`libelle`),
  CONSTRAINT `ck_type_cotisation_montant` CHECK (`montant_defaut` IS NULL OR `montant_defaut` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cotisation_campagne` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_cotisation_id` INT UNSIGNED NOT NULL,
  `motif` VARCHAR(255) NOT NULL,
  `membre_concerne_id` INT UNSIGNED NULL COMMENT 'Nullable : membre touché par décès, mariage, maladie',
  `montant_unitaire` DECIMAL(12, 2) NULL,
  `date_ouverture` DATE NOT NULL,
  `date_cloture` DATE NULL,
  `evenement_id` INT UNSIGNED NULL,
  `exercice_id` INT UNSIGNED NOT NULL,
  `statut` ENUM('ouverte', 'cloturee') NOT NULL DEFAULT 'ouverte',
  PRIMARY KEY (`id`),
  KEY `idx_campagne_type` (`type_cotisation_id`),
  KEY `idx_campagne_membre` (`membre_concerne_id`),
  KEY `idx_campagne_evenement` (`evenement_id`),
  KEY `idx_campagne_exercice` (`exercice_id`),
  CONSTRAINT `ck_campagne_montant` CHECK (`montant_unitaire` IS NULL OR `montant_unitaire` >= 0),
  CONSTRAINT `fk_campagne_type` FOREIGN KEY (`type_cotisation_id`) REFERENCES `type_cotisation` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_campagne_membre` FOREIGN KEY (`membre_concerne_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_campagne_evenement` FOREIGN KEY (`evenement_id`) REFERENCES `evenement` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_campagne_exercice` FOREIGN KEY (`exercice_id`) REFERENCES `exercice` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cotisation_paiement` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `campagne_id` INT UNSIGNED NOT NULL,
  `membre_id` INT UNSIGNED NOT NULL,
  `montant` DECIMAL(12, 2) NOT NULL,
  `date_paiement` DATE NOT NULL,
  `operation_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_paiement_campagne_membre` (`campagne_id`, `membre_id`),
  UNIQUE KEY `uk_paiement_operation` (`operation_id`),
  KEY `idx_paiement_membre` (`membre_id`),
  CONSTRAINT `ck_paiement_montant` CHECK (`montant` > 0),
  CONSTRAINT `fk_paiement_campagne` FOREIGN KEY (`campagne_id`) REFERENCES `cotisation_campagne` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_paiement_membre` FOREIGN KEY (`membre_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_paiement_operation` FOREIGN KEY (`operation_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `subvention` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source` VARCHAR(150) NOT NULL COMMENT 'Organisme ou bailleur',
  `objet` VARCHAR(255) NOT NULL,
  `montant` DECIMAL(12, 2) NOT NULL,
  `date_reception` DATE NOT NULL,
  `justificatif_url` VARCHAR(255) NULL,
  `operation_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_subvention_operation` (`operation_id`),
  CONSTRAINT `ck_subvention_montant` CHECK (`montant` > 0),
  CONSTRAINT `fk_subvention_operation` FOREIGN KEY (`operation_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `depense` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `libelle` VARCHAR(255) NOT NULL,
  `categorie` ENUM('fete', 'materiel', 'vente', 'aide_membre', 'autre') NOT NULL,
  `montant` DECIMAL(12, 2) NOT NULL,
  `date_depense` DATE NOT NULL,
  `evenement_id` INT UNSIGNED NULL,
  `campagne_id` INT UNSIGNED NULL COMMENT 'Nullable : utilisation des fonds d une cotisation',
  `justificatif_url` VARCHAR(255) NULL,
  `operation_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_depense_operation` (`operation_id`),
  KEY `idx_depense_evenement` (`evenement_id`),
  KEY `idx_depense_campagne` (`campagne_id`),
  CONSTRAINT `ck_depense_montant` CHECK (`montant` > 0),
  CONSTRAINT `fk_depense_evenement` FOREIGN KEY (`evenement_id`) REFERENCES `evenement` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_depense_campagne` FOREIGN KEY (`campagne_id`) REFERENCES `cotisation_campagne` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_depense_operation` FOREIGN KEY (`operation_id`) REFERENCES `operation_caisse` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `type_materiel` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `libelle` VARCHAR(100) NOT NULL COMMENT 'Chaises, bâches, sonorisation, etc.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_materiel_libelle` (`libelle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `materiel` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_materiel_id` INT UNSIGNED NOT NULL,
  `designation` VARCHAR(150) NOT NULL,
  `quantite` INT UNSIGNED NOT NULL DEFAULT 0,
  `etat` ENUM('bonne', 'assez_bonne', 'mauvaise') NOT NULL DEFAULT 'bonne',
  `date_acquisition` DATE NOT NULL,
  `campagne_id` INT UNSIGNED NULL COMMENT 'Nullable : matériel acquis via une campagne de cotisation',
  PRIMARY KEY (`id`),
  KEY `idx_materiel_type` (`type_materiel_id`),
  KEY `idx_materiel_campagne` (`campagne_id`),
  CONSTRAINT `fk_materiel_type` FOREIGN KEY (`type_materiel_id`) REFERENCES `type_materiel` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_materiel_campagne` FOREIGN KEY (`campagne_id`) REFERENCES `cotisation_campagne` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `historique_etat_materiel` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `materiel_id` INT UNSIGNED NOT NULL,
  `ancien_etat` ENUM('bonne', 'assez_bonne', 'mauvaise') NOT NULL,
  `nouvel_etat` ENUM('bonne', 'assez_bonne', 'mauvaise') NOT NULL,
  `modifie_par` INT UNSIGNED NOT NULL,
  `date_modification` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hist_materiel` (`materiel_id`),
  KEY `idx_hist_utilisateur` (`modifie_par`),
  CONSTRAINT `fk_hist_materiel` FOREIGN KEY (`materiel_id`) REFERENCES `materiel` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_hist_utilisateur` FOREIGN KEY (`modifie_par`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sortie_materiel` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `materiel_id` INT UNSIGNED NOT NULL,
  `quantite` INT UNSIGNED NOT NULL,
  `emprunteur_membre_id` INT UNSIGNED NULL,
  `emprunteur_libre` VARCHAR(150) NULL COMMENT 'Nom libre si emprunteur externe',
  `motif` VARCHAR(255) NOT NULL,
  `date_sortie` DATE NOT NULL,
  `date_retour_prevue` DATE NOT NULL,
  `date_retour` DATE NULL,
  `etat_sortie` ENUM('bonne', 'assez_bonne', 'mauvaise') NOT NULL,
  `etat_retour` ENUM('bonne', 'assez_bonne', 'mauvaise') NULL,
  `enregistre_par` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sortie_materiel` (`materiel_id`),
  KEY `idx_sortie_membre` (`emprunteur_membre_id`),
  KEY `idx_sortie_utilisateur` (`enregistre_par`),
  CONSTRAINT `ck_sortie_quantite` CHECK (`quantite` > 0),
  CONSTRAINT `ck_sortie_emprunteur` CHECK (`emprunteur_membre_id` IS NOT NULL OR `emprunteur_libre` IS NOT NULL),
  CONSTRAINT `fk_sortie_materiel` FOREIGN KEY (`materiel_id`) REFERENCES `materiel` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sortie_membre` FOREIGN KEY (`emprunteur_membre_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sortie_utilisateur` FOREIGN KEY (`enregistre_par`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `activite` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `titre` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `lieu` VARCHAR(150) NULL,
  `date_prevue` DATE NOT NULL,
  `statut` ENUM('a_realiser', 'realisee', 'non_tenue') NOT NULL DEFAULT 'a_realiser',
  `motif_non_tenue` TEXT NULL,
  `responsable_id` INT UNSIGNED NOT NULL,
  `evenement_id` INT UNSIGNED NULL,
  `cree_par` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_activite_responsable` (`responsable_id`),
  KEY `idx_activite_evenement` (`evenement_id`),
  KEY `idx_activite_cree_par` (`cree_par`),
  CONSTRAINT `ck_activite_motif` CHECK (`statut` <> 'non_tenue' OR `motif_non_tenue` IS NOT NULL),
  CONSTRAINT `fk_activite_responsable` FOREIGN KEY (`responsable_id`) REFERENCES `membre` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_activite_evenement` FOREIGN KEY (`evenement_id`) REFERENCES `evenement` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_activite_utilisateur` FOREIGN KEY (`cree_par`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `demande` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `groupe_id` INT UNSIGNED NOT NULL,
  `objet` VARCHAR(255) NOT NULL,
  `date_demande` DATE NOT NULL,
  `statut` ENUM('en_attente', 'repondue', 'classee') NOT NULL DEFAULT 'en_attente',
  PRIMARY KEY (`id`),
  KEY `idx_demande_groupe` (`groupe_id`),
  CONSTRAINT `fk_demande_groupe` FOREIGN KEY (`groupe_id`) REFERENCES `groupe` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `document_archive` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` ENUM('demande', 'reponse', 'invitation', 'autre') NOT NULL,
  `titre` VARCHAR(200) NOT NULL,
  `demande_id` INT UNSIGNED NULL COMMENT 'Nullable : rattache une réponse à sa demande',
  `groupe_id` INT UNSIGNED NULL,
  `fichier_url` VARCHAR(255) NOT NULL,
  `date_document` DATE NOT NULL,
  `depose_par` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_doc_demande` (`demande_id`),
  KEY `idx_doc_groupe` (`groupe_id`),
  KEY `idx_doc_utilisateur` (`depose_par`),
  CONSTRAINT `fk_doc_demande` FOREIGN KEY (`demande_id`) REFERENCES `demande` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_doc_groupe` FOREIGN KEY (`groupe_id`) REFERENCES `groupe` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_doc_utilisateur` FOREIGN KEY (`depose_par`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `journal_audit` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `utilisateur_id` INT UNSIGNED NOT NULL,
  `action` ENUM('creation', 'modification', 'suppression') NOT NULL,
  `table_cible` VARCHAR(100) NOT NULL,
  `enregistrement_id` INT UNSIGNED NOT NULL,
  `date_action` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_utilisateur` (`utilisateur_id`),
  KEY `idx_audit_cible` (`table_cible`, `enregistrement_id`),
  CONSTRAINT `fk_audit_utilisateur` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateur` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `centre` (`nom`, `actif`) VALUES
('Centre temple', 1),
('Mont-sinai', 1),
('Gloire-de-Dieu', 1),
('Bethanie', 1),
('FranceVille', 1),
('Mayama', 1),
('Kimpondzou', 1);

INSERT INTO `niveau` (`libelle`, `centre_id`)
SELECT n.`libelle`, c.`id`
FROM `centre` c
CROSS JOIN (
  SELECT 'Niveau1' AS `libelle` UNION ALL SELECT 'Niveau2' UNION ALL SELECT 'Niveau3' UNION ALL SELECT 'Niveau4'
) n;

INSERT INTO `role` (`code`, `libelle`) VALUES
('directrice', 'Directrice'),
('directrice_adjointe', 'Directrice adjointe'),
('secretaire_generale', 'Secrétaire générale'),
('charge_finance', 'Chargé(e) des finances'),
('charge_patrimoine', 'Chargé(e) du patrimoine');

-- Directrice : lecture sur tous les modules
INSERT INTO `role_permission` (`role_id`, `module`, `droit`)
SELECT r.`id`, m.`module`, 'lecture'
FROM `role` r
CROSS JOIN (
  SELECT 'finance' AS `module` UNION ALL SELECT 'programmation' UNION ALL SELECT 'archives'
  UNION ALL SELECT 'patrimoine' UNION ALL SELECT 'bilans'
) m
WHERE r.`code` = 'directrice';

INSERT INTO `role_permission` (`role_id`, `module`, `droit`) SELECT `id`, 'finance', 'ecriture' FROM `role` WHERE `code` = 'charge_finance';
INSERT INTO `role_permission` (`role_id`, `module`, `droit`) SELECT `id`, 'programmation', 'ecriture' FROM `role` WHERE `code` = 'directrice_adjointe';
INSERT INTO `role_permission` (`role_id`, `module`, `droit`) SELECT `id`, 'archives', 'ecriture' FROM `role` WHERE `code` = 'secretaire_generale';
INSERT INTO `role_permission` (`role_id`, `module`, `droit`) SELECT `id`, 'patrimoine', 'ecriture' FROM `role` WHERE `code` = 'charge_patrimoine';

INSERT INTO `type_cotisation` (`libelle`, `montant_defaut`, `montant_libre`) VALUES
('Décès d''un membre', 1000.00, 0),
('Décès d''un parent', 500.00, 0),
('Mariage', 2500.00, 0),
('Maladie', 1000.00, 0),
('Fête de fermeture', NULL, 1),
('Achat de matériel', NULL, 1);

INSERT INTO `exercice` (`libelle`, `date_debut`, `date_fin`) VALUES ('2026', '2026-01-01', '2026-12-31');

INSERT INTO `type_materiel` (`libelle`) VALUES ('Chaises'), ('Bâches'), ('Sonorisation'), ('Autre');
