import React, { useState, useEffect } from 'react';
import { X, Database, Check, RefreshCw, Send, AlertTriangle, Cpu, Sparkles, Zap } from 'lucide-react';
import { getSavedCredentials, saveCredentials, api } from '../supabaseClient';

export default function SettingsModal({ isOpen, onClose, onConnectionChanged, showToast }) {
  if (!isOpen) return null;

  const credentials = getSavedCredentials();
  const [activeSubTab, setActiveSubTab] = useState('ai'); // 'ai' or 'supabase'
  
  // Supabase states
  const [url, setUrl] = useState(credentials.url);
  const [key, setKey] = useState(credentials.key);
  const [testing, setTesting] = useState(false);
  const [seeding, setSeeding] = useState(false);
  const [testResult, setTestResult] = useState(null);

  // AI Configuration states
  const [geminiKey, setGeminiKey] = useState('');
  const [groqKey, setGroqKey] = useState('');
  const [aiMode, setAiMode] = useState('auto'); // 'auto', 'gemini', 'groq'
  const [savingAi, setSavingAi] = useState(false);

  useEffect(() => {
    // Load app settings
    api.getAppSettings().then((settings) => {
      if (settings) {
        setGeminiKey(settings.gemini_api_key || '');
        setGroqKey(settings.groq_api_key || '');
        setAiMode(settings.active_ai_provider || 'auto');
      }
    });
  }, [isOpen]);

  const handleSaveAll = async () => {
    setTesting(true);
    setTestResult(null);

    // Save Supabase credentials
    saveCredentials(url, key);

    // Save AI Settings to both local storage and Supabase app_settings table
    await api.saveAppSettings({
      gemini_api_key: geminiKey,
      groq_api_key: groqKey,
      active_ai_provider: aiMode,
    });

    let res = { success: true, message: 'Settings saved locally!' };
    if (url && key) {
      res = await api.testConnection();
      onConnectionChanged(res.success);
    }
    
    setTesting(false);
    setTestResult(res);

    if (res.success) {
      showToast('AI Keys & Supabase configurations saved successfully!', 'success');
    } else {
      showToast(res.message, 'error');
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
      <div className="modal-content" style={{ maxWidth: '640px' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Cpu size={22} color="var(--primary-light)" />
            <h3>Platform & AI Engine Configurations</h3>
          </div>
          <button 
            className="btn btn-secondary btn-sm" 
            style={{ padding: '6px' }} 
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>

        {/* Sub-tabs header */}
        <div style={{
          display: 'flex',
          gap: '8px',
          padding: '12px 24px 0 24px',
          borderBottom: '1px solid var(--border)',
          backgroundColor: 'var(--bg-secondary)'
        }}>
          <button
            type="button"
            className={`btn btn-sm ${activeSubTab === 'ai' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ borderRadius: 'var(--radius-md) var(--radius-md) 0 0', borderBottom: 'none' }}
            onClick={() => setActiveSubTab('ai')}
          >
            <Sparkles size={14} />
            <span>AI Speaking Engines (Groq & Gemini)</span>
          </button>
          <button
            type="button"
            className={`btn btn-sm ${activeSubTab === 'supabase' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ borderRadius: 'var(--radius-md) var(--radius-md) 0 0', borderBottom: 'none' }}
            onClick={() => setActiveSubTab('supabase')}
          >
            <Database size={14} />
            <span>Supabase Cloud Database</span>
          </button>
        </div>

        <div className="modal-body" style={{ maxHeight: '65vh', overflowY: 'auto' }}>
          {activeSubTab === 'ai' && (
            <div>
              <div style={{
                backgroundColor: 'rgba(99, 102, 241, 0.08)',
                border: '1px solid rgba(99, 102, 241, 0.25)',
                borderRadius: 'var(--radius-md)',
                padding: '14px',
                marginBottom: '20px'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary-light)', fontWeight: 700, fontSize: '13px', marginBottom: '4px' }}>
                  <Zap size={16} />
                  <span>Dual-Engine Auto-Failover Strategy</span>
                </div>
                <p style={{ fontSize: '12.5px', color: 'var(--text-secondary)', lineHeight: '1.45', margin: 0 }}>
                  Enter your API keys below. The mobile app automatically triggers <strong>both Gemini and Groq</strong> in parallel — whichever engine responds fastest with valid IELTS evaluation is delivered instantly! If one limits or fails, the other seamlessly guarantees 100% uptime.
                </p>
              </div>

              {/* Groq API Key */}
              <div className="form-group">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <label style={{ fontWeight: 600 }}>Groq API Key (Whisper Large V3 + LLaMA 3.3)</label>
                  <a href="https://console.groq.com/keys" target="_blank" rel="noreferrer" style={{ fontSize: '11px', color: 'var(--primary-light)' }}>
                    Get Free Groq Key ↗
                  </a>
                </div>
                <input 
                  type="password" 
                  className="form-control"
                  placeholder="gsk_..."
                  value={groqKey}
                  onChange={(e) => setGroqKey(e.target.value)}
                />
                <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                  Powers ultra-fast speech-to-text (Whisper Large V3) and sub-second reasoning (LLaMA 3.3 70B).
                </span>
              </div>

              {/* Gemini API Key */}
              <div className="form-group" style={{ marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <label style={{ fontWeight: 600 }}>Google Gemini API Key (Multimodal Speech)</label>
                  <a href="https://aistudio.google.com/" target="_blank" rel="noreferrer" style={{ fontSize: '11px', color: 'var(--primary-light)' }}>
                    Get Free Gemini Key ↗
                  </a>
                </div>
                <input 
                  type="password" 
                  className="form-control"
                  placeholder="AIzaSy..."
                  value={geminiKey}
                  onChange={(e) => setGeminiKey(e.target.value)}
                />
                <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                  Direct native multimodal audio processing with Gemini 1.5 & 2.0 Flash.
                </span>
              </div>

              {/* Execution Mode */}
              <div className="form-group" style={{ marginTop: '16px' }}>
                <label style={{ fontWeight: 600 }}>AI Orchestration Mode</label>
                <select 
                  className="form-control"
                  value={aiMode}
                  onChange={(e) => setAiMode(e.target.value)}
                >
                  <option value="auto">⚡ Auto (Dual Race — Whichever returns first wins)</option>
                  <option value="groq">🏎️ Prefer Groq (Whisper + LLaMA 3.3)</option>
                  <option value="gemini">🧠 Prefer Google Gemini 1.5 Flash</option>
                </select>
              </div>
            </div>
          )}

          {activeSubTab === 'supabase' && (
            <div>
              <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '18px' }}>
                Connect directly to your Supabase project. Questions, topics, and AI configurations uploaded here will immediately synchronize with all mobile devices!
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

              <div style={{
                backgroundColor: 'var(--bg-secondary)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)',
                padding: '14px',
                marginTop: '16px'
              }}>
                <h4 style={{ fontSize: '14px', marginBottom: '4px' }}>⚡ 1-Click Database Population</h4>
                <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '10px' }}>
                  Have you run the <code style={{ color: 'var(--secondary)' }}>supabase/schema.sql</code> script in your Supabase SQL Editor? Click below to seed topics, questions, and app_settings.
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
          )}

          {testResult && (
            <div style={{
              marginTop: '18px',
              padding: '12px 14px',
              borderRadius: 'var(--radius-md)',
              backgroundColor: testResult.success ? 'rgba(16, 185, 129, 0.15)' : 'rgba(244, 63, 94, 0.15)',
              border: `1px solid ${testResult.success ? 'var(--emerald)' : 'var(--rose)'}`,
              fontSize: '13px',
              color: testResult.success ? 'var(--emerald)' : 'var(--rose)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              {testResult.success ? <Check size={16} /> : <AlertTriangle size={16} />}
              <span>{testResult.message}</span>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>
            Cancel
          </button>
          <button 
            className="btn btn-primary" 
            disabled={testing}
            onClick={handleSaveAll}
          >
            {testing ? <RefreshCw className="spin" size={16} /> : <Check size={16} />}
            <span>Save All Configurations</span>
          </button>
        </div>
      </div>
    </div>
  );
}
