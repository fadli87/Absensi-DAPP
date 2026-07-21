const express = require('express');
const prisma = require('../lib/prisma'); // Pastikan path ini benar mengarah ke folder lib/prisma.js

const router = express.Router();

// GET /api/office
router.get('/', async (req, res) => {
    try {
        let office = await prisma.officeLocation.findFirst();

        if (!office) {
            office = await prisma.officeLocation.create({
                data: {
                    name: 'Kantor Utama DAPP',
                    latitude: -7.7202781,
                    longitude: 109.0126426,
                    radius: 150,
                }
            });
        }

        res.json({ success: true, data: office });
    } catch (error) {
        console.error('[GAGAL GET OFFICE]:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// PUT /api/office
router.put('/', async (req, res) => {
    const { name, latitude, longitude, radius } = req.body;

    try {
        const parsedLat = parseFloat(latitude);
        const parsedLng = parseFloat(longitude);
        const parsedRadius = parseInt(radius, 10);

        if (isNaN(parsedLat) || isNaN(parsedLng) || isNaN(parsedRadius)) {
            return res.status(400).json({ success: false, message: 'Latitude, longitude, dan radius harus angka.' });
        }

        let office = await prisma.officeLocation.findFirst();

        if (office) {
            office = await prisma.officeLocation.update({
                where: { id: office.id },
                data: {
                    name: name || office.name,
                    latitude: parsedLat,
                    longitude: parsedLng,
                    radius: parsedRadius,
                }
            });
        } else {
            office = await prisma.officeLocation.create({
                data: {
                    name: name || 'Kantor Utama DAPP',
                    latitude: parsedLat,
                    longitude: parsedLng,
                    radius: parsedRadius,
                }
            });
        }

        res.json({ success: true, message: 'Pengaturan geofencing berhasil disimpan', data: office });
    } catch (error) {
        console.error('[GAGAL PUT OFFICE]:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;