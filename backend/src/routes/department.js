const express = require('express');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// 1. Ambil semua daftar departemen (GET /api/departments)
router.get('/', verifyToken, async (req, res) => {
    try {
        const departments = await prisma.department.findMany({
            orderBy: { name: 'asc' }
        });
        res.json({ success: true, data: departments });
    } catch (error) {
        console.error('[GAGAL] Mengambil data departemen:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// 2. Tambah departemen baru (POST /api/departments)
router.post('/', verifyToken, async (req, res) => {
    try {
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ success: false, message: 'Nama departemen wajib diisi.' });
        }

        const newDept = await prisma.department.create({
            data: { name }
        });

        res.json({ success: true, message: 'Departemen berhasil ditambahkan!', data: newDept });
    } catch (error) {
        console.error('[GAGAL] Menambah departemen:', error);
        res.status(500).json({ success: false, message: 'Nama departemen mungkin sudah terdaftar.' });
    }
});

// 3. Update departemen (PUT /api/departments/:id)
router.put('/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;

        const updatedDept = await prisma.department.update({
            where: { id: parseInt(id) },
            data: { name }
        });

        res.json({ success: true, message: 'Departemen berhasil diperbarui!', data: updatedDept });
    } catch (error) {
        console.error('[GAGAL] Update departemen:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// 4. Hapus departemen (DELETE /api/departments/:id)
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.department.delete({
            where: { id: parseInt(id) }
        });
        res.json({ success: true, message: 'Departemen berhasil dihapus!' });
    } catch (error) {
        console.error('[GAGAL] Hapus departemen:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

module.exports = router;