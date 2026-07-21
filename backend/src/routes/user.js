// backend/src/routes/user.js
const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');

const router = express.Router();

// ==========================================
// 1. GET /api/users (Ambil daftar semua user)
// ==========================================
router.get('/', async (req, res) => {
    try {
        const users = await prisma.user.findMany({
            // Hanya tampilkan data yang aman (jangan kirim password ke frontend)
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                isActive: true,
                createdAt: true
            },
            orderBy: {
                createdAt: 'desc' // Urutkan dari yang paling baru ditambahkan
            }
        });

        res.json({ success: true, data: users });
    } catch (error) {
        console.error('[GAGAL] Mengambil data users:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// ==========================================
// 2. POST /api/users/create (Tambah user baru)
// ==========================================
router.post('/create', async (req, res) => {
    const { name, email, password, role } = req.body;

    try {
        // Cek apakah email sudah dipakai
        const existingUser = await prisma.user.findFirst({
            where: { email: email }
        });

        if (existingUser) {
            return res.status(400).json({ success: false, message: 'Email sudah terdaftar.' });
        }

        // Enkripsi password sebelum disimpan ke database
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role || 'EMPLOYEE', // Default ke EMPLOYEE jika tidak diisi
            }
        });

        res.status(201).json({
            success: true,
            message: 'User berhasil dibuat',
            data: {
                id: newUser.id,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role
            }
        });
    } catch (error) {
        console.error('[GAGAL] Menambahkan user baru:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
}); // <-- Batas akhir router.post('/create') yang benar

// ==========================================
// 3. PUT /api/users/:id (Edit data user)
// ==========================================
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { name, email, password, role, isActive } = req.body;

    try {
        // Cek apakah user ada
        const userExist = await prisma.user.findUnique({
            where: { id: id }
        });

        if (!userExist) {
            return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
        }

        // Siapkan data yang akan diupdate
        let updateData = {
            name,
            email,
            role,
            isActive
        };

        // Jika password diisi (tidak kosong), enkripsi ulang password baru
        if (password && password.trim() !== '') {
            updateData.password = await bcrypt.hash(password, 10);
        }

        const updatedUser = await prisma.user.update({
            where: { id: id },
            data: updateData,
        });

        res.json({
            success: true,
            message: 'User berhasil diperbarui',
            data: {
                id: updatedUser.id,
                name: updatedUser.name,
                email: updatedUser.email,
                role: updatedUser.role
            }
        });

    } catch (error) {
        console.error('[GAGAL] Memperbarui user:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
}); // <-- Batas akhir router.put('/:id')

module.exports = router;