const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

const router = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ status: 'error', message: 'Email and password are required' });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        department: true,
        shift: true,
      },
    });

    if (!user) {
      return res.status(401).json({ status: 'error', message: 'Invalid email or password' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ status: 'error', message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const { password: _, ...userWithoutPassword } = user;

    res.json({
      status: 'success',
      message: 'Login successful',
      data: {
        token,
        user: userWithoutPassword,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// POST /api/auth/register (Admin only — for creating new users)
router.post('/register', async (req, res) => {
  const { email, password, name, role, departmentId, shiftId } = req.body;

  if (!email || !password || !name || !departmentId || !shiftId) {
    return res.status(400).json({
      status: 'error',
      message: 'email, password, name, departmentId, and shiftId are required',
    });
  }

  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ status: 'error', message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        role: role || 'EMPLOYEE',
        departmentId: parseInt(departmentId),
        shiftId: parseInt(shiftId),
      },
      include: {
        department: true,
        shift: true,
      },
    });

    const { password: _, ...userWithoutPassword } = user;

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: userWithoutPassword,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

module.exports = router;
