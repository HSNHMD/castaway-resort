# Castaway Resort — Game Design Document

*Working title. A castaway-to-empire island resort tycoon, grounded in real Maldivian operations.*

Status: core loop and challenge systems validated in HTML prototype (v2). This doc captures the validated design plus the systems still to build, and the path from prototype to shippable game.

---

## 1. Concept & pillars

You wash up alone on an uninhabited island in the northern atolls with no money. You forage palm leaves and branches to lash together your first hut, draw in your first backpacker off a passing dhoni, and reinvest every rufiyaa into a slowly growing resort — until planes land on your own airstrip.

Three pillars hold the whole design up. Break one and it stops being this game:

1. **Rags to empire.** The game *starts* with nothing — no cash, only labour and foliage. The bootstrap is short but it's the emotional hook almost no tycoon game has. The arc from "lashing palm leaves" to "fly-in luxury" is the promise.
2. **Authentic Maldivian operations.** Jetties, dhonis, desalination, generators vs solar, monsoon storms, FENAKA-style power constraints. The texture is the differentiator — generic "island resort" builders get none of this right. This is the unfair advantage.
3. **Expansion is a liability, not just a reward.** Every room you add loads power, water, and staff. Grow faster than your infrastructure and the reviews bury you. Caution is the skill.

The game is secretly two games joined by a transition: a short **survival bootstrap** (currency = labour + foliage) and a longer **operations tycoon** (currency = money + reputation). The handoff — your first paying guest — is the most important moment in the game.

---

## 2. Core loop (validated)

```
Forage materials ─► Build hut (no money) ─► Guest arrives ─► Earn money
        ▲                                                        │
        │                                                        ▼
   Keep systems covered ◄── Reinvest: rooms · infra · staff ◄────┘
```

The compounding spend → capacity → earn → reinvest loop is classic and proven. What keeps it from going stale (the failure mode of every idle tycoon) is the **second axis of pressure**: you're never just choosing *what to build next*, you're choosing whether you can afford to run what you already have.

---

## 3. Systems

### 3.1 Economy

**Currencies**

| Currency | Source | Role |
|---|---|---|
| 🌿 Leaves / 🪵 Branches | Foraging (labour) | Bootstrap build material; ongoing cost for huts/restaurant |
| 💰 Rufiyaa | Occupied rooms | Main economy |
| ⭐ Rating (0–5) | Guest satisfaction over time | **Gates guest tier and demand. Can fall.** |

**Income** = sum of occupied room rates (+ restaurant bonus per occupied room), modulated by satisfaction. Validated rates: hut 8 / bungalow 26 / villa 85 per night.

**The money sinks** (the thing that makes you able to lose) — charged every day, occupied or not:

- **Wages** — each staff member costs ~12/day.
- **Upkeep** — per building, every day.
- **Fuel** — diesel generators burn fuel daily; solar doesn't.
- **Storm repairs** — event-driven lump sums.
- **Refunds / walkouts** — furious guests leave without paying.

Build cost scales ~1.3–1.4× per copy of a building, so you're always nudged toward the next tier rather than spamming the cheapest unit. A daily **net** readout (green/red) keeps profitability legible.

### 3.2 Capacity systems — the core challenge (validated)

Three load-vs-capacity systems, each shown as a live gauge. Coverage = capacity ÷ load. Below 1.0, the system generates complaints and drags satisfaction.

| System | Capacity from | Load from | Notes |
|---|---|---|---|
| 🛎️ Staff | Hires (×4 rooms each) + base 2 | All built rooms | Cleaning/service |
| ⚡ Power | Generators (+6) / Solar (+10) + base 2 | Bungalows + villas | **Huts are off-grid** — keeps the bootstrap forgiving |
| 💧 Water | Desalination (+8) + base 4 | Occupied guests | Fresh water is scarce |

The base buffers mean the early castaway phase doesn't punish you; the pressure ramps only as you scale past them. This phasing is deliberate — it teaches the systems gently, then makes them bite.

### 3.3 Satisfaction & reputation (validated)

Satisfaction (0–100) starts at 100 and is docked for each under-covered system (staff hits hardest), for active storm damage, and is lifted by amenities like the restaurant. **Rating drifts toward satisfaction** each day rather than snapping — so neglect bleeds your rating down over a week or so, and recovery takes similar time. Low rating cuts demand, which cuts income, while costs keep running: the spiral that punishes reckless expansion. Rating gates guest tiers (bungalow guests at ⭐1.5, villas at ⭐3, airstrip at ⭐3.5).

### 3.4 Guest reviews / Guestbook (validated)

The live feed is the player's primary diagnostic surface — it makes hidden state legible. Complaints name the exact failing system ("AC died at 2am," "tap ran dry before dinner," "waited 40 minutes at the desk"); praise appears when you run a tight ship. The player should be able to read the feed and know what to fix without staring at gauges.

### 3.5 Events (partially built)

- 🌀 **Monsoon storm** *(built)* — guests flee, buildings take damage, a repair cost sits on the island until paid. Rating dips.
- ✨ **Gone viral / travel blogger** *(built)* — rating bump + multi-day booking surge.
- ⚙️ **Generator breakdown** *(to add)* — power drops until repaired; pure incentive to diversify to solar.
- 🦟 **Health/sanitation inspection** *(to add)* — fine if upkeep/waste neglected.
- 🐠 **Peak season / regatta** *(to add)* — temporary demand spike that *tempts* over-expansion.

