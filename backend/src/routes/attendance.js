const express = require('express');
const multer = require('multer');
const path = require('path');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// Konfigurasi penyimpanan file upload (multer)
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/'); // Pastikan folder 'uploads' sudah ada di root backend
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'selfie-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// 1. Endpoint Check-In (Absen Masuk + Selfie + GPS)
router.post('/check-in', verifyToken, upload.single('image'), async (req, res) => {
    try {
        const userId = req.user.userId;
        const { latitude, longitude } = req.body;
        const selfieImage = req.file ? req.file.filename : null;

        // Validasi keberadaan foto dan GPS
        if (!selfieImage) {
            return res.status(400).json({ success: false, message: 'Foto selfie wajib diunggah.' });
        }
        if (!latitude || !longitude) {
            return res.status(400).json({ success: false, message: 'Koordinat GPS tidak valid.' });
        }

        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        const existingAttendance = await prisma.attendance.findFirst({
            where: { userId: userId, date: today }
        });

        if (existingAttendance) {
            return res.status(400).json({ success: false, message: 'Anda sudah melakukan absen masuk hari ini.' });
        }

        // Simpan ke database (pastikan skema prisma Anda mendukung field foto/GPS jika ingin disimpan)
        const newAttendance = await prisma.attendance.create({
            data: {
                userId: userId,
                date: today,
                checkIn: now,
                status: 'PRESENT',
                // latitude: parseFloat(latitude), // Aktifkan jika kolom Prisma sudah ada
                // longitude: parseFloat(longitude),
                // selfie: selfieImage
            }
        });

        res.json({ success: true, message: 'Absen masuk berhasil dicatat!', data: newAttendance });
    } catch (error) {
        console.error('[GAGAL] Error saat Check-in:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 2. Endpoint Check-Out (Absen Pulang + Selfie + GPS)
router.post('/check-out', verifyToken, upload.single('image'), async (req, res) => {
    try {
        const userId = req.user.userId;
        const { latitude, longitude } = req.body;
        const selfieImage = req.file ? req.file.filename : null;

        if (!selfieImage) {
            return res.status(400).json({ success: false, message: 'Foto selfie wajib diunggah untuk check-out.' });
        }

        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        const existingAttendance = await prisma.attendance.findFirst({
            where: { userId: userId, date: today }
        });

        if (!existingAttendance) {
            return res.status(400).json({ success: false, message: 'Anda belum melakukan absen masuk hari ini.' });
        }

        if (existingAttendance.checkOut) {
            return res.status(400).json({ success: false, message: 'Anda sudah melakukan absen pulang hari ini.' });
        }

        const updatedAttendance = await prisma.attendance.update({
            where: { id: existingAttendance.id },
            data: { checkOut: now }
        });

        res.json({ success: true, message: 'Absen pulang berhasil dicatat!', data: updatedAttendance });
    } catch (error) {
        console.error('[GAGAL] Error saat Check-out:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 3. Endpoint Riwayat Absensi Saya
router.get('/my-history', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const history = await prisma.attendance.findMany({
            where: { userId: userId },
            orderBy: { date: 'desc' },
            take: 30
        });

        res.json({ success: true, data: history });
    } catch (error) {
        console.error('[GAGAL] Error saat mengambil riwayat:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

module.exports = router;