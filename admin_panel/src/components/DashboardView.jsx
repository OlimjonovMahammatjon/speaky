import React from 'react';
import { 
  MessageSquare, 
  FileText, 
  Sparkles, 
  HelpCircle, 
  Plus, 
  ArrowUpRight, 
  CheckCircle2, 
  Flame,
  Layers
} from 'lucide-react';

export default function DashboardView({ 
  topics, 
  questions, 
  cueCards, 
  vocabulary, 
  setActiveTab, 
  openAddModal 
}) {
  return (
    <div className="dashboard-view">
      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-info">
            <p>Part 1 Topics</p>
            <h3>{topics.length}</h3>
          </div>
          <div className="stat-icon" style={{ background: 'var(--gradient-cyan)', color: 'white' }}>
            <MessageSquare size={24} />
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Interview Questions</p>
            <h3>{questions.length}</h3>
          </div>
          <div className="stat-icon" style={{ background: 'var(--gradient-primary)', color: 'white' }}>
            <HelpCircle size={24} />
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Part 2 Cue Cards</p>
            <h3>{cueCards.length}</h3>
          </div>
          <div className="stat-icon" style={{ background: 'var(--gradient-sunset)', color: 'white' }}>
            <FileText size={24} />
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Band 8+ Lexis Items</p>
            <h3>{vocabulary.length}</h3>
          </div>
          <div className="stat-icon" style={{ background: 'var(--gradient-gold)', color: 'white' }}>
            <Sparkles size={24} />
          </div>
        </div>
      </div>

      {/* Quick Action Banner */}
      <div style={{
        background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.2) 0%, rgba(6, 182, 212, 0.1) 100%)',
        border: '1px solid rgba(99, 102, 241, 0.3)',
        borderRadius: 'var(--radius-lg)',
        padding: '24px',
        marginBottom: '32px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h3 style={{ fontSize: '20px', marginBottom: '6px' }}>Upload Content to Mobile App</h3>
          <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
            Quickly add high-frequency IELTS exam questions, cue cards, and idiomatic vocabulary.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button className="btn btn-secondary" onClick={() => openAddModal('topic')}>
            <Plus size={16} />
            <span>New Topic</span>
          </button>
          <button className="btn btn-secondary" onClick={() => openAddModal('cue_card')}>
            <Plus size={16} />
            <span>New Cue Card</span>
          </button>
          <button className="btn btn-primary" onClick={() => openAddModal('question')}>
            <Plus size={16} />
            <span>New Question</span>
          </button>
        </div>
      </div>

      {/* Two Column Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(450px, 1fr))', gap: '24px' }}>
        {/* Recent Part 1 Topics */}
        <div className="table-card">
          <div className="table-header">
            <h3>Recent Part 1 Topics</h3>
            <button className="btn btn-secondary btn-sm" onClick={() => setActiveTab('part1')}>
              <span>View All</span>
              <ArrowUpRight size={14} />
            </button>
          </div>
          <div className="table-responsive">
            <table>
              <thead>
                <tr>
                  <th>Topic</th>
                  <th>Category</th>
                  <th>Target</th>
                  <th>Questions</th>
                </tr>
              </thead>
              <tbody>
                {topics.slice(0, 4).map((t) => (
                  <tr key={t.id}>
                    <td>
                      <strong>{t.title}</strong>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{t.id}</div>
                    </td>
                    <td>
                      <span className="badge badge-primary">{t.category}</span>
                    </td>
                    <td>
                      <span className="badge badge-emerald">{t.band_target || '7.5+'}</span>
                    </td>
                    <td>{t.questions_count || 4} Qs</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Recent Cue Cards */}
        <div className="table-card">
          <div className="table-header">
            <h3>Part 2 Candidate Task Cards</h3>
            <button className="btn btn-secondary btn-sm" onClick={() => setActiveTab('cue_cards')}>
              <span>View All</span>
              <ArrowUpRight size={14} />
            </button>
          </div>
          <div className="table-responsive">
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Topic Area</th>
                  <th>Collocations</th>
                </tr>
              </thead>
              <tbody>
                {cueCards.slice(0, 4).map((c) => (
                  <tr key={c.id}>
                    <td>
                      <strong>{c.title}</strong>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: '240px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {c.cue_prompt}
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-cyan">{c.topic_area}</span>
                    </td>
                    <td>
                      <span className="badge badge-amber">{c.key_collocations?.length || 0} items</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
