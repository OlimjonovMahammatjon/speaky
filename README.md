# 🎙️ IELTS SPEAKY • Ecosystem

An all-in-one IELTS Speaking preparation platform featuring a Flutter mobile app built with **Clean Architecture** and a **React (Vite) Admin Studio** connected via **Supabase**.

---

## 📁 Repository Structure

```
Speaking App/
├── mobile_app/         # Flutter Mobile Application (Clean Architecture + BLoC + Supabase)
├── admin_panel/        # React + Vite Admin Panel (Question & Cue Card Management)
└── supabase/           # PostgreSQL Schema, RLS Policies & Seed Migrations
    └── schema.sql
```

---

## 📱 1. Mobile App (`mobile_app/`)
Built with Flutter & Clean Architecture:
- **Clean Architecture Layers**: `core/`, `domain/`, `data/`, `presentation/`
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **Database / Cloud**: `supabase_flutter` with seamless offline cache fallback
- **Features**:
  - Part 1: Interactive Interview Topics with Band 8.5 sample answers & examiner tips
  - Part 2: Timed Candidate Task Cards (1-min prep + 2-min recording with live audio wave)
  - Part 3 & Full Mock: Real-time exam simulation & 4 criteria scoring (FC, LR, GRA, PR)
  - Band 8+ Lexical Bank: Collocations, Idioms & Discourse Markers

### How to Run:
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 💻 2. React Admin Studio (`admin_panel/`)
Built with React 19, Vite, and Lucide Icons:
- **Dashboard**: Live counts of topics, questions, cue cards, and vocabulary items
- **Part 1 Manager**: Create and organize topics and interview questions
- **Part 2 Manager**: Upload Candidate Task Cards with bullet points, Band 9 model answers, and Part 3 follow-ups
- **Vocabulary Manager**: Add high-scoring idioms, collocations, and discourse markers
- **Supabase Cloud Sync**: 1-click cloud synchronization and sample data seeder

### How to Run:
```bash
cd admin_panel
npm install
npm run dev
```

---

## 🗄️ 3. Supabase Setup (`supabase/schema.sql`)
1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** tab in your Supabase Dashboard.
3. Paste the contents of `supabase/schema.sql` and run it.
4. Add your **Project URL** and **Anon Key** in either:
   - React Admin Panel (click "Connect Supabase" in the header)
   - Flutter App (`mobile_app/lib/core/network/supabase_config.dart`)
