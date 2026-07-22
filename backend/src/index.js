// backend/src/index.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const attendanceRoutes = require('./routes/attendance');
const userRoutes = require('./routes/user');
const officeRoutes = require('./routes/office');
const shiftRoutes = require('./routes/shift'); // <-- 1. Impor rute shift
const departmentRoutes = require('./routes/department'); // <-- 1. Impor rute department
const reportRoutes = require('./routes/report'); // <-- 1. Impor rute report
const leaveRoutes = require('./routes/leave');

const app = express();

app.use(express.json());
app.use(cors());

// Gunakan rute
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/users', userRoutes);
app.use('/api/office', officeRoutes);
app.use('/api/shifts', shiftRoutes); // <-- 2. Daftarkan endpoint shift
app.use('/api/departments', departmentRoutes); // <-- 2. Daftarkan endpoint department
app.use('/api/reports', reportRoutes); // <-- 2. Daftarkan endpoint report
app.use('/api/leaves', leaveRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'API Absensi Backend is running smoothly!' });
});

const PORT = 5005;
app.listen(PORT, () => {
  console.log(`[BERHASIL] Server is running on port ${PORT}`);
});