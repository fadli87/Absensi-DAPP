const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak ditemukan.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'kunci_rahasia_cadangan_123');
    req.user = decoded; // Menyimpan data userId dan role untuk digunakan di rute selanjutnya
    next();
  } catch (error) {
    console.error('[AUTH GAGAL!]', error.message);
    return res.status(403).json({ success: false, message: 'Token tidak valid atau kedaluwarsa.' });
  }
};

module.exports = verifyToken;