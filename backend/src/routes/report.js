const express = require('express');
const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');
const prisma = require('../lib/prisma');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// Helper: ambil data absensi sesuai filter
async function getFilteredAttendance({ startDate, endDate, departmentId, userId, status }) {
    const where = {};

    if (startDate && endDate) {
        where.date = {
            gte: new Date(startDate),
            lte: new Date(endDate),
        };
    }
    if (userId) {
        where.userId = parseInt(userId);
    }
    if (status) {
        where.status = status;
    }
    if (departmentId) {
        where.user = { departmentId: parseInt(departmentId) };
    }

    return prisma.attendance.findMany({
        where,
        include: {
            user: {
                select: { id: true, name: true, email: true, department: { select: { name: true } } },
            },
        },
        orderBy: [{ date: 'asc' }, { userId: 'asc' }],
    });
}

// Helper: hitung ringkasan per pegawai
function buildSummary(records) {
    const summaryMap = {};

    for (const r of records) {
        const key = r.userId;
        if (!summaryMap[key]) {
            summaryMap[key] = {
                userId: r.userId,
                name: r.user.name,
                department: r.user.department?.name || '-',
                present: 0,
                late: 0,
                permit: 0,
                absent: 0,
                total: 0,
            };
        }
        summaryMap[key].total += 1;
        if (r.status === 'PRESENT') summaryMap[key].present += 1;
        if (r.status === 'LATE') summaryMap[key].late += 1;
        if (r.status === 'PERMIT') summaryMap[key].permit += 1;
        if (r.status === 'ABSENT') summaryMap[key].absent += 1;
    }

    return Object.values(summaryMap);
}

// 1. Data laporan (JSON, untuk ditampilkan di tabel Flutter)
router.get('/attendance', verifyToken, async (req, res) => {
    try {
        const { startDate, endDate, departmentId, userId, status } = req.query;
        const records = await getFilteredAttendance({ startDate, endDate, departmentId, userId, status });
        const summary = buildSummary(records);

        res.json({
            success: true,
            data: {
                records,
                summary,
            },
        });
    } catch (error) {
        console.error('[GAGAL] Ambil laporan absensi:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// 2. Export Excel
router.get('/attendance/export/excel', verifyToken, async (req, res) => {
    try {
        const { startDate, endDate, departmentId, userId, status } = req.query;
        const records = await getFilteredAttendance({ startDate, endDate, departmentId, userId, status });

        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('Laporan Absensi');

        sheet.columns = [
            { header: 'Tanggal', key: 'date', width: 15 },
            { header: 'Nama', key: 'name', width: 25 },
            { header: 'Departemen', key: 'department', width: 20 },
            { header: 'Check In', key: 'checkIn', width: 20 },
            { header: 'Check Out', key: 'checkOut', width: 20 },
            { header: 'Status', key: 'status', width: 12 },
        ];

        records.forEach((r) => {
            sheet.addRow({
                date: r.date.toISOString().split('T')[0],
                name: r.user.name,
                department: r.user.department?.name || '-',
                checkIn: r.checkIn ? r.checkIn.toLocaleTimeString('id-ID') : '-',
                checkOut: r.checkOut ? r.checkOut.toLocaleTimeString('id-ID') : '-',
                status: r.status,
            });
        });

        sheet.getRow(1).font = { bold: true };

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=laporan_absensi.xlsx');

        await workbook.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('[GAGAL] Export excel laporan:', error);
        res.status(500).json({ success: false, message: 'Gagal export excel' });
    }
});

// 3. Export PDF
router.get('/attendance/export/pdf', verifyToken, async (req, res) => {
    try {
        const { startDate, endDate, departmentId, userId, status } = req.query;
        const records = await getFilteredAttendance({ startDate, endDate, departmentId, userId, status });

        const doc = new PDFDocument({ margin: 30, size: 'A4', layout: 'landscape' });

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'attachment; filename=laporan_absensi.pdf');
        doc.pipe(res);

        doc.fontSize(16).text('Laporan Absensi', { align: 'center' });
        doc.moveDown();

        const tableTop = doc.y;
        const colWidths = [80, 140, 120, 100, 100, 80];
        const headers = ['Tanggal', 'Nama', 'Departemen', 'Check In', 'Check Out', 'Status'];

        let x = doc.x;
        headers.forEach((h, i) => {
            doc.fontSize(10).font('Helvetica-Bold').text(h, x, tableTop, { width: colWidths[i] });
            x += colWidths[i];
        });

        let y = tableTop + 20;
        doc.font('Helvetica');

        records.forEach((r) => {
            x = doc.x;
            const row = [
                r.date.toISOString().split('T')[0],
                r.user.name,
                r.user.department?.name || '-',
                r.checkIn ? r.checkIn.toLocaleTimeString('id-ID') : '-',
                r.checkOut ? r.checkOut.toLocaleTimeString('id-ID') : '-',
                r.status,
            ];
            row.forEach((val, i) => {
                doc.fontSize(9).text(String(val), 30 + colWidths.slice(0, i).reduce((a, b) => a + b, 0), y, {
                    width: colWidths[i],
                });
            });
            y += 18;
            if (y > 500) {
                doc.addPage({ layout: 'landscape' });
                y = 40;
            }
        });

        doc.end();
    } catch (error) {
        console.error('[GAGAL] Export pdf laporan:', error);
        res.status(500).json({ success: false, message: 'Gagal export pdf' });
    }
});

module.exports = router;