import { createClient } from '@supabase/supabase-js';

// Default keys or retrieve from localStorage
const STORAGE_URL_KEY = 'ielts_speaky_supabase_url';
const STORAGE_KEY_KEY = 'ielts_speaky_supabase_key';

export const getSavedCredentials = () => {
  const envUrl = import.meta.env.VITE_SUPABASE_URL || '';
  const envKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  // Priority 1: Check .env variables
  if (
    envUrl &&
    envKey &&
    !envUrl.includes('your-project-id') &&
    !envKey.includes('your-anon-key-here') &&
    envUrl.startsWith('https://')
  ) {
    return { url: envUrl.trim(), key: envKey.trim(), fromEnv: true };
  }

  // Priority 2: Check localStorage
  const url = localStorage.getItem(STORAGE_URL_KEY) || '';
  const key = localStorage.getItem(STORAGE_KEY_KEY) || '';
  return { url, key, fromEnv: false };
};

export const saveCredentials = (url, key) => {
  localStorage.setItem(STORAGE_URL_KEY, url.trim());
  localStorage.setItem(STORAGE_KEY_KEY, key.trim());
  supabaseInstance = null; // reset instance
};

let supabaseInstance = null;

export const getSupabase = () => {
  if (supabaseInstance) return supabaseInstance;

  const { url, key } = getSavedCredentials();
  if (url && key && url.startsWith('https://')) {
    try {
      supabaseInstance = createClient(url, key);
      return supabaseInstance;
    } catch (e) {
      console.error('Supabase init error:', e);
    }
  }
  return null;
};

// ===== Authentication =====

export const getCurrentUser = () => {
  const client = getSupabase();
  if (!client) return Promise.resolve(null);
  return client.auth.getUser().then(({ data }) => data?.user || null).catch(() => null);
};

export const signIn = async (email, password) => {
  const client = getSupabase();
  if (!client) return { success: false, message: 'Supabase not configured' };
  try {
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return { success: true, user: data.user };
  } catch (e) {
    return { success: false, message: e.message || 'Sign in failed' };
  }
};

export const signOut = async () => {
  const client = getSupabase();
  if (!client) return;
  try {
    await client.auth.signOut();
  } catch (_) {}
};

export const onAuthChange = (callback) => {
  const client = getSupabase();
  if (!client) return () => {};
  return client.auth.onAuthStateChange((_event, session) => {
    callback(session?.user || null);
  });
};

