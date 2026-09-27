import React, { useState } from 'react';
import { X, Database, Check, RefreshCw, Send, AlertTriangle } from 'lucide-react';
import { getSavedCredentials, saveCredentials, api } from '../supabaseClient';

export default function SettingsModal({ isOpen, onClose, onConnectionChanged, showToast }) {
  if (!isOpen) return null;

  const credentials = getSavedCredentials();
  const [url, setUrl] = useState(credentials.url);
  const [key, setKey] = useState(credentials.key);
  const [testing, setTesting] = useState(false);
  const [seeding, setSeeding] = useState(false);
  const [testResult, setTestResult] = useState(null);

  const handleSave = async () => {
    saveCredentials(url, key);
    setTesting(true);
    setTestResult(null);

    const res = await api.testConnection();
    setTesting(false);
    setTestResult(res);

    if (res.success) {
      showToast('Supabase connection verified & credentials saved!', 'success');
      onConnectionChanged(true);
    } else {
      showToast(res.message, 'error');
      onConnectionChanged(false);
    }
  };

  const handleSeed = async () => {
    if (!confirm('This will insert standard IELTS Speaking Part 1, 2, and Vocabulary seed rows into your Supabase database. Proceed?')) {
      return;
    }
    setSeeding(true);
    try {
      await api.seedSampleDataToSupabase();
      showToast('Sample IELTS exam questions successfully seeded to Supabase!', 'success');
      onConnectionChanged(true);
      onClose();
    } catch (e) {
      showToast('Seeding failed: ' + (e.message || e), 'error');
    } finally {
      setSeeding(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Database size={20} color="var(--primary-light)" />
            <h3>Supabase Cloud Configuration</h3>
          </div>
          <button 
            className="btn btn-secondary btn-sm" 
            style={{ padding: '6px' }} 
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>

        <div className="modal-body">
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '20px' }}>
            Connect your IELTS Speaky React Admin Panel directly to your Supabase project. Questions uploaded here will immediately synchronize with the Flutter mobile application!
          </p>

          <div className="form-group">
            <label>Supabase Project URL</label>
            <input 
              type="text" 
              className="form-control"
              placeholder="https://your-project.supabase.co"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label>Supabase Anon / Public Key</label>
            <input 
              type="password" 
              className="form-control"
              placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
              value={key}
              onChange={(e) => setKey(e.target.value)}
            />
          </div>

          {testResult && (
            <div style={{
              padding: '12px 14px',
              borderRadius: 'var(--radius-md)',
              backgroundColor: testResult.success ? 'rgba(16, 185, 129, 0.15)' : 'rgba(244, 63, 94, 0.15)',
              border: `1px solid ${testResult.success ? 'var(--emerald)' : 'var(--rose)'}`,
              fontSize: '13px',
              color: testResult.success ? 'var(--emerald)' : 'var(--rose)',
              marginBottom: '18px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              {testResult.success ? <Check size={16} /> : <AlertTriangle size={16} />}
              <span>{testResult.message}</span>
            </div>
          )}

          <div style={{
            backgroundColor: 'var(--bg-secondary)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-md)',
            padding: '14px',
            marginTop: '10px'
          }}>
            <h4 style={{ fontSize: '14px', marginBottom: '4px' }}>⚡ 1-Click Database Population</h4>
            <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '10px' }}>
              Have you run the <code style={{ color: 'var(--secondary)' }}>supabase/schema.sql</code> script in your Supabase SQL Editor? Click below to populate high-scoring sample topics and questions.
            </p>
            <button 
              className="btn btn-secondary btn-sm"
              disabled={seeding || !url || !key}
              onClick={handleSeed}
            >
              {seeding ? <RefreshCw className="spin" size={14} /> : <Send size={14} />}
              <span>{seeding ? 'Seeding Tables...' : 'Seed Sample IELTS Exam Data'}</span>
            </button>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>
            Cancel
          </button>
          <button 
            className="btn btn-primary" 
            disabled={testing}
            onClick={handleSave}
          >
            {testing ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
            <span>Save & Test Connection</span>
          </button>
        </div>
      </div>
    </div>
  );
}
