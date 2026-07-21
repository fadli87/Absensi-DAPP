const express = require('express');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// 1. Ambil semua daftar shift (GET /api/shifts)
router.get('/', verifyToken, async (req, res) => {
    try {
        const shifts = await prisma.shift.findMany({
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, data: shifts });
    } catch (error) {
        console.error('[GAGAL] Mengambil data shift:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 2. Tambah shift baru (POST /api/shifts) - Khusus Admin/HR
router.post('/', verifyToken, async (req, res) => {
    try {
        const { name, checkInTime, checkOutTime, toleranceMinutes } = req.body;

        if (!name || !checkInTime || !checkOutTime) {
            return res.status(400).json({ success: false, message: 'Nama shift, jam masuk, dan jam pulang wajib diisi.' });
        }

        const newShift = await prisma.shift.create({
            data: {
                name,
                checkInTime,
                checkOutTime,
                toleranceMinutes: toleranceMinutes ? parseInt(toleranceMinutes) : 15
            }
        });

        res.json({ success: true, message: 'Shift baru berhasil ditambahkan!', data: newShift });
    } catch (error) {
        console.error('[GAGAL] Menambah shift:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 3. Update shift (PUT /api/shifts/:id)
router.put('/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, checkInTime, checkOutTime, toleranceMinutes } = req.body;

        const updatedShift = await prisma.shift.update({
            where: { id: parseInt(id) },
            data: {
                name,
                checkInTime,
                checkOutTime,
                toleranceMinutes: toleranceMinutes ? parseInt(toleranceMinutes) : 15
            }
        });

        res.json({ success: true, message: 'Shift berhasil diperbarui!', data: updatedShift });
    } catch (error) {
        console.error('[GAGAL] Update shift:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

// 4. Hapus shift (DELETE /api/shifts/:id)
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;

        await prisma.shift.delete({
            where: { id: parseInt(id) }
        });

        res.json({ success: true, message: 'Shift berhasil dihapus!' });
    } catch (error) {
        console.error('[GAGAL] Hapus shift:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error_detail: error.message });
    }
});

module.exports = router;