// Initial Mock Seed Data used for offline mode & 1-click cloud push
export const INITIAL_MOCK_DATA = {
  topics: [
    {
      id: 'p1_tech',
      title: 'Artificial Intelligence & Tech',
      description: 'Discussing daily smart gadgets, automated systems, and modern digital lifestyle.',
      category: 'technology',
      part_number: 1,
      questions_count: 3,
      band_target: '8.0+',
      icon_code: 'smart_toy',
    },
    {
      id: 'p1_work',
      title: 'Work & Studies',
      description: 'Core IELTS topic: current job, career aspirations, and educational background.',
      category: 'workAndStudy',
      part_number: 1,
      questions_count: 2,
      band_target: '7.5+',
      icon_code: 'business_center',
    },
    {
      id: 'p1_environment',
      title: 'Environmental Protection',
      description: 'Recycling habits, renewable green habits, and climate consciousness.',
      category: 'environment',
      part_number: 1,
      questions_count: 2,
      band_target: '8.0+',
      icon_code: 'eco',
    },
  ],
  questions: [
    {
      id: 'q1_1',
      topic_id: 'p1_tech',
      question_text: 'Do you frequently use artificial intelligence tools in your daily routine?',
      short_sample_answer: 'Yes, I use AI apps like ChatGPT and smart writing assistants daily to draft quick emails, summarize long articles, and save time on repetitive work.',
      ideas: [
        'Daily tools: ChatGPT, Grammarly, smart search',
        'Use cases: Drafting emails, summarizing articles, brainstorming ideas',
        'Benefits: Saves hours of tedious work, boosts productivity'
      ],
      sample_answer_band8: 'Yes, absolutely. AI has practically woven itself into the fabric of my daily routine. For instance, I frequently rely on intelligent search engines and natural language assistants to streamline research and automate repetitive clerical tasks. It saves me an enormous amount of time.',
      high_band_vocabulary: ['Woven itself into the fabric of', 'Streamline research', 'Automate repetitive clerical tasks'],
      examiner_tips: ['Extend your answer by giving a clear, concrete example.', 'Avoid simple yes/no responses; showcase topical collocations.'],
      order_index: 1,
    },
    {
      id: 'q1_2',
      topic_id: 'p1_tech',
      question_text: 'Are there any disadvantages to relying heavily on modern gadgets?',
      short_sample_answer: 'A major disadvantage is reduced attention span and reliance on automated corrections, which can weaken memory and creative problem-solving skills.',
      ideas: [
        'Attention span & patience: Instant dopamine reduces focus',
        'Cognitive reliance: Relying on calculators and spell-check weakens mental math & spelling',
        'Health: Eye strain, sedentary lifestyle, insomnia from blue light'
      ],
      sample_answer_band8: 'Undoubtedly, there are noticeable pitfalls. One primary drawback is our diminishing cognitive endurance and attention spans, as people have become accustomed to instantaneous gratification. Furthermore, over-reliance on automated tools can occasionally stifle spontaneous creative thinking.',
      high_band_vocabulary: ['Noticeable pitfalls', 'Diminishing cognitive endurance', 'Instantaneous gratification', 'Stifle spontaneous creative thinking'],
      examiner_tips: ['Use contrasting linking words like "Undoubtedly" or "Furthermore".', 'Discuss broader societal impacts rather than just personal inconvenience.'],
      order_index: 2,
    },
    {
      id: 'q2_1',
      topic_id: 'p1_work',
      question_text: 'Do you currently work or are you a student?',
      short_sample_answer: 'I am currently balancing both: studying computer science at university while working part-time as a junior developer to gain real-world experience.',
      ideas: [
        'Status: Juggling both (part-time software job + student)',
        'Daily routine: Classes in the morning, coding projects in afternoon',
        'Benefits: Applying classroom theories directly into real-world code'
      ],
      sample_answer_band8: 'At present, I am actively juggling both. I work part-time as a junior developer while concurrently pursuing a degree in computer engineering. Maintaining this equilibrium requires rigorous discipline, but it allows me to directly translate theoretical classroom concepts into practical industry applications.',
      high_band_vocabulary: ['Actively juggling both', 'Concurrently pursuing', 'Maintaining this equilibrium', 'Theoretical concepts into practical applications'],
      examiner_tips: ['Be direct in your first sentence, then elaborate with nuance.', 'Use dynamic adverbs like "concurrently", "rigorously".'],
      order_index: 1,
    },
  ],
  cue_cards: [
    {
      id: 'cc_1',
      title: 'A Difficult Decision with a Positive Outcome',
      topic_area: 'Life Experience & Problem Solving',
      cue_prompt: 'Describe a difficult decision you made that had a positive outcome in the end.',
      bullet_points: [
        'What the decision was and when you made it',
        'Why it was difficult or stressful to make',
        'What advice or factors influenced your final choice',
        'And explain why the outcome turned out to be so rewarding.'
      ],
      story_ideas: [
        'Option A: Leaving a secure corporate job to learn software engineering',
        'Option B: Choosing to study abroad in a foreign country despite homesickness',
        'Option C: Turning down a safe inheritance to build a sustainable local startup'
      ],
      short_sample_answer: 'A challenging decision I made was leaving my comfortable corporate job to pivot into software engineering, which initially felt daunting but eventually doubled my career fulfillment.',
      band9_model_answer: 'Without a shadow of a doubt, making consequential life choices is seldom straightforward. I would like to talk about the pivotal juncture three years ago when I resolved to transition from my stable corporate desk job into high-tech software engineering. At that time, I was working as a junior project coordinator. While the compensation was dependable, I felt professionally stagnant and realized my genuine passion lay in technology and problem solving. It was an excruciating dilemma because it demanded resigning from a steady income stream to enroll in an intensive boot-camp. My peers were somewhat skeptical, arguing that abandoning stability was a reckless gamble. Nonetheless, after conducting thorough research and seeking counsel from a seasoned mentor, I took the leap of faith. The initial months were undeniably grueling—I had to burn the midnight oil mastering complex algorithmic paradigms. However, persevering through that steep learning curve yielded spectacular rewards. Within eight months, I secured a role at an international tech firm with double my prior remuneration and immensely greater job satisfaction. Looking back, that difficult choice taught me that calculated risks and resilience invariably pay dividends.',
      key_collocations: ['Without a shadow of a doubt', 'Pivotal juncture', 'Professionally stagnant', 'Leap of faith', 'Burn the midnight oil', 'Pay dividends'],
      part3_follow_ups: [
        'Why do some individuals struggle more than others with decision making?',
        'Do you think elders always give more sensible advice compared to friends?',
        'How does technology influence everyday decision making nowadays?'
      ],
    },
    {
      id: 'cc_2',
      title: 'An Ambitious Person You Greatly Admire',
      topic_area: 'People & Personality',
      cue_prompt: 'Describe an ambitious person you know and greatly admire.',
      bullet_points: [
        'Who this person is and your relationship to them',
        'What their personal or professional goals are',
        'How they work tirelessly to achieve those goals',
        'And explain why you hold them in such high esteem.'
      ],
      story_ideas: [
        'Option A: An older sibling or relative who became a dedicated doctor/surgeon',
        'Option B: A local entrepreneur who built an educational academy from nothing',
        'Option C: A school teacher who overcame physical disability to mentor students'
      ],
      short_sample_answer: 'The ambitious person I admire most is my elder sister, who navigated grueling pediatric surgical residency to provide free healthcare in rural clinics.',
      band9_model_answer: 'When thinking of ambition and tenacity, the first person that spontaneously springs to mind is my elder sister, Nodira. She is a dedicated pediatric surgeon whose unwavering commitment to healthcare has always left me in awe. Ever since our teenage years, she harbored an aspiration to spearhead pediatric medical research in underserved regions. Achieving this required navigating an exceptionally competitive academic pipeline. She completed her residency while concurrently authoring peer-reviewed medical journals. Her diligence is astonishing; she maintains an impeccable work ethic without ever succumbing to burnout. What I admire most is that her ambition is not driven by vanity or monetary gain, but rather by an altruistic desire to alleviate suffering among vulnerable children. Her tenacity serves as a continuous beacon of inspiration for my own personal and academic endeavors.',
      key_collocations: ['Spontaneously springs to mind', 'Unwavering commitment', 'Harbored an aspiration', 'Impeccable work ethic', 'Beacon of inspiration'],
      part3_follow_ups: [
        'Is ambition always a positive character trait, or can it have detrimental effects?',
        'How can parents nurture healthy ambition in young children?'
      ],
    }
  ],
  vocabulary: [
    {
      id: 'v_1',
      phrase: 'Embark upon',
      phonetics: '/ɪmˈbɑːrk əˈpɒn/',
      type: 'collocation',
      meaning: 'To start or commence a significant, adventurous, or challenging undertaking.',
      band_target: 'Band 8.5+',
      example_ielts_context: 'Before embarking upon my university studies, I took a gap year to volunteer.',
      topic_tag: 'Education & Career',
    },
    {
      id: 'v_2',
      phrase: 'Of paramount importance',
      phonetics: '/ɒv ˈpær.ə.maʊnt ɪmˈpɔː.təns/',
      type: 'academicLexis',
      meaning: 'More important than anything else; supreme in significance.',
      band_target: 'Band 9.0',
      example_ielts_context: 'Safeguarding natural biospheres is of paramount importance for succeeding generations.',
      topic_tag: 'Environment',
    },
    {
      id: 'v_3',
      phrase: 'Having said that',
      phonetics: '/ˈhæv.ɪŋ sed ðæt/',
      type: 'discourseMarker',
      meaning: 'Used to introduce an opposing viewpoint or qualification; synonymous with nevertheless.',
      band_target: 'Band 8.0+',
      example_ielts_context: 'Urban living is bustling and full of career opportunities. Having said that, the stress levels can be quite detrimental.',
      topic_tag: 'Discourse Marker',
    }
  ]
};