### 3.6 Systems still to design & build

These are the depth-adders flagged during prototyping, in rough priority:

1. **Land & placement (highest impact).** Right now buildings auto-place into fixed slots. The real game wants a constrained, reclaimable island grid where *where* you build matters: villas must be over water, generators are noisy (penalty if next to villas), the restaurant wants to be central, beach frontage is premium. Land reclamation becomes a money sink and a pacing gate. This is the single biggest upgrade to strategic depth.
2. **Guest archetypes with needs, not just tiers.** Backpacker, diver, family, honeymooner, influencer. A diver wants a dive centre + boats; a honeymooner wants privacy and pays a premium for it; an influencer can swing your rating hard either way. Matching supply to who's arriving becomes a real decision.
3. **Excursions & boats.** Dhonis and speedboats as buildable assets that unlock dive trips, sandbank picnics, airport transfers — new income streams with their own upkeep and staffing.
4. **Seasons & weather cycle.** A monsoon/dry rhythm so demand and storm risk ebb and flow, rewarding players who build buffers before the bad season.
5. **Waste & environment.** Sanitation as a fourth system; an eco-rating that luxury guests care about (and that rewards solar over diesel).
6. **Save/load & progression meta.** Persistent islands, maybe multiple islands later.

---

## 4. Progression tiers

The whole arc, each tier gated by rating and unlocking a new guest class:

1. **Castaway** — forage, build first hut by hand. No money. *(minutes)*
2. **Backpacker beach** — cheap huts, first cash, jetty for arrivals.
3. **Mid-range** *(⭐1.5)* — bungalows, restaurant, first real infrastructure pressure (power/water start mattering).
4. **Luxury** *(⭐3)* — over-water villas, heavy systems load, big margins if run well.
5. **Fly-in resort** *(⭐3.5)* — the airstrip. The win-state and a soft "endless mode" anchor.

---

## 5. Failure & difficulty

There's no hard game-over in the prototype; the *spiral* is the punishment. Cash crunch → can't make payroll → staff quit → service collapses → complaints → rating falls → demand falls → deeper cash crunch. It's recoverable but scary, which is the right texture for a builder game. A later difficulty setting could add a true bankruptcy lose-condition. **Open question:** is the spiral currently too forgiving (no real stakes) or about right? Worth playtesting before adding a hard fail.

---

## 6. Art direction & UX

- **Look:** stylized illustrated top-down, *not* photoreal. Layered reef → lagoon → shallows → sand water bands, organic coastline, warm low sun. Drawn structures (thatched huts with lit windows when occupied, stilted villas, tilted solar panels, a jetty with a moored boat) rather than icons.
- **Palette:** ocean #063047, lagoon #2ec4b6, sand #f1deac, gold accent #ffb02e, coral warning #ff5d5d, success #28b487. Friendly rounded display type (Fredoka) over a clean UI face (Inter).
- **Mobile-first.** Sticky resource bar, the island as the hero, gauges + Guestbook as the always-visible "state of the resort," tabbed build menu. Big tap targets, the forage button as the prominent early action.
- **Juice:** building pop-in, floating income numbers, occupied-window glow, slide-in reviews, gentle water shimmer. Respect reduced-motion.

True photoreal/3D is out of scope for the style and the medium — that's a deliberate choice, not a limitation to apologize for. Stylized ages better and reads instantly on a phone.

---

## 7. From prototype to game — build roadmap

The HTML prototype has done its job: it proves the loop and the challenge are fun, and it's a working spec for the economy. The next decision is the engine.

**Engine recommendation: Godot 4.**
- Free, open-source, excellent 2D, one-click export to web *and* mobile *and* desktop.
- Scene/node model fits a tycoon game cleanly; TileMap is built for the land/placement system that's the biggest depth upgrade.
- GDScript is concise and very friendly to Claude Code / agentic workflows — it suits how you build.

**Alternative: Phaser 3 (stay in JS).** If you'd rather keep momentum, Phaser lets you port v2's economy logic almost directly — same language, same mental model, pure web. Faster to a richer prototype; weaker on native mobile and long-term tooling than Godot. Honest trade: Phaser is the fastest *next step*, Godot is the better *destination*.

**Phased plan (engine-agnostic):**

- **Phase A — Port the validated core.** Rebuild the v2 economy, three capacity systems, satisfaction/rating, and Guestbook in the chosen engine. No new features — just get the proven loop running natively with save/load.
- **Phase B — Land & placement.** Replace fixed slots with a real island grid: zoning (over-water vs beach vs interior), adjacency effects, land reclamation as a pacing gate. *This is where the game gets genuinely strategic.*
- **Phase C — Guest archetypes & excursions.** Distinct guest needs, boats/dive centre, new income streams.
- **Phase D — Seasons, full event deck, waste/eco system, difficulty modes.**
- **Phase E — Polish:** audio, tutorial, art pass, balancing, soft-launch build.

**Reuse from the prototype:** every tuned number (rates, scaling, coverage weights, drift rate, demand formula) transfers directly — that balancing work is already banked.

---

## 8. Open design questions

- Does the failure spiral feel *fair and diagnosable* — can the player always tell what to fix? (Feed is meant to ensure yes.)
- Is the storm too punishing or about right?
- Should the bootstrap be even shorter, or does a slightly longer "stranded" phase build attachment?
- Does the economy need a hard lose-condition, or is the spiral enough stakes?
- How much should placement/adjacency matter before it becomes fiddly on a phone?
