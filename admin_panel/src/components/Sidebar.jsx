import React from 'react';
import {
  LayoutDashboard,
  MessageSquare,
  FileText,
  BookOpen,
  Settings,
} from 'lucide-react';

export default function Sidebar({
  activeTab,
  setActiveTab,
  counts,
  isSupabaseConnected,
  openSettings,
}) {
  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'part1', label: 'Part 1 Topics & Qs', icon: MessageSquare, badge: counts.topics },
    { id: 'cue_cards', label: 'Part 2 Cue Cards', icon: FileText, badge: counts.cueCards },
    { id: 'vocabulary', label: 'Band 8+ Lexis', icon: BookOpen, badge: counts.vocabulary },
  ];

  return (
    <aside className="sidebar">
      {/* Brand */}
      <div className="brand-logo">
        <div className="brand-icon">
          <MessageSquare size={20} />
        </div>
        <div className="brand-text">
          <h2>Speaky</h2>
          <span>Admin Studio</span>
        </div>
      </div>

      {/* Nav Menu */}
      <nav className="nav-menu">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              className={`nav-item ${isActive ? 'active' : ''}`}
              onClick={() => setActiveTab(item.id)}
            >
              <Icon size={18} />
              <span>{item.label}</span>
              {item.badge !== undefined && (
                <span className="nav-badge">{item.badge}</span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Database Connection Pill */}
      <div className="db-status-box">
        <div className="db-status-header">
          <div className="status-indicator">
            <span className={`status-dot ${isSupabaseConnected ? 'connected' : 'local'}`} />
            <span>{isSupabaseConnected ? 'Supabase Live' : 'Local Storage Mode'}</span>
          </div>
          <button 
            className="btn btn-secondary btn-sm" 
            style={{ padding: '4px 8px' }} 
            onClick={openSettings}
            title="Configure Supabase"
          >
            <Settings size={14} />
          </button>
        </div>
        <p style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
          {isSupabaseConnected 
            ? 'Synced directly with cloud DB' 
            : 'Using cached mode. Connect to Supabase for mobile app sync.'}
        </p>
      </div>
    </aside>
  );
}
