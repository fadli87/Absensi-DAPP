const express = require('express');
const router = express.Router();
const { verifyToken, isAdmin } = require('../middleware/auth');
const {
    createLeaveRequest,
    getMyLeaveRequests,
    getAllLeaveRequests,
    updateLeaveStatus,
} = require('../controllers/leaveController');

// Route Karyawan
router.post('/', verifyToken, createLeaveRequest);
router.get('/my', verifyToken, getMyLeaveRequests);

// Route Admin
router.get('/admin/all', verifyToken, isAdmin, getAllLeaveRequests);
router.put('/admin/:id/status', verifyToken, isAdmin, updateLeaveStatus);

module.exports = router;