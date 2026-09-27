-- ==========================================================
-- IELTS SPEAKY - Supabase Database Schema
-- ==========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TOPICS TABLE (Part 1 Speaking Topics)
CREATE TABLE IF NOT EXISTS public.topics (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'technology',
    part_number INTEGER NOT NULL DEFAULT 1,
    questions_count INTEGER NOT NULL DEFAULT 4,
    band_target TEXT NOT NULL DEFAULT '7.5+',
    icon_code TEXT NOT NULL DEFAULT 'chat',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()) NOT NULL
);

-- 2. QUESTIONS TABLE (Part 1 Interview Questions)
CREATE TABLE IF NOT EXISTS public.questions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    topic_id TEXT NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    sample_answer_band8 TEXT NOT NULL,
    short_sample_answer TEXT NOT NULL DEFAULT '',
    ideas TEXT[] NOT NULL DEFAULT '{}',
    high_band_vocabulary TEXT[] NOT NULL DEFAULT '{}',
    examiner_tips TEXT[] NOT NULL DEFAULT '{}',
    order_index INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()) NOT NULL
);

-- 3. CUE CARDS TABLE (Part 2 Candidate Task Cards & Part 3 Follow-ups)
CREATE TABLE IF NOT EXISTS public.cue_cards (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    title TEXT NOT NULL,
    topic_area TEXT NOT NULL,
    cue_prompt TEXT NOT NULL,
    bullet_points TEXT[] NOT NULL DEFAULT '{}',
    story_ideas TEXT[] NOT NULL DEFAULT '{}',
    short_sample_answer TEXT NOT NULL DEFAULT '',
    band9_model_answer TEXT NOT NULL,
    key_collocations TEXT[] NOT NULL DEFAULT '{}',
    part3_follow_ups TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()) NOT NULL
);

-- 4. VOCABULARY TABLE (Band 8+ Idioms, Collocations & Linkers)
CREATE TABLE IF NOT EXISTS public.vocabulary (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    phrase TEXT NOT NULL,
    phonetics TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT 'collocation', -- 'collocation', 'idiom', 'discourseMarker', 'academicLexis'
    meaning TEXT NOT NULL,
    band_target TEXT NOT NULL DEFAULT 'Band 8.0+',
    example_ielts_context TEXT NOT NULL,
    topic_tag TEXT NOT NULL DEFAULT 'General',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()) NOT NULL
);

-- 5. MOCK EVALUATIONS (Test History & Scores)
CREATE TABLE IF NOT EXISTS public.mock_evaluations (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    test_title TEXT NOT NULL,
    overall_band NUMERIC(3, 1) NOT NULL,
    fluency_band NUMERIC(3, 1) NOT NULL,
    lexical_band NUMERIC(3, 1) NOT NULL,
    grammar_band NUMERIC(3, 1) NOT NULL,
    pronunciation_band NUMERIC(3, 1) NOT NULL,
    feedback_summary TEXT NOT NULL,
    strengths TEXT[] NOT NULL DEFAULT '{}',
    areas_to_improve TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()) NOT NULL
);

-- ==========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================================
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cue_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vocabulary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_evaluations ENABLE ROW LEVEL SECURITY;

-- Public read access (anon key can read, for mobile app users)
CREATE POLICY "Allow public read access on topics" ON public.topics FOR SELECT USING (true);
CREATE POLICY "Allow public read access on questions" ON public.questions FOR SELECT USING (true);
CREATE POLICY "Allow public read access on cue_cards" ON public.cue_cards FOR SELECT USING (true);
CREATE POLICY "Allow public read access on vocabulary" ON public.vocabulary FOR SELECT USING (true);
CREATE POLICY "Allow public read access on mock_evaluations" ON public.mock_evaluations FOR SELECT USING (true);

-- Admin write access: only authenticated users (Supabase Auth)
-- Requires admin to sign in via Supabase Auth before using the admin panel
CREATE POLICY "Admin write access on topics" ON public.topics FOR ALL
  TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin write access on questions" ON public.questions FOR ALL
  TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin write access on cue_cards" ON public.cue_cards FOR ALL
  TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin write access on vocabulary" ON public.vocabulary FOR ALL
  TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin write access on mock_evaluations" ON public.mock_evaluations FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- NOTE: The old policies below used USING(true) WITH CHECK(true) for ALL users
-- including anon, which allowed anyone to DELETE everything.
-- Now only authenticated users can write. Anon users can only read.

