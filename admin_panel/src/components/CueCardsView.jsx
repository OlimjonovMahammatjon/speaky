import React, { useState } from 'react';
import { Plus, Trash2, FileText, CheckCircle2, Bookmark } from 'lucide-react';

export default function CueCardsView({ cueCards, onAddCueCard, onDeleteCueCard }) {
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({
    title: '',
    topic_area: '',
    cue_prompt: '',
    bullet_1: '',
    bullet_2: '',
    bullet_3: '',
    bullet_4: '',
    story_ideas: '',
    short_sample_answer: '',
    band9_model_answer: '',
    key_collocations: '',
    part3_follow_ups: '',
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.title || !form.cue_prompt) return;

    const bullets = [form.bullet_1, form.bullet_2, form.bullet_3, form.bullet_4].filter(Boolean);
    const storyIdeasList = form.story_ideas
      ? form.story_ideas.split('\n').map(s => s.trim()).filter(Boolean)
      : [];
    const collocations = form.key_collocations
      ? form.key_collocations.split(',').map(s => s.trim()).filter(Boolean)
      : [];
    const followUps = form.part3_follow_ups
      ? form.part3_follow_ups.split('\n').map(s => s.trim()).filter(Boolean)
      : [];

    onAddCueCard({
      title: form.title,
      topic_area: form.topic_area || 'Life Experience',
      cue_prompt: form.cue_prompt,
      bullet_points: bullets,
      story_ideas: storyIdeasList,
      short_sample_answer: form.short_sample_answer,
      band9_model_answer: form.band9_model_answer,
      key_collocations: collocations,
      part3_follow_ups: followUps,
    });

    setShowModal(false);
    setForm({
      title: '',
      topic_area: '',
      cue_prompt: '',
      bullet_1: '',
      bullet_2: '',
      bullet_3: '',
      bullet_4: '',
      story_ideas: '',
      short_sample_answer: '',
      band9_model_answer: '',
      key_collocations: '',
      part3_follow_ups: '',
    });
  };

  return (
    <div className="cue-cards-view">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h2>Part 2: Candidate Task Cards (Cue Cards)</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Configure 1-minute prep tasks with 4 bullet prompts, Band 9 transcripts, and Part 3 follow-up queries.
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          <Plus size={16} />
          <span>New Cue Card</span>
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(420px, 1fr))', gap: '24px' }}>
        {cueCards.map((card) => (
          <div 
            key={card.id}
            style={{
              backgroundColor: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-lg)',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: 'var(--shadow-card)'
            }}
          >
            {/* Header */}
            <div style={{
              padding: '16px 20px',
              backgroundColor: 'rgba(255, 255, 255, 0.02)',
              borderBottom: '1px solid var(--border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between'
            }}>
              <div>
                <span className="badge badge-primary">{card.topic_area}</span>
                <h3 style={{ fontSize: '17px', marginTop: '6px' }}>{card.title}</h3>
              </div>
              <button 
                className="btn btn-danger btn-sm"
                style={{ padding: '6px' }}
                onClick={() => {
                  if (confirm(`Delete Cue Card "${card.title}"?`)) {
                    onDeleteCueCard(card.id);
                  }
                }}
              >
                <Trash2 size={14} />
              </button>
            </div>

            {/* Cue Card Body */}
            <div style={{ padding: '20px', flex: 1, display: 'flex', flexDirection: 'column' }}>
              <p style={{ fontWeight: 600, fontSize: '14px', marginBottom: '12px', lineHeight: '1.4' }}>
                {card.cue_prompt}
              </p>

              <div style={{
                backgroundColor: 'var(--bg-secondary)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)',
                padding: '12px 16px',
                marginBottom: '16px'
              }}>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: 700, marginBottom: '6px' }}>
                  YOU SHOULD SAY:
                </div>
                {card.bullet_points?.map((bullet, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', marginBottom: '4px' }}>
                    <span style={{ width: '4px', height: '4px', borderRadius: '50%', backgroundColor: 'var(--secondary)' }} />
                    <span>{bullet}</span>
                  </div>
                ))}
              </div>

              {/* Story Ideas & Angles */}
              {card.story_ideas && card.story_ideas.length > 0 && (
                <div style={{
                  backgroundColor: 'rgba(168, 85, 247, 0.08)',
                  border: '1px solid rgba(168, 85, 247, 0.25)',
                  borderRadius: 'var(--radius-md)',
                  padding: '10px 14px',
                  marginBottom: '12px'
                }}>
                  <div style={{ fontSize: '11px', color: '#c084fc', fontWeight: 700, marginBottom: '6px' }}>
                    💡 STORY ANGLES / BRAINSTORMING IDEAS:
                  </div>
                  <ul style={{ margin: 0, paddingLeft: '18px', fontSize: '12.5px', color: 'var(--text-primary)' }}>
                    {card.story_ideas.map((idea, i) => (
                      <li key={i} style={{ marginBottom: '2px' }}>{idea}</li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Short Sample Answer */}
              {card.short_sample_answer && (
                <div style={{
                  backgroundColor: 'rgba(99, 102, 241, 0.08)',
                  border: '1px solid rgba(99, 102, 241, 0.2)',
                  borderRadius: 'var(--radius-md)',
                  padding: '10px 14px',
                  marginBottom: '12px',
                  fontSize: '13px',
                  color: 'var(--text-primary)'
                }}>
                  <div style={{ fontSize: '11px', color: 'var(--primary-light)', fontWeight: 700, marginBottom: '4px' }}>
                    📝 SHORT SAMPLE ANSWER (QISQA JAVOB):
                  </div>
                  <em style={{ fontStyle: 'italic' }}>{card.short_sample_answer}</em>
                </div>
              )}

              {card.key_collocations && card.key_collocations.length > 0 && (
                <div style={{ marginBottom: '14px' }}>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: 700, marginBottom: '6px' }}>
                    KEY COLLOCATIONS:
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                    {card.key_collocations.map((c, i) => (
                      <span key={i} className="badge badge-amber" style={{ fontSize: '10px' }}>
                        {c}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {card.band9_model_answer && (
                <details style={{ marginTop: 'auto', paddingTop: '10px', borderTop: '1px solid var(--border)' }}>
                  <summary style={{ cursor: 'pointer', fontSize: '12px', color: 'var(--secondary)', fontWeight: 600 }}>
                    Preview Band 9.0 Model Answer
                  </summary>
                  <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '8px', lineHeight: '1.6', maxHeight: '140px', overflowY: 'auto' }}>
                    {card.band9_model_answer}
                  </p>
                </details>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* CREATE CUE CARD MODAL */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '720px' }}>
            <div className="modal-header">
              <h3>Create IELTS Part 2 Task Card</h3>
              <button className="btn btn-secondary btn-sm" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '14px' }}>
                  <div className="form-group">
                    <label>Cue Card Title</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="e.g. A Memorable Journey You Took" 
                      value={form.title}
                      onChange={(e) => setForm({ ...form, title: e.target.value })}
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label>Topic Area</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="e.g. Travel & Places" 
                      value={form.topic_area}
                      onChange={(e) => setForm({ ...form, topic_area: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Cue Prompt (Describe...)</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="Describe a memorable journey by train or car that you took recently." 
                    value={form.cue_prompt}
                    onChange={(e) => setForm({ ...form, cue_prompt: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>You Should Say (4 Bullet Points):</label>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Bullet 1: Where you went and who with"
                      value={form.bullet_1}
                      onChange={(e) => setForm({ ...form, bullet_1: e.target.value })}
                    />
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Bullet 2: How you traveled"
                      value={form.bullet_2}
                      onChange={(e) => setForm({ ...form, bullet_2: e.target.value })}
                    />
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Bullet 3: What you did during the trip"
                      value={form.bullet_3}
                      onChange={(e) => setForm({ ...form, bullet_3: e.target.value })}
                    />
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="Bullet 4: And explain why it was memorable"
                      value={form.bullet_4}
                      onChange={(e) => setForm({ ...form, bullet_4: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Story Ideas / Angles (Fikrlar / Mavzular - bir qatorda bittadan)</label>
                  <textarea 
                    className="form-control" 
                    rows={3}
                    placeholder="Option A: A solo road trip along the mountains&#10;Option B: An overnight sleeper train to another city&#10;Option C: A spontaneous bike expedition with childhood friends"
                    value={form.story_ideas}
                    onChange={(e) => setForm({ ...form, story_ideas: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Short Sample Answer (Qisqa namunaviy javob - 1-2 gap)</label>
                  <textarea 
                    className="form-control" 
                    rows={2}
                    placeholder="e.g. A memorable journey I took was a scenic road trip across the northern valleys, which offered breathtaking views and unforgettable experiences."
                    value={form.short_sample_answer}
                    onChange={(e) => setForm({ ...form, short_sample_answer: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Band 9.0 Model Answer (To'liq javob)</label>
                  <textarea 
                    className="form-control" 
                    rows={4}
                    placeholder="Enter an exemplary IELTS band 9 response showcasing fluency, rich collocations, and varied syntax..."
                    value={form.band9_model_answer}
                    onChange={(e) => setForm({ ...form, band9_model_answer: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Key Collocations (comma separated)</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Scenic vista, off the beaten track, picturesque landscape"
                    value={form.key_collocations}
                    onChange={(e) => setForm({ ...form, key_collocations: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Part 3 Follow-Up Questions (one per line)</label>
                  <textarea 
                    className="form-control" 
                    rows={3}
                    placeholder="Why do people prefer traveling solo nowadays?&#10;How does tourism impact local cultures?"
                    value={form.part3_follow_ups}
                    onChange={(e) => setForm({ ...form, part3_follow_ups: e.target.value })}
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Save Cue Card</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
