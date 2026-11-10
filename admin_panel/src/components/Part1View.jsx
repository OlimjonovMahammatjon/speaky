import React, { useState } from 'react';
import { 
  Plus, 
  Trash2, 
  Pencil,
  MessageSquare, 
  HelpCircle, 
  CheckCircle, 
  Filter, 
  ChevronRight,
  BookOpen
} from 'lucide-react';

export default function Part1View({ 
  topics, 
  questions, 
  onAddTopic, 
  onUpdateTopic,
  onDeleteTopic, 
  onAddQuestion, 
  onUpdateQuestion,
  onDeleteQuestion 
}) {
  const [selectedTopicId, setSelectedTopicId] = useState(topics.length > 0 ? topics[0].id : '');
  const [showTopicModal, setShowTopicModal] = useState(false);
  const [showQuestionModal, setShowQuestionModal] = useState(false);
  const [editingTopicId, setEditingTopicId] = useState(null);
  const [editingQuestionId, setEditingQuestionId] = useState(null);

  // Topic Form state
  const [topicForm, setTopicForm] = useState({
    title: '',
    description: '',
    category: 'technology',
    band_target: '8.0+',
    questions_count: 4,
  });

  // Question Form state
  const [questionForm, setQuestionForm] = useState({
    topic_id: selectedTopicId,
    question_text: '',
    short_sample_answer: '',
    ideas: '',
    sample_answer_band8: '',
    high_band_vocabulary: '',
    examiner_tips: '',
  });

  const activeTopic = topics.find(t => t.id === selectedTopicId);
  const topicQuestions = questions.filter(q => q.topic_id === selectedTopicId);

  const openCreateTopicModal = () => {
    setEditingTopicId(null);
    setTopicForm({
      title: '',
      description: '',
      category: 'technology',
      band_target: '8.0+',
      questions_count: 4,
    });
    setShowTopicModal(true);
  };

  const openEditTopicModal = (topic) => {
    setEditingTopicId(topic.id);
    setTopicForm({
      title: topic.title,
      description: topic.description,
      category: topic.category,
      band_target: topic.band_target,
      questions_count: topic.questions_count,
    });
    setShowTopicModal(true);
  };

  const handleSaveTopic = (e) => {
    e.preventDefault();
    if (!topicForm.title) return;
    if (editingTopicId && onUpdateTopic) {
      onUpdateTopic(editingTopicId, topicForm);
    } else {
      onAddTopic(topicForm);
    }
    setShowTopicModal(false);
    setEditingTopicId(null);
  };

  const openCreateQuestionModal = () => {
    setEditingQuestionId(null);
    setQuestionForm({
      topic_id: selectedTopicId,
      question_text: '',
      short_sample_answer: '',
      ideas: '',
      sample_answer_band8: '',
      high_band_vocabulary: '',
      examiner_tips: '',
    });
    setShowQuestionModal(true);
  };

  const openEditQuestionModal = (q) => {
    setEditingQuestionId(q.id);
    setQuestionForm({
      topic_id: q.topic_id,
      question_text: q.question_text || '',
      short_sample_answer: q.short_sample_answer || '',
      ideas: Array.isArray(q.ideas) ? q.ideas.join('\n') : (q.ideas || ''),
      sample_answer_band8: q.sample_answer_band8 || '',
      high_band_vocabulary: Array.isArray(q.high_band_vocabulary) ? q.high_band_vocabulary.join(', ') : (q.high_band_vocabulary || ''),
      examiner_tips: Array.isArray(q.examiner_tips) ? q.examiner_tips.join(', ') : (q.examiner_tips || ''),
    });
    setShowQuestionModal(true);
  };

  const handleSaveQuestion = (e) => {
    e.preventDefault();
    if (!questionForm.question_text) return;

    const ideasList = questionForm.ideas
      ? (typeof questionForm.ideas === 'string' ? questionForm.ideas.split('\n').map(s => s.trim()).filter(Boolean) : questionForm.ideas)
      : [];
    const vocabList = questionForm.high_band_vocabulary
      ? (typeof questionForm.high_band_vocabulary === 'string' ? questionForm.high_band_vocabulary.split(',').map(s => s.trim()).filter(Boolean) : questionForm.high_band_vocabulary)
      : [];
    const tipsList = questionForm.examiner_tips
      ? (typeof questionForm.examiner_tips === 'string' ? questionForm.examiner_tips.split(',').map(s => s.trim()).filter(Boolean) : questionForm.examiner_tips)
      : [];

    const payload = {
      topic_id: questionForm.topic_id || selectedTopicId,
      question_text: questionForm.question_text,
      short_sample_answer: questionForm.short_sample_answer,
      ideas: ideasList,
      sample_answer_band8: questionForm.sample_answer_band8,
      high_band_vocabulary: vocabList,
      examiner_tips: tipsList,
      order_index: topicQuestions.length + 1,
    };

    if (editingQuestionId && onUpdateQuestion) {
      onUpdateQuestion(editingQuestionId, payload);
    } else {
      onAddQuestion(payload);
    }

    setShowQuestionModal(false);
    setEditingQuestionId(null);
  };

  return (
    <div className="part1-view">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h2>Part 1: Topics & Interview Questions</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Manage everyday conversation topics, examiner prompts, Band 8.5 answers, and lexical items.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button className="btn btn-secondary" onClick={openCreateTopicModal}>
            <Plus size={16} />
            <span>Create Topic</span>
          </button>
          <button 
            className="btn btn-primary" 
            onClick={openCreateQuestionModal}
          >
            <Plus size={16} />
            <span>Add Question</span>
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: '24px' }}>
        {/* Topics List Sidebar */}
        <div className="table-card" style={{ height: 'fit-content' }}>
          <div className="table-header">
            <h3>IELTS Topics ({topics.length})</h3>
          </div>
          <div style={{ padding: '8px' }}>
            {topics.map((t) => {
              const isSelected = t.id === selectedTopicId;
              const count = questions.filter(q => q.topic_id === t.id).length;
              return (
                <div 
                  key={t.id}
                  onClick={() => setSelectedTopicId(t.id)}
                  style={{
                    padding: '12px 14px',
                    borderRadius: 'var(--radius-md)',
                    backgroundColor: isSelected ? 'rgba(99, 102, 241, 0.15)' : 'transparent',
                    border: `1px solid ${isSelected ? 'rgba(99, 102, 241, 0.4)' : 'transparent'}`,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    marginBottom: '4px',
                    transition: 'all 0.2s ease',
                  }}
                >
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: '14px', color: isSelected ? 'var(--primary-light)' : 'var(--text-primary)' }}>
                      {t.title}
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      {t.category} • {count} questions
                    </div>
                  </div>
                  <ChevronRight size={16} color={isSelected ? 'var(--primary-light)' : 'var(--text-muted)'} />
                </div>
              );
            })}
          </div>
        </div>

        {/* Questions for Selected Topic */}
        <div>
          {activeTopic ? (
            <div>
              {/* Active Topic Banner */}
              <div style={{
                backgroundColor: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-lg)',
                padding: '20px',
                marginBottom: '20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                    <span className="badge badge-primary">{activeTopic.category}</span>
                    <span className="badge badge-emerald">Target: {activeTopic.band_target}</span>
                  </div>
                  <h3 style={{ fontSize: '20px' }}>{activeTopic.title}</h3>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>{activeTopic.description}</p>
                </div>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button 
                    className="btn btn-secondary btn-sm"
                    onClick={() => openEditTopicModal(activeTopic)}
                    title="Edit Topic"
                  >
                    <Pencil size={14} />
                    <span>Edit</span>
                  </button>
                  <button 
                    className="btn btn-danger btn-sm"
                    onClick={() => {
                      if (confirm(`Delete topic "${activeTopic.title}" and its questions?`)) {
                        onDeleteTopic(activeTopic.id);
                      }
                    }}
                    title="Delete Topic"
                  >
                    <Trash2 size={14} />
                    <span>Delete</span>
                  </button>
                </div>
              </div>

              {/* Questions List */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {topicQuestions.length === 0 ? (
                  <div className="table-card" style={{ padding: '40px', textAlign: 'center' }}>
                    <p style={{ color: 'var(--text-muted)' }}>No questions added for this topic yet.</p>
                    <button 
                      className="btn btn-primary btn-sm" 
                      style={{ marginTop: '12px' }}
                      onClick={openCreateQuestionModal}
                    >
                      <Plus size={14} />
                      <span>Add First Question</span>
                    </button>
                  </div>
                ) : (
                  topicQuestions.map((q, idx) => (
                    <div 
                      key={q.id}
                      style={{
                        backgroundColor: 'var(--bg-card)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-lg)',
                        padding: '20px',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <span style={{
                            width: '26px',
                            height: '26px',
                            borderRadius: '50%',
                            backgroundColor: 'rgba(99, 102, 241, 0.2)',
                            color: 'var(--primary-light)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '12px',
                            fontWeight: 700
                          }}>
                            {idx + 1}
                          </span>
                          <h4 style={{ fontSize: '16px' }}>{q.question_text}</h4>
                        </div>
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button 
                            className="btn btn-secondary btn-sm"
                            style={{ padding: '4px 8px' }}
                            onClick={() => openEditQuestionModal(q)}
                            title="Edit Question"
                          >
                            <Pencil size={13} />
                            <span>Edit</span>
                          </button>
                          <button 
                            className="btn btn-danger btn-sm"
                            style={{ padding: '4px 8px' }}
                            onClick={() => {
                              if (confirm('Delete this question?')) {
                                onDeleteQuestion(q.id);
                              }
                            }}
                            title="Delete Question"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>

                      {/* Brainstorming Ideas */}
                      {q.ideas && q.ideas.length > 0 && (
                        <div style={{
                          backgroundColor: 'rgba(20, 184, 166, 0.08)',
                          border: '1px solid rgba(20, 184, 166, 0.25)',
                          borderRadius: 'var(--radius-md)',
                          padding: '10px 14px',
                          marginBottom: '10px'
                        }}>
                          <div style={{ fontSize: '11px', color: '#14b8a6', fontWeight: 700, marginBottom: '6px' }}>
                            💡 BRAINSTORMING IDEAS & ANGLES:
                          </div>
                          <ul style={{ margin: 0, paddingLeft: '18px', fontSize: '12.5px', color: 'var(--text-primary)' }}>
                            {q.ideas.map((idea, idx) => (
                              <li key={idx} style={{ marginBottom: '2px' }}>{idea}</li>
                            ))}
                          </ul>
                        </div>
                      )}

                      {/* Short Sample Answer */}
                      {q.short_sample_answer && (
                        <div style={{
                          backgroundColor: 'rgba(99, 102, 241, 0.08)',
                          border: '1px solid rgba(99, 102, 241, 0.2)',
                          borderRadius: 'var(--radius-md)',
                          padding: '10px 14px',
                          marginBottom: '10px',
                          fontSize: '13px',
                          color: 'var(--text-primary)'
                        }}>
                          <div style={{ fontSize: '11px', color: 'var(--primary-light)', fontWeight: 700, marginBottom: '4px' }}>
                            📝 SHORT SAMPLE ANSWER (QISQA JAVOB):
                          </div>
                          <em style={{ fontStyle: 'italic' }}>{q.short_sample_answer}</em>
                        </div>
                      )}

                      {q.sample_answer_band8 && (
                        <div style={{
                          backgroundColor: 'var(--bg-secondary)',
                          border: '1px solid var(--border)',
                          borderRadius: 'var(--radius-md)',
                          padding: '12px',
                          marginBottom: '12px',
                          fontSize: '13px',
                          lineHeight: '1.6',
                          color: 'var(--text-primary)'
                        }}>
                          <div style={{ fontSize: '11px', color: 'var(--secondary)', fontWeight: 700, marginBottom: '4px' }}>
                            BAND 8.5 SAMPLE ANSWER:
                          </div>
                          {q.sample_answer_band8}
                        </div>
                      )}

                      {/* Vocabulary & Tips Chips */}
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                        {q.high_band_vocabulary?.map((v, i) => (
                          <span key={i} className="badge badge-primary">
                            💎 {v}
                          </span>
                        ))}
                        {q.examiner_tips?.map((t, i) => (
                          <span key={i} className="badge badge-amber">
                            💡 {t}
                          </span>
                        ))}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          ) : (
            <div className="table-card" style={{ padding: '40px', textAlign: 'center' }}>
              <p>Please select a topic or create a new one.</p>
            </div>
          )}
        </div>
      </div>

      {/* CREATE TOPIC MODAL */}
      {showTopicModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>{editingTopicId ? 'Edit IELTS Topic' : 'Create New IELTS Part 1 Topic'}</h3>
              <button className="btn btn-secondary btn-sm" onClick={() => setShowTopicModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSaveTopic}>
              <div className="modal-body">
                <div className="form-group">
                  <label>Topic Title</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Artificial Intelligence & Gadgets" 
                    value={topicForm.title}
                    onChange={(e) => setTopicForm({ ...topicForm, title: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Description / Context</label>
                  <textarea 
                    className="form-control" 
                    placeholder="Brief description of what candidates discuss..."
                    value={topicForm.description}
                    onChange={(e) => setTopicForm({ ...topicForm, description: e.target.value })}
                  />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                  <div className="form-group">
                    <label>Category</label>
                    <select 
                      className="form-control"
                      value={topicForm.category}
                      onChange={(e) => setTopicForm({ ...topicForm, category: e.target.value })}
                    >
                      <option value="technology">Technology</option>
                      <option value="workAndStudy">Work & Study</option>
                      <option value="travelAndPlaces">Travel & Places</option>
                      <option value="environment">Environment</option>
                      <option value="artAndCulture">Art & Culture</option>
                      <option value="societyAndPeople">Society & People</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Target Band Score</label>
                    <select 
                      className="form-control"
                      value={topicForm.band_target}
                      onChange={(e) => setTopicForm({ ...topicForm, band_target: e.target.value })}
                    >
                      <option value="7.0+">Band 7.0+</option>
                      <option value="7.5+">Band 7.5+</option>
                      <option value="8.0+">Band 8.0+</option>
                      <option value="8.5+">Band 8.5+</option>
                    </select>
                  </div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowTopicModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">{editingTopicId ? 'Save Changes' : 'Create Topic'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* CREATE QUESTION MODAL */}
      {showQuestionModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>{editingQuestionId ? 'Edit Interview Question' : 'Add Interview Question'}</h3>
              <button className="btn btn-secondary btn-sm" onClick={() => setShowQuestionModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSaveQuestion}>
              <div className="modal-body">
                <div className="form-group">
                  <label>Assign to Topic</label>
                  <select 
                    className="form-control"
                    value={questionForm.topic_id || selectedTopicId}
                    onChange={(e) => setQuestionForm({ ...questionForm, topic_id: e.target.value })}
                  >
                    {topics.map(t => (
                      <option key={t.id} value={t.id}>{t.title}</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Question Text</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Do you prefer reading physical books or e-books?" 
                    value={questionForm.question_text}
                    onChange={(e) => setQuestionForm({ ...questionForm, question_text: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Short Sample Answer (Ozgina namunaviy javob - 1-2 gap)</label>
                  <textarea 
                    className="form-control" 
                    placeholder="e.g. I prefer physical books because the tactile feeling helps me focus and retain information better."
                    rows={2}
                    value={questionForm.short_sample_answer}
                    onChange={(e) => setQuestionForm({ ...questionForm, short_sample_answer: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Brainstorming Ideas & Angles (Fikrlar / Mavzular - bir qatorda bittadan)</label>
                  <textarea 
                    className="form-control" 
                    placeholder="Physical books: Tactile feeling, less eye strain&#10;E-books: Portability, adjustable font, night mode"
                    rows={3}
                    value={questionForm.ideas}
                    onChange={(e) => setQuestionForm({ ...questionForm, ideas: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Band 8.5 Model Answer (To'liq javob)</label>
                  <textarea 
                    className="form-control" 
                    placeholder="Write a high-scoring sample answer with fluent discourse..."
                    rows={4}
                    value={questionForm.sample_answer_band8}
                    onChange={(e) => setQuestionForm({ ...questionForm, sample_answer_band8: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>High-Band Vocabulary (comma separated)</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Tactile experience, indispensable tool, cognitive retention" 
                    value={questionForm.high_band_vocabulary}
                    onChange={(e) => setQuestionForm({ ...questionForm, high_band_vocabulary: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Examiner Tips (comma separated)</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    placeholder="e.g. Compare both options using contrastive linkers, Avoid flat monotones" 
                    value={questionForm.examiner_tips}
                    onChange={(e) => setQuestionForm({ ...questionForm, examiner_tips: e.target.value })}
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowQuestionModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">{editingQuestionId ? 'Save Changes' : 'Save Question'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
