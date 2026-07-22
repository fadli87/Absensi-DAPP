const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth'); // <-- Pastikan middleware auth diimpor

const router = express.Router();

// ==========================================
// 1. GET /api/users (Ambil daftar semua user + Shift & Departemen)
// ==========================================
router.get('/', verifyToken, async (req, res) => {
    try {
        const users = await prisma.user.findMany({
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                departmentId: true,
                shiftId: true,
                isActive: true,
                createdAt: true,
                department: {
                    select: {
                        id: true,
                        name: true
                    }
                },
                shift: {
                    select: {
                        id: true,
                        name: true,
                        checkInTime: true,
                        checkOutTime: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
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
router.post('/create', verifyToken, async (req, res) => {
    const { name, email, password, role, departmentId, shiftId } = req.body;

    try {
        const existingUser = await prisma.user.findFirst({
            where: { email: email }
        });

        if (existingUser) {
            return res.status(400).json({ success: false, message: 'Email sudah terdaftar.' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role || 'EMPLOYEE',
                departmentId: departmentId ? parseInt(departmentId) : null,
                shiftId: shiftId ? parseInt(shiftId) : null,
            }
        });

        res.status(201).json({
            success: true,
            message: 'User berhasil dibuat',
            data: {
                id: newUser.id,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role,
                departmentId: newUser.departmentId,
                shiftId: newUser.shiftId
            }
        });
    } catch (error) {
        console.error('[GAGAL] Menambahkan user baru:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// ==========================================
// 3. PUT /api/users/:id (Edit data user)
// ==========================================
router.put('/:id', verifyToken, async (req, res) => {
    const { id } = req.params;
    const numericId = parseInt(id);
    const { name, email, password, role, departmentId, shiftId, isActive } = req.body;

    try {
        const userExist = await prisma.user.findUnique({
            where: { id: numericId }
        });

        if (!userExist) {
            return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
        }

        let updateData = {
            name,
            email,
            role,
            departmentId: departmentId ? parseInt(departmentId) : null,
            shiftId: shiftId ? parseInt(shiftId) : null,
            isActive
        };

        if (password && password.trim() !== '') {
            updateData.password = await bcrypt.hash(password, 10);
        }

        const updatedUser = await prisma.user.update({
            where: { id: numericId },
            data: updateData,
        });

        res.json({
            success: true,
            message: 'User berhasil diperbarui',
            data: {
                id: updatedUser.id,
                name: updatedUser.name,
                email: updatedUser.email,
                role: updatedUser.role,
                departmentId: updatedUser.departmentId,
                shiftId: updatedUser.shiftId
            }
        });

    } catch (error) {
        console.error('[GAGAL] Memperbarui user:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

module.exports = router;