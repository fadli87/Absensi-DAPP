require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const attendanceRoutes = require('./routes/attendance'); // <-- 1. Impor rute absensi

const app = express();

app.use(express.json());
app.use(cors());

// Gunakan rute
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes); // <-- 2. Daftarkan jalur endpoint-nya

app.get('/', (req, res) => {
  res.json({ message: 'API Absensi Backend is running smoothly!' });
});

const PORT = 5005;
app.listen(PORT, () => {
  console.log(`[BERHASIL] Server is running on port ${PORT}`);
});