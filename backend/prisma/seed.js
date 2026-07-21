// backend/prisma/seed.js
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Konfigurasi Driver Adapter untuk Prisma 7
const connectionString = process.env.DIRECT_URL || process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Memulai proses seeding...');

  const hashedPassword = await bcrypt.hash('admin123', 10);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@dapp.com' },
    update: {},
    create: {
      name: 'Super Admin',
      email: 'admin@dapp.com',
      password: hashedPassword,
      role: 'ADMIN',
      isActive: true,
    },
  });

  console.log('-----------------------------------');
  console.log('Berhasil membuat user pertama!');
  console.log(`Email    : ${admin.email}`);
  console.log(`Password : admin123`);
  console.log(`Role     : ${admin.role}`);
  console.log('-----------------------------------');
}

main()
  .catch((e) => {
    console.error('Error saat seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });