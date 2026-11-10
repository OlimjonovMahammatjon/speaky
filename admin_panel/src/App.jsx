import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import DashboardView from './components/DashboardView';
import Part1View from './components/Part1View';
import CueCardsView from './components/CueCardsView';
import VocabularyView from './components/VocabularyView';
import SettingsModal from './components/SettingsModal';
import AuthModal from './components/AuthModal';
import { api, getSavedCredentials, onAuthChange, signOut, getCurrentUser } from './supabaseClient';
import { Database, Plus, RefreshCw, CheckCircle, AlertCircle, LogIn, LogOut } from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isSupabaseConnected, setIsSupabaseConnected] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showAuth, setShowAuth] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Data states
  const [topics, setTopics] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [cueCards, setCueCards] = useState([]);
  const [vocabulary, setVocabulary] = useState([]);

  // Toast state
  const [toast, setToast] = useState(null);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const loadAllData = async () => {
    setLoading(true);
    try {
      const [tData, qData, cData, vData] = await Promise.all([
        api.getTopics(),
        api.getQuestions(),
        api.getCueCards(),
        api.getVocabulary(),
      ]);
      setTopics(tData || []);
      setQuestions(qData || []);
      setCueCards(cData || []);
      setVocabulary(vData || []);
    } catch (e) {
      console.error('Error fetching data:', e);
      showToast('Error loading data: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const checkConnection = async () => {
    const creds = getSavedCredentials();
    if (creds.url && creds.key) {
      const res = await api.testConnection();
      setIsSupabaseConnected(res.success);
    } else {
      setIsSupabaseConnected(false);
    }
  };

  useEffect(() => {
    checkConnection();
    loadAllData();
    // Check if user is already signed in
    getCurrentUser().then((user) => {
      if (user) setCurrentUser(user);
    });
    // Listen for auth changes
    const unsub = onAuthChange((user) => {
      setCurrentUser(user);
    });
    return () => { if (typeof unsub === 'function') unsub(); };
  }, []);

  // Auth guard: allow local demo edits if offline, but if live Supabase is connected require login
  const canEdit = !isSupabaseConnected || currentUser !== null;

  // CRUD Handlers
  const handleAddTopic = async (topic) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const created = await api.addTopic(topic);
      setTopics(prev => [created, ...prev]);
      showToast(`Topic "${created.title}" successfully added!`);
    } catch (e) {
      showToast('Failed to add topic: ' + e.message, 'error');
    }
  };

  const handleUpdateTopic = async (id, updated) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const res = await api.updateTopic(id, updated);
      setTopics(prev => prev.map(t => t.id === id ? { ...t, ...res } : t));
      showToast(`Topic updated successfully!`);
    } catch (e) {
      showToast('Failed to update topic: ' + e.message, 'error');
    }
  };

  const handleDeleteTopic = async (id) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      await api.deleteTopic(id);
      setTopics(prev => prev.filter(t => t.id !== id));
      setQuestions(prev => prev.filter(q => q.topic_id !== id));
      showToast('Topic deleted');
    } catch (e) {
      showToast('Failed to delete topic: ' + e.message, 'error');
    }
  };

  const handleAddQuestion = async (question) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const created = await api.addQuestion(question);
      setQuestions(prev => [...prev, created]);
      showToast('Question successfully added!');
    } catch (e) {
      showToast('Failed to add question: ' + e.message, 'error');
    }
  };

  const handleUpdateQuestion = async (id, updated) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const res = await api.updateQuestion(id, updated);
      setQuestions(prev => prev.map(q => q.id === id ? { ...q, ...res } : q));
      showToast('Question updated successfully!');
    } catch (e) {
      showToast('Failed to update question: ' + e.message, 'error');
    }
  };

  const handleDeleteQuestion = async (id) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      await api.deleteQuestion(id);
      setQuestions(prev => prev.filter(q => q.id !== id));
      showToast('Question deleted');
    } catch (e) {
      showToast('Failed to delete question: ' + e.message, 'error');
    }
  };

  const handleAddCueCard = async (card) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const created = await api.addCueCard(card);
      setCueCards(prev => [created, ...prev]);
      showToast(`Cue Card "${created.title}" successfully added!`);
    } catch (e) {
      showToast('Failed to add cue card: ' + e.message, 'error');
    }
  };

  const handleUpdateCueCard = async (id, updated) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const res = await api.updateCueCard(id, updated);
      setCueCards(prev => prev.map(c => c.id === id ? { ...c, ...res } : c));
      showToast('Cue card updated successfully!');
    } catch (e) {
      showToast('Failed to update cue card: ' + e.message, 'error');
    }
  };

  const handleDeleteCueCard = async (id) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      await api.deleteCueCard(id);
      setCueCards(prev => prev.filter(c => c.id !== id));
      showToast('Cue card deleted');
    } catch (e) {
      showToast('Failed to delete cue card: ' + e.message, 'error');
    }
  };

  const handleAddVocabulary = async (vocab) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const created = await api.addVocabulary(vocab);
      setVocabulary(prev => [created, ...prev]);
      showToast(`Vocabulary item "${created.phrase}" added!`);
    } catch (e) {
      showToast('Failed to add vocabulary: ' + e.message, 'error');
    }
  };

  const handleUpdateVocabulary = async (id, updated) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      const res = await api.updateVocabulary(id, updated);
      setVocabulary(prev => prev.map(v => v.id === id ? { ...v, ...res } : v));
      showToast('Vocabulary updated successfully!');
    } catch (e) {
      showToast('Failed to update vocabulary: ' + e.message, 'error');
    }
  };

  const handleDeleteVocabulary = async (id) => {
    if (!canEdit) { setShowAuth(true); return; }
    try {
      await api.deleteVocabulary(id);
      setVocabulary(prev => prev.filter(v => v.id !== id));
      showToast('Vocabulary item deleted');
    } catch (e) {
      showToast('Failed to delete vocabulary: ' + e.message, 'error');
    }
  };

  const openAddModalFromDashboard = (type) => {
    if (type === 'topic') setActiveTab('part1');
    else if (type === 'question') setActiveTab('part1');
    else if (type === 'cue_card') setActiveTab('cue_cards');
    else if (type === 'vocabulary') setActiveTab('vocabulary');
  };

  const getPageTitle = () => {
    switch (activeTab) {
      case 'dashboard': return { title: 'Exam Content Overview', subtitle: 'Live synchronization between Admin Studio and Flutter Mobile App' };
      case 'part1': return { title: 'Part 1: Interview Management', subtitle: 'Manage conversational prompts, Band 8.5 answers, and examiner tips' };
      case 'cue_cards': return { title: 'Part 2: Candidate Task Cards', subtitle: 'Timed cue card topics with 1-min prep and Band 9 transcripts' };
      case 'vocabulary': return { title: 'Band 8+ Lexical Bank', subtitle: 'High-scoring idioms, academic lexis, and discourse markers' };
      default: return { title: 'Admin Studio', subtitle: 'IELTS Speaky Dashboard' };
    }
  };

  const pageInfo = getPageTitle();

  return (
    <div className="app-container">
      {/* Left Sidebar */}
      <Sidebar 
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        counts={{
          topics: topics.length,
          cueCards: cueCards.length,
          vocabulary: vocabulary.length,
        }}
        isSupabaseConnected={isSupabaseConnected}
        openSettings={() => setShowSettings(true)}
      />

      {/* Main Wrapper */}
      <div className="main-wrapper">
        {/* Top Header */}
        <header className="top-header">
          <div className="header-title">
            <h1>{pageInfo.title}</h1>
            <p>{pageInfo.subtitle}</p>
          </div>
          <div className="header-actions">
            <button 
              className="btn btn-secondary btn-sm" 
              onClick={loadAllData} 
              title="Refresh Data"
            >
              <RefreshCw size={14} className={loading ? 'spin' : ''} />
              <span>Refresh</span>
            </button>
            <button 
              className="btn btn-secondary btn-sm" 
              onClick={() => setShowSettings(true)}
            >
              <Database size={14} color={isSupabaseConnected ? 'var(--emerald)' : 'var(--amber)'} />
              <span>{isSupabaseConnected ? 'Supabase Connected' : 'Connect Supabase'}</span>
            </button>
            {currentUser ? (
              <button
                className="btn btn-secondary btn-sm"
                onClick={async () => {
                  await signOut();
                  setCurrentUser(null);
                  showToast('Signed out successfully');
                }}
                title="Sign out"
              >
                <LogOut size={14} />
                <span>{currentUser.email}</span>
              </button>
            ) : (
              <button
                className="btn btn-primary btn-sm"
                onClick={() => setShowAuth(true)}
                title="Sign in to manage content"
              >
                <LogIn size={14} />
                <span>Sign In</span>
              </button>
            )}
          </div>
        </header>

        {/* Content Body */}
        <main className="content-body">
          {activeTab === 'dashboard' && (
            <DashboardView 
              topics={topics}
              questions={questions}
              cueCards={cueCards}
              vocabulary={vocabulary}
              setActiveTab={setActiveTab}
              openAddModal={openAddModalFromDashboard}
            />
          )}

          {activeTab === 'part1' && (
            <Part1View 
              topics={topics}
              questions={questions}
              onAddTopic={handleAddTopic}
              onUpdateTopic={handleUpdateTopic}
              onDeleteTopic={handleDeleteTopic}
              onAddQuestion={handleAddQuestion}
              onUpdateQuestion={handleUpdateQuestion}
              onDeleteQuestion={handleDeleteQuestion}
            />
          )}

          {activeTab === 'cue_cards' && (
            <CueCardsView 
              cueCards={cueCards}
              onAddCueCard={handleAddCueCard}
              onUpdateCueCard={handleUpdateCueCard}
              onDeleteCueCard={handleDeleteCueCard}
            />
          )}

          {activeTab === 'vocabulary' && (
            <VocabularyView 
              vocabulary={vocabulary}
              onAddVocabulary={handleAddVocabulary}
              onUpdateVocabulary={handleUpdateVocabulary}
              onDeleteVocabulary={handleDeleteVocabulary}
            />
          )}
        </main>
      </div>

      {/* Settings Modal */}
      <SettingsModal 
        isOpen={showSettings}
        onClose={() => setShowSettings(false)}
        onConnectionChanged={(connected) => {
          setIsSupabaseConnected(connected);
          loadAllData();
        }}
        showToast={showToast}
      />

      {/* Auth Modal */}
      <AuthModal
        isOpen={showAuth}
        onClose={() => setShowAuth(false)}
        onAuthSuccess={(user) => {
          setCurrentUser(user);
          showToast(`Signed in as ${user.email}`);
        }}
      />

      {/* Toast Notification */}
      {toast && (
        <div className={`toast ${toast.type}`}>
          {toast.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
          <span>{toast.message}</span>
        </div>
      )}
    </div>
  );
}
