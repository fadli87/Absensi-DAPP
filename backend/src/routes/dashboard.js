const express = require('express');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

router.get('/summary', verifyToken, async (req, res) => {
    try {
        const { date } = req.query;
        const targetDate = date ? new Date(date) : new Date();
        const dayStart = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());
        const dayEnd = new Date(dayStart);
        dayEnd.setDate(dayEnd.getDate() + 1);

        // Semua pegawai aktif
        const employees = await prisma.user.findMany({
            where: { isActive: true },
            select: {
                id: true,
                name: true,
                email: true,
                department: { select: { name: true } },
            },
        });

        // Absensi hari ini
        const todayAttendance = await prisma.attendance.findMany({
            where: { date: dayStart },
        });
        const attendanceByUserId = {};
        todayAttendance.forEach((a) => {
            attendanceByUserId[a.userId] = a;
        });

        // Cuti/izin yang disetujui dan mencakup tanggal ini
        const approvedLeaves = await prisma.leaveRequest.findMany({
            where: {
                status: 'APPROVED',
                startDate: { lte: dayEnd },
                endDate: { gte: dayStart },
            },
        });
        const leaveUserIds = new Set(approvedLeaves.map((l) => l.userId));

        const present = [];
        const late = [];
        const onLeave = [];
        const notYetCheckedIn = [];

        for (const emp of employees) {
            const attendance = attendanceByUserId[emp.id];
            const empData = {
                id: emp.id,
                name: emp.name,
                email: emp.email,
                department: emp.department?.name || '-',
            };

            if (attendance) {
                if (attendance.status === 'LATE') {
                    late.push({ ...empData, checkIn: attendance.checkIn });
                } else {
                    present.push({ ...empData, checkIn: attendance.checkIn });
                }
            } else if (leaveUserIds.has(emp.id)) {
                onLeave.push(empData);
            } else {
                notYetCheckedIn.push(empData);
            }
        }

        res.json({
            success: true,
            data: {
                date: dayStart.toISOString().split('T')[0],
                totalEmployees: employees.length,
                summary: {
                    present: present.length,
                    late: late.length,
                    onLeave: onLeave.length,
                    notYetCheckedIn: notYetCheckedIn.length,
                },
                details: {
                    present,
                    late,
                    onLeave,
                    notYetCheckedIn,
                },
            },
        });
    } catch (error) {
        console.error('[GAGAL] Ambil ringkasan dashboard:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

module.exports = router;