const express = require('express');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// 1. Endpoint Check-In (Absen Masuk)
router.post('/check-in', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        const existingAttendance = await prisma.attendance.findFirst({
            where: { userId: userId, date: today }
        });

        if (existingAttendance) {
            return res.status(400).json({ success: false, message: 'Anda sudah melakukan absen masuk hari ini.' });
        }

        const newAttendance = await prisma.attendance.create({
            data: { userId: userId, date: today, checkIn: now, status: 'PRESENT' }
        });

        res.json({ success: true, message: 'Absen masuk berhasil dicatat!', data: newAttendance });
    } catch (error) {
        console.error('[GAGAL] Error saat Check-in:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 2. Endpoint Check-Out (Absen Pulang) - BARU
router.post('/check-out', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        // Cari data absen hari ini
        const existingAttendance = await prisma.attendance.findFirst({
            where: { userId: userId, date: today }
        });

        if (!existingAttendance) {
            return res.status(400).json({ success: false, message: 'Anda belum melakukan absen masuk hari ini.' });
        }

        if (existingAttendance.checkOut) {
            return res.status(400).json({ success: false, message: 'Anda sudah melakukan absen pulang hari ini.' });
        }

        // Update waktu checkOut
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

// 3. Endpoint Riwayat Absensi Saya - BARU
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