// API Functions
export const api = {
  // Test connection
  async testConnection() {
    const client = getSupabase();
    if (!client) return { success: false, message: 'Supabase credentials not configured' };
    try {
      const { error } = await client.from('topics').select('id').limit(1);
      if (error) throw error;
      return { success: true, message: 'Successfully connected to Supabase database!' };
    } catch (e) {
      return { success: false, message: e.message || 'Connection failed' };
    }
  },

  // Topics
  async getTopics() {
    const client = getSupabase();
    if (!client) {
      const local = localStorage.getItem('ielts_local_topics');
      return local ? JSON.parse(local) : INITIAL_MOCK_DATA.topics;
    }
    const { data, error } = await client.from('topics').select('*').order('created_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  async addTopic(topic) {
    const client = getSupabase();
    const newTopic = {
      ...topic,
      id: topic.id || `topic_${Date.now()}`,
      created_at: new Date().toISOString(),
    };
    if (!client) {
      const current = await api.getTopics();
      const updated = [newTopic, ...current];
      localStorage.setItem('ielts_local_topics', JSON.stringify(updated));
      return newTopic;
    }
    const { data, error } = await client.from('topics').insert([newTopic]).select().single();
    if (error) throw error;
    return data;
  },

  async updateTopic(id, updated) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getTopics();
      const updatedList = current.map(t => t.id === id ? { ...t, ...updated } : t);
      localStorage.setItem('ielts_local_topics', JSON.stringify(updatedList));
      return { ...current.find(t => t.id === id), ...updated };
    }
    const { data, error } = await client.from('topics').update(updated).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },

  async deleteTopic(id) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getTopics();
      const updated = current.filter(t => t.id !== id);
      localStorage.setItem('ielts_local_topics', JSON.stringify(updated));
      return true;
    }
    const { error } = await client.from('topics').delete().eq('id', id);
    if (error) throw error;
    return true;
  },

  // Questions
  async getQuestions(topicId) {
    const client = getSupabase();
    if (!client) {
      const local = localStorage.getItem('ielts_local_questions');
      const all = local ? JSON.parse(local) : INITIAL_MOCK_DATA.questions;
      return topicId ? all.filter(q => q.topic_id === topicId) : all;
    }
    let query = client.from('questions').select('*').order('order_index', { ascending: true });
    if (topicId) query = query.eq('topic_id', topicId);
    const { data, error } = await query;
    if (error) throw error;
    return data;
  },

  async addQuestion(question) {
    const client = getSupabase();
    const newQ = {
      ...question,
      id: question.id || `q_${Date.now()}`,
      created_at: new Date().toISOString(),
    };
    if (!client) {
      const current = await api.getQuestions();
      const updated = [newQ, ...current];
      localStorage.setItem('ielts_local_questions', JSON.stringify(updated));
      return newQ;
    }
    const { data, error } = await client.from('questions').insert([newQ]).select().single();
    if (error) throw error;
    return data;
  },

  async updateQuestion(id, updated) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getQuestions();
      const updatedList = current.map(q => q.id === id ? { ...q, ...updated } : q);
      localStorage.setItem('ielts_local_questions', JSON.stringify(updatedList));
      return { ...current.find(q => q.id === id), ...updated };
    }
    const { data, error } = await client.from('questions').update(updated).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },

  async deleteQuestion(id) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getQuestions();
      const updated = current.filter(q => q.id !== id);
      localStorage.setItem('ielts_local_questions', JSON.stringify(updated));
      return true;
    }
    const { error } = await client.from('questions').delete().eq('id', id);
    if (error) throw error;
    return true;
  },

  // Cue Cards
  async getCueCards() {
    const client = getSupabase();
    if (!client) {
      const local = localStorage.getItem('ielts_local_cue_cards');
      return local ? JSON.parse(local) : INITIAL_MOCK_DATA.cue_cards;
    }
    const { data, error } = await client.from('cue_cards').select('*').order('created_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  async addCueCard(card) {
    const client = getSupabase();
    const newCard = {
      ...card,
      id: card.id || `cc_${Date.now()}`,
      created_at: new Date().toISOString(),
    };
    if (!client) {
      const current = await api.getCueCards();
      const updated = [newCard, ...current];
      localStorage.setItem('ielts_local_cue_cards', JSON.stringify(updated));
      return newCard;
    }
    const { data, error } = await client.from('cue_cards').insert([newCard]).select().single();
    if (error) throw error;
    return data;
  },

  async updateCueCard(id, updated) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getCueCards();
      const updatedList = current.map(c => c.id === id ? { ...c, ...updated } : c);
      localStorage.setItem('ielts_local_cue_cards', JSON.stringify(updatedList));
      return { ...current.find(c => c.id === id), ...updated };
    }
    const { data, error } = await client.from('cue_cards').update(updated).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },

  async deleteCueCard(id) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getCueCards();
      const updated = current.filter(c => c.id !== id);
      localStorage.setItem('ielts_local_cue_cards', JSON.stringify(updated));
      return true;
    }
    const { error } = await client.from('cue_cards').delete().eq('id', id);
    if (error) throw error;
    return true;
  },

  // Vocabulary
  async getVocabulary() {
    const client = getSupabase();
    if (!client) {
      const local = localStorage.getItem('ielts_local_vocabulary');
      return local ? JSON.parse(local) : INITIAL_MOCK_DATA.vocabulary;
    }
    const { data, error } = await client.from('vocabulary').select('*').order('phrase', { ascending: true });
    if (error) throw error;
    return data;
  },

  async addVocabulary(vocab) {
    const client = getSupabase();
    const newVocab = {
      ...vocab,
      id: vocab.id || `v_${Date.now()}`,
      created_at: new Date().toISOString(),
    };
    if (!client) {
      const current = await api.getVocabulary();
      const updated = [newVocab, ...current];
      localStorage.setItem('ielts_local_vocabulary', JSON.stringify(updated));
      return newVocab;
    }
    const { data, error } = await client.from('vocabulary').insert([newVocab]).select().single();
    if (error) throw error;
    return data;
  },

  async updateVocabulary(id, updated) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getVocabulary();
      const updatedList = current.map(v => v.id === id ? { ...v, ...updated } : v);
      localStorage.setItem('ielts_local_vocabulary', JSON.stringify(updatedList));
      return { ...current.find(v => v.id === id), ...updated };
    }
    const { data, error } = await client.from('vocabulary').update(updated).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },

  async deleteVocabulary(id) {
    const client = getSupabase();
    if (!client) {
      const current = await api.getVocabulary();
      const updated = current.filter(v => v.id !== id);
      localStorage.setItem('ielts_local_vocabulary', JSON.stringify(updated));
      return true;
    }
    const { error } = await client.from('vocabulary').delete().eq('id', id);
    if (error) throw error;
    return true;
  },

  // App Settings (AI API Keys & Configuration)
  async getAppSettings() {
    const client = getSupabase();
    const localGemini = localStorage.getItem('ielts_gemini_api_key') || '';
    const localGroq = localStorage.getItem('ielts_groq_api_key') || '';
    const localMode = localStorage.getItem('ielts_ai_mode') || 'auto';

    const defaultSettings = {
      gemini_api_key: localGemini,
      groq_api_key: localGroq,
      active_ai_provider: localMode,
    };

    if (!client) return defaultSettings;

    try {
      const { data, error } = await client.from('app_settings').select('*');
      if (error || !data) return defaultSettings;
      const settings = { ...defaultSettings };
      data.forEach(row => {
        settings[row.key] = row.value;
      });
      return settings;
    } catch (_) {
      return defaultSettings;
    }
  },

  async saveAppSettings(settings) {
    if (settings.gemini_api_key !== undefined) {
      localStorage.setItem('ielts_gemini_api_key', (settings.gemini_api_key || '').trim());
    }
    if (settings.groq_api_key !== undefined) {
      localStorage.setItem('ielts_groq_api_key', (settings.groq_api_key || '').trim());
    }
    if (settings.active_ai_provider !== undefined) {
      localStorage.setItem('ielts_ai_mode', settings.active_ai_provider || 'auto');
    }

    const client = getSupabase();
    if (!client) return true;

    try {
      const rows = [
        { key: 'gemini_api_key', value: (settings.gemini_api_key || '').trim(), updated_at: new Date().toISOString() },
        { key: 'groq_api_key', value: (settings.groq_api_key || '').trim(), updated_at: new Date().toISOString() },
        { key: 'active_ai_provider', value: settings.active_ai_provider || 'auto', updated_at: new Date().toISOString() },
      ];
      await client.from('app_settings').upsert(rows);
      return true;
    } catch (e) {
      console.warn('Failed to save to Supabase app_settings table:', e);
      return false;
    }
  },

  // Seed sample data to Supabase
  async seedSampleDataToSupabase() {
    const client = getSupabase();
    if (!client) throw new Error('Please configure Supabase URL & Anon Key first!');

    await client.from('topics').upsert(INITIAL_MOCK_DATA.topics);
    await client.from('questions').upsert(INITIAL_MOCK_DATA.questions);
    await client.from('cue_cards').upsert(INITIAL_MOCK_DATA.cue_cards);
    await client.from('vocabulary').upsert(INITIAL_MOCK_DATA.vocabulary);

    return true;
  }
};
