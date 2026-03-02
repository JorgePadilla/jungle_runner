# Jungle Runner — Development Checklist

## 🔴 Critical (Must Fix Before Testing)
- [x] **Camera/Viewport scaling** — FixedResolutionViewport(400x720) added ✅
- [x] **Distance-to-meters conversion** — pixelsPerMeter=50, 150px/s = 3m/s ✅
- [x] **Speed curve tuning** — Gentler progression (rate=3), max=350 ✅
- [x] **World dimensions** — Changed to 400x720 portrait-native ✅

## 🟡 Core Gameplay (Pre-Launch)
- [ ] Additional characters — Jaguar, Toucan, Snake, Adventurer (only Monkey exists)
- [ ] Character sprite sheets — Run, jump, slide, death animations per character
- [ ] Environment transitions — River, Cave, Temple (only Forest exists)
- [ ] Progressive difficulty — Speed increase curve + obstacle variety scaling
- [ ] Polish obstacle variety — More obstacle types beyond log/vine/gap
- [ ] Death animation — Player death visual feedback beyond particles

## 🟢 Retention & Engagement
- [x] Daily rewards system — 7-day calendar popup with claim animations ✅
- [x] Missions system — 3 active, 8 types, difficulty scaling, progress tracking ✅
- [ ] Global leaderboard — Google Play Games integration
- [ ] Achievement system — Milestones, first kills, etc.

## 💰 Monetization
- [x] AdMob integration — Interstitial, rewarded video, banner (scaffolded)
- [ ] Ad mediation — Meta, Unity, InMobi alongside AdMob
- [ ] Native ads — Pause screen ad placement
- [ ] IAP — Remove ads pack, coin packs
- [ ] Firebase Analytics — Event tracking for tROAS
- [ ] Ad revenue tracking → Firebase → Google Ads campaign

## 🎨 Art & Audio
- [x] Replace placeholder sprites with final art — Jungle pack integrated ✅
- [x] Parallax background art — 5 jungle layers with aspect-ratio fix ✅
- [x] Character art — All 5 skins from Pixel Adventure pack ✅
- [x] Ground tile — Jungle-themed teal/green tile ✅
- [ ] Obstacle art — Polished jungle-themed sprites
- [ ] UI art — Buttons, cards, icons
- [ ] Sound effects — Jump, slide, death, coin, power-up
- [ ] Background music — Per environment

## 📱 Platform & Distribution
- [ ] Create GitHub repo
- [ ] App icon + store screenshots
- [ ] Play Store listing
- [ ] Google Ads campaign setup
- [ ] Content rating setup (Mature audience for higher CPM)
- [ ] Privacy policy page

## ✅ Completed
- [x] Core game scaffolded (Flame engine, 18 Dart files)
- [x] Player mechanics — Jump, double jump, slide
- [x] Ground scrolling
- [x] Parallax background (5 layers)
- [x] Obstacle system — Log, Vine, Gap
- [x] Coin collection + floating +1 animation
- [x] Power-ups — Shield, Magnet
- [x] Particle effects — Dust, coin burst, death explosion, power-up burst
- [x] Screen shake on death
- [x] HUD — Frosted glass, animated score, power-up timers
- [x] Game over screen — Confetti, stats, continue/restart
- [x] Pause system with 3-2-1 countdown resume
- [x] Splash screen with animations
- [x] Main menu with glass cards
- [x] Shop with character carousel
- [x] Settings screen with toggles
- [x] Tutorial overlay (first-time)
- [x] Collision hitbox tuning (25% player shrink, 18% obstacle shrink)
- [x] Swipe detection fix (onVerticalDragEnd)
- [x] Audio stop on game over fix
- [x] AdMob service scaffolded
- [x] Storage service (SharedPreferences)
- [x] Design system (colors, typography, spacing, gradients)
- [x] Page transitions (slide, fade-scale)

---
*Last updated: 2025-07-12*
