// backend/src/index.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const attendanceRoutes = require('./routes/attendance');
const userRoutes = require('./routes/user');
const officeRoutes = require('./routes/office'); // <-- 1. Impor rute office/geofencing

const app = express();

app.use(express.json());
app.use(cors());

// Gunakan rute
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/users', userRoutes);
app.use('/api/office', officeRoutes); // <-- 2. Daftarkan endpoint geofencing

app.get('/', (req, res) => {
  res.json({ message: 'API Absensi Backend is running smoothly!' });
});

const PORT = 5005;
app.listen(PORT, () => {
  console.log(`[BERHASIL] Server is running on port ${PORT}`);
});