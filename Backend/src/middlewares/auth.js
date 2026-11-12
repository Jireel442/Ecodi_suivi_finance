import jwt from 'jsonwebtoken';

export const verifierToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: "Accès refusé. Token manquant." });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'votre_secret_jwt', (err, utilisateur) => {
    if (err) {
      return res.status(403).json({ success: false, message: "Token invalide ou expiré." });
    }
    req.user = utilisateur; 
    next();
  });
};

export const verifierRole = (rolesAutorises) => {
  return (req, res, next) => {
    if (!req.user || !rolesAutorises.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        message: "Accès non autorisé pour votre grade / rôle." 
      });
    }
    next();
  };
};