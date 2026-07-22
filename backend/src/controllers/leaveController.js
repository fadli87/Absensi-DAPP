const prisma = require('../lib/prisma');

const createLeaveRequest = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { startDate, endDate, reason } = req.body;

        if (!startDate || !endDate || !reason) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }

        const leaveRequest = await prisma.leaveRequest.create({
            data: {
                userId,
                startDate: new Date(startDate),
                endDate: new Date(endDate),
                reason,
                status: 'PENDING',
            },
        });

        res.status(201).json({
            message: 'Pengajuan cuti/izin berhasil dikirim',
            data: leaveRequest,
        });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const getMyLeaveRequests = async (req, res) => {
    try {
        const userId = req.user.userId;
        const requests = await prisma.leaveRequest.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });

        res.status(200).json({ data: requests });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const getAllLeaveRequests = async (req, res) => {
    try {
        const requests = await prisma.leaveRequest.findMany({
            include: {
                user: {
                    select: { name: true, email: true, department: true },
                },
            },
            orderBy: { createdAt: 'desc' },
        });

        res.status(200).json({ data: requests });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const updateLeaveStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, adminNotes } = req.body;

        if (!['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ message: 'Status tidak valid' });
        }

        const updated = await prisma.leaveRequest.update({
            where: { id: parseInt(id) },
            data: {
                status,
                adminNotes: adminNotes || null,
            },
        });

        res.status(200).json({
            message: `Pengajuan berhasil di-${status === 'APPROVED' ? 'setujui' : 'tolak'}`,
            data: updated,
        });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

module.exports = {
    createLeaveRequest,
    getMyLeaveRequests,
    getAllLeaveRequests,
    updateLeaveStatus,
};