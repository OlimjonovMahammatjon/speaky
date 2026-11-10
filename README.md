# 🎙️ IELTS SPEAKY • Ecosystem

An all-in-one IELTS Speaking preparation platform featuring a Flutter mobile app built with **Clean Architecture** and a **React 19 (Vite) Admin Studio** powered by **Dual-Engine AI (Google Gemini + Groq Whisper Large V3 & LLaMA 3.3)** connected via **Supabase**.

---

## 📁 Repository Structure

```
Speaking App/
├── mobile_app/         # Flutter Mobile Application (Clean Architecture + BLoC + Dual AI)
├── admin_panel/        # React + Vite Admin Studio (CRUD + AI API Key Manager)
├── supabase/           # PostgreSQL Schema, RLS Policies, app_settings & Seeds
│   └── schema.sql
├── PLAN.md             # Detailed Master Development Plan
└── README.md
```

---

## ⚡ Dual-Engine AI Architecture

API kalitlar Admin Panelda kiritiladi va Supabase orqali mobil ilovaga avtomatik sinxronlanadi:
1. **Google Gemini 1.5 & 2.0 Flash:** Native multimodal audio tahlili (intonatsiya, pauzalar, ravonlik).
2. **Groq Cloud (Whisper Large V3 + LLaMA 3.3 70B):** Dunyodagi eng tezkor transkripsiya va sub-soniyalik tahlil.
3. **⚡ Auto Dual-Race Mode:** Ikkala modelga parallel so'rov yuboriladi — qaysi biri birinchi javob qaytarsa o'sha ishlaydi! Biri to'xtab qolsa yoki rate limit bo'lsa, ikkinchisi 100% uzluksiz qutqaradi.

---

## 📱 1. Mobile App (`mobile_app/`)
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **AI Speaking Orchestrator**: `AiSpeakingService` (Gemini + Groq race & fallback)
- **Features**:
  - **🤖 AI Speaking Partner**: Groq Whisper va Gemini orqali rasmiy 0.0 - 9.0 mezonlar bo'yicha baholash.
  - **🎧 Audio Replay Player**: O'z ovozingizni qayta tinglash pleyeri va avtomatik transkript.
  - **🏁 Full 3-Part Exam Simulation**: Rasmiy imtihon oqimi (Part 1 $\to$ Part 2 $\to$ Part 3 $\to$ Natija).
  - **Part 1, Part 2 & Lexical Bank**: To'liq oflayn kesh va namunaviy javoblar.

### How to Run:
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 💻 2. React Admin Studio (`admin_panel/`)
- **AI Keys Manager**: Google Gemini va Groq API kalitlarini kiritish va rejimni tanlash (Auto, Gemini, Groq).
- **Full CRUD Management**: Part 1, Part 2 Cue Cards va Vocabulary bo'limlarida yaratish, **tahrirlash (Edit)** va o'chirish.
- **Offline / Local Demo Support**: Supabase bo'lmasa ham to'liq ishlash imkoni.

### How to Run:
```bash
cd admin_panel
npm install
npm run dev
```

---

## 🗄️ 3. Supabase Setup (`supabase/schema.sql`)
1. [supabase.com](https://supabase.com) loyihangiz SQL Editor qismida `supabase/schema.sql` faylini ishga tushiring.
2. Admin Panelda "Connect Supabase" yoki "Settings" orqali Supabase URL & Anon Key kiritib, **Gemini va Groq kalitlarini** saqlang.
