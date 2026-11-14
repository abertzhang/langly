# reply

这个Tool Box是我原创,本来是另一个AI绳结系列(正开发中未上架)的工具功能,该app的页面都是我独自结合AI工具设计的,页面都属于原创,app的代码也是我的原创,使用Flutter技术栈,数据库由supabase提供服务.因此这个app没有任何抄袭,是原创.

# Reply in English

Dear App Review Team,

Thank you for the feedback under Guideline 4.3(a). Tool Box is entirely my own work; below are the facts and one specific request before I make any changes.

**1. Independent authorship.** I am the sole developer: every screen, interaction and visual asset was designed and implemented by me, with AI tools used only as a productivity aid. No app template, UI kit, purchased shell or white-label framework is involved — only public, general-purpose packages (Flutter, go_router, Riverpod, Supabase, Isar, Hive, AdMob, in-app purchase, platform sensors).

**2. Not repackaged or split.** The idea came from utilities I prototyped for a separate, still-unreleased AI knot-tying project that has never been submitted to App Review or published on the App Store. Tool Box has its own codebase, design system, data model and store listing, and shares no source code, icons or screenshots with it. I have not submitted near-identical apps under other names or accounts.

**3. Original engineering.** Beyond the screens: a custom theme and navigation shell; a self-designed analytics pipeline (event schema, batching, retry queue, value bucketing, no raw measurements uploaded); a free-usage quota with rewarded-ad bonuses; a one-time Pro Unlock with restore; and a full in-app account deletion flow. These run on custom Supabase logic (PostgreSQL, Row Level Security, RPCs, Edge Functions) plus on-device Isar/Hive storage, with five-language localisation, native iOS permission prompts and UMP consent.

**4. Request.** Could you please indicate whether the similarity was found in the binary, metadata or concept — and, if possible, which app or listing was compared? Compasses, levels and sound meters are common categories, but the implementation above is my own. If the concern is the listing, I will rewrite the description, subtitle, keywords and screenshots to describe this app specifically.

Available on request: a source repository with dated commits (read-only access if helpful), original icon and screenshot artwork, an unedited device recording, and the custom SQL / Edge Function code. I would rather act on your guidance than resubmit an unchanged build. Thank you for your time.

Sincerely,
zhang chunhua
Tool Box · Bundle ID: uk.aknot.toolbox

# 版本2

Dear App Review Team,

Thank you for the feedback. I would like to clarify that this **Toolbox** app is entirely my own original work.

It began as a supporting utility feature for another project of mine — an AI knot-tying series that is still under development and has not been published. The screens and interaction layouts were designed independently by me; AI tools were used only as an auxiliary design aid, and all layouts, visuals, and copy are original. The source code is also my own original work, built with the **Flutter** framework, with data stored and served through **Supabase**.

I have not copied any design, code, content, or assets from another app. This app provides **[一句话写清核心功能，例如: a set of handy daily utility tools that help users …]**, intended for **[目标用户 / 使用场景]**.

I hope this addresses the 4.3.0 concern. I am happy to provide further details or screenshots if needed.

Best regards, 

zhang chunhua

### fix:

Dear App Review Team,

Thank you for the feedback. I would like to clarify that this **Toolbox** app is entirely my own original work.
It began as a supporting utility feature for another project of mine — an AI knot-tying series that is still under development and has not been published. The screens and interaction layouts were designed independently by me; AI tools were used only as an auxiliary design aid, and all layouts, visuals, and copy are original. The source code is also my own original work, built with the **Flutter** framework, with data stored and served through **Supabase**.
I have not copied any design, code, content, or assets from another app. This app provides a focused set of on-device utilities — compass with bearing and GPS altitude, bubble level, noise meter, adjustable flashlight, on-screen ruler and world clock — plus a locally stored Travel Memo for trip notes, intended for travelers and everyday users who need quick measurements and short notes while away from home.
I hope this addresses the 4.3.0 concern. I am happy to provide further details or screenshots if needed.
Best regards,
zhang chunhua



# app信息备注内容

1. App purpose & target audience:
Tool Box is an all-in-one everyday toolkit for general travelers and everyday users. It replaces many separate single-function apps by combining compass, bubble level, noise meter, flashlight, travel checklist, memo, ruler, tide, unit conversion and other common tools in one lightweight app. Premium is a one-time in-app purchase that removes ads and lifts the free usage limit.
2. Instructions for main features:
The app is fully usable without login as a guest (with a limited free quota). Login is optional via Apple Sign In or Google Sign In.
- Compass: tap to start, calibrate as prompted.
- Bubble level: place phone on a flat surface to measure angle.
- Noise meter: grant microphone permission, then measure noise.
- Flashlight: toggle and adjust brightness.
- Travel checklist/memo: add, edit and delete items.
- Pro Unlock: tap the upgrade entry, complete the system in-app purchase, then use "Restore Purchases" to recover the membership.
No demo account or sample files required.
3. External services used:
- Supabase (authentication and user profile storage).
- Google AdMob (banner, rewarded and interstitial ads; premium users see no ads). Google User Messaging Platform (UMP) used for consent where required.
- Apple Sign In and Google Sign In for third-party login.
Core tools run entirely on-device using native iOS APIs (microphone, motion sensors, camera flash, GPS); no data or media is uploaded.
4. Regional differences:
The app is offered in all App Store countries and regions except mainland China. There are NO functional or content differences across offered regions; all features work consistently everywhere.
5. Regulated industry / third-party material:
This app is not in a highly regulated industry. All icons and assets are original and owned by the developer. No copyrighted third-party protected materials are used.
The app was fully tested on physical iPhone devices with no crashes, plus TestFlight beta testing. Because it supports account creation, it includes a complete in-app account deletion flow. It includes a non-consumable in-app purchase ("Pro Unlock", $1.99 lifetime) with a working restore function verified in sandbox. All App Store screenshots show the real running UI, not splash screens. This app is for general consumers, not specific businesses.

