import React, { useState, useEffect } from 'react';
import api from './api';
import { LogIn, LogOut, History, User } from 'lucide-react';

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [email, setEmail] = useState('admin@dappcorp.com');
  const [password, setPassword] = useState('admin123');

  const [message, setMessage] = useState({ text: '', type: '' });
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (token) {
      fetchHistory();
    }
  }, [token]);

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      const res = await api.post('/auth/login', { email, password });
      localStorage.setItem('token', res.data.token);
      setToken(res.data.token);
      setMessage({ text: 'Login berhasil!', type: 'success' });
    } catch (err) {
      setMessage({ text: err.response?.data?.message || 'Gagal login', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken('');
    setHistory([]);
    setMessage({ text: 'Berhasil logout.', type: 'success' });
  };

  const handleCheckIn = async () => {
    try {
      setLoading(true);
      const res = await api.post('/attendance/check-in');
      setMessage({ text: res.data.message, type: 'success' });
      fetchHistory();
    } catch (err) {
      setMessage({ text: err.response?.data?.message || 'Gagal check-in', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleCheckOut = async () => {
    try {
      setLoading(true);
      const res = await api.post('/attendance/check-out');
      setMessage({ text: res.data.message, type: 'success' });
      fetchHistory();
    } catch (err) {
      setMessage({ text: err.response?.data?.message || 'Gagal check-out', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const fetchHistory = async () => {
    try {
      const res = await api.get('/attendance/my-history');
      setHistory(res.data.data);
    } catch (err) {
      console.error('Gagal memuat riwayat');
    }
  };

  if (!token) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <div style={styles.header}>
            <User size={36} color="#2563eb" />
            <h2 style={styles.title}>Absensi DAPP - Login</h2>
          </div>

          {message.text && (
            <div style={message.type === 'success' ? styles.alertSuccess : styles.alertError}>
              {message.text}
            </div>
          )}

          <form onSubmit={handleLogin} style={styles.form}>
            <div style={styles.inputGroup}>
              <label style={styles.label}>Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={styles.input}
                required
              />
            </div>
            <div style={styles.inputGroup}>
              <label style={styles.label}>Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={styles.input}
                required
              />
            </div>
            <button type="submit" style={styles.button} disabled={loading}>
              {loading ? 'Memproses...' : 'Masuk Dashboard'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.dashboardContainer}>
      <header style={styles.navBar}>
        <h1 style={styles.navTitle}>🚀 Dashboard Absensi DAPP</h1>
        <button onClick={handleLogout} style={styles.logoutButton}>Logout</button>
      </header>

      <main style={styles.mainContent}>
        {message.text && (
          <div style={message.type === 'success' ? styles.alertSuccess : styles.alertError}>
            {message.text}
          </div>
        )}

        <div style={styles.actionCardContainer}>
          <div style={styles.actionCard}>
            <h3 style={styles.cardHeading}>Absen Masuk</h3>
            <p style={styles.subText}>Catat waktu kedatangan Anda hari ini dengan akurat.</p>
            <button onClick={handleCheckIn} style={styles.checkInBtn} disabled={loading}>
              <LogIn size={20} style={{ marginRight: 8 }} /> Check In Sekarang
            </button>
          </div>

          <div style={styles.actionCard}>
            <h3 style={styles.cardHeading}>Absen Pulang</h3>
            <p style={styles.subText}>Catat waktu kepulangan Anda setelah jam kerja selesai.</p>
            <button onClick={handleCheckOut} style={styles.checkOutBtn} disabled={loading}>
              <LogOut size={20} style={{ marginRight: 8 }} /> Check Out Sekarang
            </button>
          </div>
        </div>

        <div style={styles.historySection}>
          <h3 style={styles.historyHeading}>
            <History size={22} color="#2563eb" /> Riwayat Absensi Anda
          </h3>
          <div style={styles.tableWrapper}>
            <table style={styles.table}>
              <thead>
                <tr style={styles.thRow}>
                  <th style={styles.th}>Tanggal</th>
                  <th style={styles.th}>Jam Masuk</th>
                  <th style={styles.th}>Jam Pulang</th>
                  <th style={styles.th}>Status</th>
                </tr>
              </thead>
              <tbody>
                {history.length === 0 ? (
                  <tr>
                    <td colSpan="4" style={styles.noData}>Belum ada riwayat absensi tercatat.</td>
                  </tr>
                ) : (
                  history.map((item) => (
                    <tr key={item.id} style={styles.tr}>
                      <td style={styles.tdBold}>{new Date(item.date).toLocaleDateString()}</td>
                      <td style={styles.td}>{item.checkIn ? new Date(item.checkIn).toLocaleTimeString() : '-'}</td>
                      <td style={styles.td}>{item.checkOut ? new Date(item.checkOut).toLocaleTimeString() : 'Belum Pulang'}</td>
                      <td style={styles.td}>
                        <span style={styles.badge}>{item.status}</span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}

const styles = {
  container: { display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', backgroundColor: '#f1f5f9', fontFamily: 'Inter, system-ui, sans-serif' },
  card: { background: '#ffffff', padding: '2.5rem', borderRadius: '16px', boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1)', width: '100%', maxWidth: '420px', border: '1px solid #e2e8f0' },
  header: { display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '1.75rem' },
  title: { fontSize: '1.4rem', fontWeight: '800', color: '#0f172a', letterSpacing: '-0.025em' },
  form: { display: 'flex', flexDirection: 'column', gap: '1.25rem' },
  inputGroup: { display: 'flex', flexDirection: 'column', gap: '0.5rem' },
  label: { fontSize: '0.95rem', fontWeight: '700', color: '#334155' },
  input: { padding: '0.85rem 1rem', borderRadius: '8px', border: '2px solid #cbd5e1', fontSize: '1rem', color: '#0f172a', fontWeight: '600', outline: 'none' },
  button: { padding: '0.85rem', background: '#2563eb', color: '#ffffff', border: 'none', borderRadius: '8px', fontSize: '1rem', fontWeight: '700', cursor: 'pointer' },

  dashboardContainer: { minHeight: '100vh', backgroundColor: '#f8fafc', fontFamily: 'Inter, system-ui, sans-serif' },
  navBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem 3rem', background: '#ffffff', borderBottom: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' },
  navTitle: { fontSize: '1.35rem', fontWeight: '800', color: '#0f172a', letterSpacing: '-0.025em' },
  logoutButton: { padding: '0.6rem 1.25rem', background: '#ef4444', color: '#ffffff', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: '700', fontSize: '0.9rem' },

  mainContent: { padding: '2rem 3rem', maxWidth: '1100px', margin: '0 auto' },
  actionCardContainer: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2rem' },
  actionCard: { background: '#ffffff', padding: '1.75rem 2rem', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)', border: '1px solid #e2e8f0' },
  cardHeading: { fontSize: '1.2rem', fontWeight: '800', color: '#1e293b', marginBottom: '0.5rem' },
  subText: { color: '#475569', fontSize: '0.95rem', fontWeight: '500', marginBottom: '1.5rem', lineHeight: '1.5' },

  checkInBtn: { display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%', padding: '0.85rem', background: '#059669', color: '#ffffff', border: 'none', borderRadius: '8px', fontWeight: '700', fontSize: '1rem', cursor: 'pointer', boxShadow: '0 4px 10px rgba(5, 150, 105, 0.2)' },
  checkOutBtn: { display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%', padding: '0.85rem', background: '#d97706', color: '#ffffff', border: 'none', borderRadius: '8px', fontWeight: '700', fontSize: '1rem', cursor: 'pointer', boxShadow: '0 4px 10px rgba(217, 119, 6, 0.2)' },

  historySection: { background: '#ffffff', padding: '2rem', borderRadius: '12px', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)' },
  historyHeading: { display: 'flex', alignItems: 'center', gap: '10px', fontSize: '1.2rem', fontWeight: '800', color: '#0f172a', marginBottom: '1rem' },
  tableWrapper: { overflowX: 'auto', marginTop: '1rem' },
  table: { width: '100%', borderCollapse: 'collapse', textAlign: 'left' },
  thRow: { borderBottom: '2px solid #cbd5e1', background: '#f1f5f9' },
  th: { padding: '1rem', fontSize: '0.9rem', color: '#1e293b', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.05em' },
  tr: { borderBottom: '1px solid #e2e8f0' },
  td: { padding: '1rem', fontSize: '0.95rem', color: '#334155', fontWeight: '600' },
  tdBold: { padding: '1rem', fontSize: '0.95rem', color: '#0f172a', fontWeight: '800' },
  noData: { textAlign: 'center', padding: '2rem', color: '#64748b', fontWeight: '600' },
  badge: { padding: '0.35rem 0.75rem', background: '#d1fae5', color: '#047857', borderRadius: '6px', fontSize: '0.85rem', fontWeight: '800', letterSpacing: '0.05em' },

  alertSuccess: { padding: '1rem', marginBottom: '1.25rem', background: '#d1fae5', color: '#065f46', borderRadius: '8px', fontSize: '0.95rem', fontWeight: '700', border: '1px solid #a7f3d0' },
  alertError: { padding: '1rem', marginBottom: '1.25rem', background: '#fee2e2', color: '#991b1b', borderRadius: '8px', fontSize: '0.95rem', fontWeight: '700', border: '1px solid #fecaca' }
};