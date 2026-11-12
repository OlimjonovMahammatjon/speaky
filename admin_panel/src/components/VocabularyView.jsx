import React, { useState, useEffect, useCallback } from 'react';
import { Plus, Trash2, Pencil } from 'lucide-react';

export default function VocabularyView({
  vocabulary,
  onAddVocabulary,
  onUpdateVocabulary,
  onDeleteVocabulary,
  quickAction,
  onQuickActionHandled,
  showToast,
}) {
  const [filterType, setFilterType] = useState('All');
  const [showModal, setShowModal] = useState(false);
  const [editingVocabId, setEditingVocabId] = useState(null);
  const [form, setForm] = useState({
    phrase: '',
    phonetics: '',
    type: 'collocation',
    meaning: '',
    band_target: 'Band 8.5+',
    example_ielts_context: '',
    topic_tag: 'General',
  });

  const filtered = filterType === 'All' 
    ? vocabulary 
    : vocabulary.filter(v => v.type?.toLowerCase() === filterType.toLowerCase());

  const openCreateModal = useCallback(() => {
    setEditingVocabId(null);
    setForm({
      phrase: '',
      phonetics: '',
      type: 'collocation',
      meaning: '',
      band_target: 'Band 8.5+',
      example_ielts_context: '',
      topic_tag: 'General',
    });
    setShowModal(true);
  }, []);

  useEffect(() => {
    if (quickAction?.type === 'vocabulary') {
      openCreateModal();
      onQuickActionHandled?.();
    }
  }, [quickAction, openCreateModal, onQuickActionHandled]);

  const openEditModal = (item) => {
    setEditingVocabId(item.id);
    setForm({
      phrase: item.phrase || '',
      phonetics: item.phonetics || '',
      type: item.type || 'collocation',
      meaning: item.meaning || '',
      band_target: item.band_target || 'Band 8.5+',
      example_ielts_context: item.example_ielts_context || '',
      topic_tag: item.topic_tag || 'General',
    });
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const phrase = (form.phrase || '').trim();
    const meaning = (form.meaning || '').trim();
    if (!phrase || !meaning) {
      showToast?.('Phrase and meaning are required.', 'error');
      return;
    }

    const payload = {
      phrase,
      phonetics: (form.phonetics || '').trim(),
      type: form.type,
      meaning,
      band_target: form.band_target,
      example_ielts_context: (form.example_ielts_context || '').trim(),
      topic_tag: (form.topic_tag || '').trim() || 'General',
    };

    if (editingVocabId && onUpdateVocabulary) {
      const updated = await onUpdateVocabulary(editingVocabId, payload);
      if (!updated) return;
    } else if (onAddVocabulary) {
      const created = await onAddVocabulary(payload);
      if (!created) return;
    }

    setShowModal(false);
    setEditingVocabId(null);
  };

  const getTypeBadgeClass = (type) => {
    switch (type?.toLowerCase()) {
      case 'collocation': return 'badge-primary';
      case 'idiom': return 'badge-cyan';
      case 'discoursemarker': return 'badge-cyan';
      default: return 'badge-primary';
    }
  };

  return (
    <div className="vocabulary-view">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h2>Band 8+ Lexical Resource & Idioms</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Elevate candidates' Lexical Resource scores with high-impact collocations, phrasal verbs, and cohesive discourse markers.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openCreateModal}>
          <Plus size={16} />
          <span>Add Lexical Item</span>
        </button>
      </div>

      {/* Filter Tabs */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
        {['All', 'Collocation', 'Idiom', 'DiscourseMarker', 'AcademicLexis'].map((type) => (
          <button
            key={type}
            className={`btn btn-sm ${filterType === type ? 'btn-primary' : 'btn-secondary'}`}
            onClick={() => setFilterType(type)}
          >
            {type === 'DiscourseMarker' ? 'Discourse Markers' : type === 'AcademicLexis' ? 'Academic Lexis' : type}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="table-card">
        <div className="table-responsive">
          <table>
            <thead>
              <tr>
                <th>Phrase / Word</th>
                <th>Type</th>
                <th>Band Target</th>
                <th>Meaning</th>
                <th>IELTS Context Example</th>
                <th>Topic Tag</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((item) => (
                <tr key={item.id}>
                  <td>
                    <strong style={{ fontSize: '15px' }}>{item.phrase}</strong>
                    {item.phonetics && (
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                        {item.phonetics}
                      </div>
                    )}
                  </td>
                  <td>
                    <span className={`badge ${getTypeBadgeClass(item.type)}`}>
                      {item.type}
                    </span>
                  </td>
                  <td>
                    <span className="badge badge-emerald">{item.band_target || 'Band 8.0+'}</span>
                  </td>
                  <td style={{ maxWidth: '220px', fontSize: '13px' }}>
                    {item.meaning}
                  </td>
                  <td style={{ maxWidth: '280px', fontSize: '13px', fontStyle: 'italic', color: 'var(--text-secondary)' }}>
                    "{item.example_ielts_context}"
                  </td>
                  <td>
                    <span className="badge" style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)' }}>
                      {item.topic_tag || 'General'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '6px' }}>
                      <button 
                        className="btn btn-secondary btn-sm"
                        style={{ padding: '6px' }}
                        onClick={() => openEditModal(item)}
                        title="Edit Item"
                      >
                        <Pencil size={13} />
                      </button>
                      <button 
                        className="btn btn-danger btn-sm"
                        style={{ padding: '6px' }}
                        onClick={() => {
                          if (confirm(`Delete "${item.phrase}"?`)) {
                            onDeleteVocabulary(item.id);
                          }
                        }}
                        title="Delete Item"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ADD VOCABULARY MODAL */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>{editingVocabId ? 'Edit Band 8+ Lexical Item' : 'Add Band 8+ Vocabulary Item'}</h3>
              <button className="btn btn-secondary btn-sm" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '14px' }}>
                  <div className="form-group">
                    <label>Phrase or Word</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="e.g. In the blink of an eye" 
                      value={form.phrase}
                      onChange={(e) => setForm({ ...form, phrase: e.target.value })}
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label>Phonetics</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="/ɪn ðə blɪŋk əv ən aɪ/" 
                      value={form.phonetics}
                      onChange={(e) => setForm({ ...form, phonetics: e.target.value })}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px' }}>
                  <div className="form-group">
                    <label>Classification Type</label>
                    <select 
                      className="form-control"
                      value={form.type}
                      onChange={(e) => setForm({ ...form, type: e.target.value })}
                    >
                      <option value="collocation">Collocation</option>
                      <option value="idiom">Idiom</option>
                      <option value="discourseMarker">Discourse Marker</option>
                      <option value="academicLexis">Academic Lexis</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Target Band</label>
                    <select 
                      className="form-control"
                      value={form.band_target}
                      onChange={(e) => setForm({ ...form, band_target: e.target.value })}
                    >
                      <option value="Band 7.5+">Band 7.5+</option>
                      <option value="Band 8.0+">Band 8.0+</option>
                      <option value="Band 8.5+">Band 8.5+</option>
                      <option value="Band 9.0">Band 9.0</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Topic Tag</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      placeholder="e.g. Technology" 
                      value={form.topic_tag}
                      onChange={(e) => setForm({ ...form, topic_tag: e.target.value })}
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Meaning & Nuance</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Extremely quickly, in an instant" 
                    value={form.meaning}
                    onChange={(e) => setForm({ ...form, meaning: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>IELTS Exam Sample Sentence</label>
                  <textarea 
                    className="form-control" 
                    rows={3}
                    placeholder="e.g. Technological innovations have evolved in the blink of an eye over the past decade."
                    value={form.example_ielts_context}
                    onChange={(e) => setForm({ ...form, example_ielts_context: e.target.value })}
                    required
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">{editingVocabId ? 'Save Changes' : 'Save Lexis'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
