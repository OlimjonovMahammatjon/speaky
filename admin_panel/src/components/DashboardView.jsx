import React from 'react';
import { Plus, ArrowUpRight } from 'lucide-react';

export default function DashboardView({
  topics,
  questions,
  cueCards,
  vocabulary,
  setActiveTab,
  openAddModal,
}) {
  const getQuestionCount = (topicId, fallback) => {
    const live = questions.filter((q) => q.topic_id === topicId).length;
    return live > 0 ? live : (fallback || 0);
  };

  return (
    <div className="dashboard-view">
      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-info">
            <p>Part 1 Topics</p>
            <h3>{topics.length}</h3>
          </div>
          <span className="stat-pill">PART 1</span>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Interview Questions</p>
            <h3>{questions.length}</h3>
          </div>
          <span className="stat-pill">QUESTIONS</span>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Part 2 Cue Cards</p>
            <h3>{cueCards.length}</h3>
          </div>
          <span className="stat-pill">PART 2</span>
        </div>

        <div className="stat-card">
          <div className="stat-info">
            <p>Band 8+ Lexis Items</p>
            <h3>{vocabulary.length}</h3>
          </div>
          <span className="stat-pill">LEXIS</span>
        </div>
      </div>

      {/* Quick Action Banner */}
      <div style={{
        backgroundColor: 'var(--primary-soft)',
        border: '1px solid var(--primary-border)',
        borderRadius: 'var(--radius-lg)',
        padding: '22px 24px',
        marginBottom: '24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px',
      }}>
        <div>
          <h3 style={{ fontSize: '18px', marginBottom: '4px', color: 'var(--text-primary)' }}>
            Upload Content to Mobile App
          </h3>
          <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
            Quickly add high-frequency IELTS exam questions, cue cards, and idiomatic vocabulary.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button className="btn btn-secondary" onClick={() => openAddModal('topic')}>
            <Plus size={15} />
            <span>New Topic</span>
          </button>
          <button className="btn btn-secondary" onClick={() => openAddModal('cue_card')}>
            <Plus size={15} />
            <span>New Cue Card</span>
          </button>
          <button className="btn btn-primary" onClick={() => openAddModal('question')}>
            <Plus size={15} />
            <span>New Question</span>
          </button>
        </div>
      </div>

      {/* Two Column Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(440px, 1fr))', gap: '20px' }}>
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
                      <div style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>{t.id}</div>
                    </td>
                    <td>
                      <span className="badge badge-primary">{t.category}</span>
                    </td>
                    <td>
                      <span className="badge badge-emerald">{t.band_target || '7.5+'}</span>
                    </td>
                    <td>{getQuestionCount(t.id, t.questions_count)} Qs</td>
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
                      <span className="badge badge-primary">{c.key_collocations?.length || 0} items</span>
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
