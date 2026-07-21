require('dotenv').config();
const bcrypt = require('bcryptjs');
const prisma = require('../src/lib/prisma');

async function main() {
  console.log('🌱 Starting seed...');

  // Create Departments
  const dept = await prisma.department.upsert({
    where: { name: 'IT' },
    update: {},
    create: { name: 'IT' },
  });
  console.log('✅ Department:', dept.name);

  // Create Shifts
  const shift = await prisma.shift.upsert({
    where: { id: 1 },
    update: {},
    create: { name: 'Morning', startTime: '08:00', endTime: '17:00' },
  });
  console.log('✅ Shift:', shift.name);

  // Create Admin user
  const hashedPassword = await bcrypt.hash('admin123', 10);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@dappcorp.com' },
    update: {},
    create: {
      email: 'admin@dappcorp.com',
      password: hashedPassword,
      name: 'Admin DAPP',
      role: 'ADMIN',
      departmentId: dept.id,
      shiftId: shift.id,
    },
  });
  console.log('✅ Admin user:', admin.email);

  console.log('🎉 Seed completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
