const express = require('express');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    console.log(`[DEBUG] Mencoba login dengan email: ${email}`);

    // GANTI menjadi findFirst agar lebih aman dan tidak rewel soal @unique
    // Hapus sementara 'include' agar tidak bentrok dengan schema database
    const user = await prisma.user.findFirst({
      where: { email: email }
    });

    if (!user) {
      console.log(`[DEBUG] Email tidak ditemukan di database.`);
      return res.status(404).json({ success: false, message: 'Email tidak ditemukan.' });
    }

    if (password !== user.password) {
      console.log(`[DEBUG] Password yang dimasukkan salah.`);
      return res.status(401).json({ success: false, message: 'Password salah.' });
    }

    const secretKey = process.env.JWT_SECRET || 'kunci_rahasia_cadangan_123';
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      secretKey,
      { expiresIn: '1d' }
    );

    console.log(`[DEBUG] Login BERHASIL untuk: ${user.name}`);
    res.json({ success: true, token, data: { name: user.name, role: user.role } });

  } catch (error) {
    console.error('[GAGAL] Error terdeteksi saat login:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error_detail: error.message
    });
  }
});

module.exports = router;