-- ==========================================================
-- SAMPLE SEED DATA
-- ==========================================================
INSERT INTO public.topics (id, title, description, category, part_number, questions_count, band_target, icon_code)
VALUES 
('p1_tech', 'Artificial Intelligence & Tech', 'Discussing daily smart gadgets, automated systems, and modern digital lifestyle.', 'technology', 1, 3, '8.0+', 'smart_toy'),
('p1_work', 'Work & Studies', 'Core IELTS topic: current job, career aspirations, and educational background.', 'workAndStudy', 1, 2, '7.5+', 'business_center'),
('p1_environment', 'Environmental Protection', 'Recycling habits, renewable green habits, and climate consciousness.', 'environment', 1, 3, '8.0+', 'eco')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.questions (id, topic_id, question_text, short_sample_answer, ideas, sample_answer_band8, high_band_vocabulary, examiner_tips, order_index)
VALUES 
('q1_1', 'p1_tech', 'Do you frequently use artificial intelligence tools in your daily routine?', 'Yes, I use AI apps like ChatGPT and smart writing assistants daily to draft quick emails, summarize long articles, and save time on repetitive work.', ARRAY['Daily tools: ChatGPT, Grammarly, smart search', 'Use cases: Drafting emails, summarizing articles, brainstorming ideas', 'Benefits: Saves hours of tedious work, boosts productivity'], 'Yes, absolutely. AI has practically woven itself into the fabric of my daily routine. For instance, I frequently rely on intelligent search engines and natural language assistants to streamline research and automate repetitive clerical tasks. It saves me an enormous amount of time.', ARRAY['Woven itself into the fabric of', 'Streamline research', 'Automate repetitive clerical tasks'], ARRAY['Extend your answer by giving a clear, concrete example.', 'Avoid simple yes/no responses; showcase topical collocations.'], 1),
('q1_2', 'p1_tech', 'Are there any disadvantages to relying heavily on modern gadgets?', 'A major disadvantage is reduced attention span and reliance on automated corrections, which can weaken memory and creative problem-solving skills.', ARRAY['Attention span & patience: Instant dopamine reduces focus', 'Cognitive reliance: Relying on calculators and spell-check weakens mental math & spelling', 'Health: Eye strain, sedentary lifestyle, insomnia from blue light'], 'Undoubtedly, there are noticeable pitfalls. One primary drawback is our diminishing cognitive endurance and attention spans, as people have become accustomed to instantaneous gratification. Furthermore, over-reliance on automated tools can occasionally stifle spontaneous creative thinking.', ARRAY['Noticeable pitfalls', 'Diminishing cognitive endurance', 'Instantaneous gratification', 'Stifle spontaneous creative thinking'], ARRAY['Use contrasting linking words like "Undoubtedly" or "Furthermore".', 'Discuss broader societal impacts rather than just personal inconvenience.'], 2)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.cue_cards (id, title, topic_area, cue_prompt, bullet_points, story_ideas, short_sample_answer, band9_model_answer, key_collocations, part3_follow_ups)
VALUES 
('cc_1', 'A Difficult Decision with a Positive Outcome', 'Life Experience & Problem Solving', 'Describe a difficult decision you made that had a positive outcome in the end.', ARRAY['What the decision was and when you made it', 'Why it was difficult or stressful to make', 'What advice or factors influenced your final choice', 'And explain why the outcome turned out to be so rewarding.'], ARRAY['Option A: Leaving a secure corporate job to learn software engineering', 'Option B: Choosing to study abroad in a foreign country despite homesickness', 'Option C: Turning down a safe inheritance to build a sustainable local startup'], 'A challenging decision I made was leaving my comfortable corporate job to pivot into software engineering, which initially felt daunting but eventually doubled my career fulfillment.', 'Without a shadow of a doubt, making consequential life choices is seldom straightforward. I would like to talk about the pivotal juncture three years ago when I resolved to transition from my stable corporate desk job into high-tech software engineering. At that time, I was working as a junior project coordinator. While the compensation was dependable, I felt professionally stagnant and realized my genuine passion lay in technology and problem solving. It was an excruciating dilemma because it demanded resigning from a steady income stream to enroll in an intensive boot-camp. My peers were somewhat skeptical, arguing that abandoning stability was a reckless gamble. Nonetheless, after conducting thorough research and seeking counsel from a seasoned mentor, I took the leap of faith. The initial months were undeniably grueling—I had to burn the midnight oil mastering complex algorithmic paradigms. However, persevering through that steep learning curve yielded spectacular rewards. Within eight months, I secured a role at an international tech firm with double my prior remuneration and immensely greater job satisfaction. Looking back, that difficult choice taught me that calculated risks and resilience invariably pay dividends.', ARRAY['Without a shadow of a doubt', 'Pivotal juncture', 'Professionally stagnant', 'Leap of faith', 'Burn the midnight oil', 'Pay dividends'], ARRAY['Why do some individuals struggle more than others with decision making?', 'Do you think elders always give more sensible advice compared to friends?', 'How does technology influence everyday decision making nowadays?'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.vocabulary (id, phrase, phonetics, type, meaning, band_target, example_ielts_context, topic_tag)
VALUES 
('v_1', 'Embark upon', '/ɪmˈbɑːrk əˈpɒn/', 'collocation', 'To start or commence a significant, adventurous, or challenging undertaking.', 'Band 8.5+', 'Before embarking upon my university studies, I took a gap year to volunteer.', 'Education & Career'),
('v_2', 'Of paramount importance', '/ɒv ˈpær.ə.maʊnt ɪmˈpɔː.təns/', 'academicLexis', 'More important than anything else; supreme in significance.', 'Band 9.0', 'Safeguarding natural biospheres is of paramount importance for succeeding generations.', 'Environment'),
('v_3', 'Having said that', '/ˈhæv.ɪŋ sed ðæt/', 'discourseMarker', 'Used to introduce an opposing viewpoint or qualification; synonymous with nevertheless.', 'Band 8.0+', 'Urban living is bustling and full of career opportunities. Having said that, the stress levels can be quite detrimental.', 'Discourse Marker')
ON CONFLICT (id) DO NOTHING;
