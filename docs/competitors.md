# Competitor and Existing Solution Analysis

> **Module:** Module 2 — Ride Matching & Mobility Analysis  
> **Purpose:** Review existing ride-sharing solutions, campus transport options, and mobility platforms available to Universiti Malaya (UM) students to identify practical gaps that UMPooling addresses.

---

## 1. SAPU — Closed-Community Student Ride Platform

**What it is:** SAPU (originating colloquially from the Malaysian term *kereta sapu* / *prebet sapu*) is a dedicated **peer-to-peer campus ride-sharing and mobility web platform** operating across Malaysian universities including Universiti Malaya (UM), Universiti Utara Malaysia (UUM), and UiTM. Branded as *"The Ride Every Student Knows"* with the slogan *"Your ride, your way. Sapu it and go!"* (#SapuIt).

* **Official Web Platform:** [https://www.sapu-my.com/](https://www.sapu-my.com/)
* **Android Application:** [SAPU on Google Play](https://play.google.com/store/apps/details?id=com.sapu.client)

**How it works:**
* **Institutional / Student Onboarding:** Students access booking portals directly through web landing pages (or scan physical QR codes deployed across campus noticeboards, bus shelters, and residential colleges).
* **Point-to-Point Scheduling:** Passengers select specific campus pickup landmarks (e.g. FSKTM, KK10, LRT Universiti, Pantai Hillpark) and coordinate with student drivers circulating campus loops.
* **Pricing & Direct Peer Economy:** Operates on fixed student-budget fares (typically 20% to 40% cheaper than commercial e-hailing surge rates), settled peer-to-peer between driver and passenger.
* **Safety Options:** Select booking channels feature a "Request Female Driver" preference to provide female students with enhanced comfort during late-night library commutes.

**Strengths:**
* High brand awareness and strong community recognition among UM undergraduates.
* Hyper-localized knowledge of campus gates, shortcuts, residential college entrances, and lecture halls that external GPS often mishandles.
* Substantially lower fares than commercial e-hailing during peak morning hours (8:00 AM – 9:00 AM) and heavy rain.

**Gaps & Limitations Addressed by UMPooling:**
| Problem in SAPU | Operational Detail | UMPooling Solution |
|---|---|---|
| **No automated route matching** | Commuters manually browse lists or submit discrete bookings; no smart matching based on saved routes or overlapping corridors. | Automated route matching with saved frequent routes, origin/destination zone overlap detection (FR2.1, FR2.2). |
| **No environmental / CO2 tracking** | Focuses solely on transit coordination; zero sustainability education or impact measurement. | Point-of-decision CO2 indicators on offers, trip-end carbon summaries, and campus-wide institutional dashboards aligned with **SDG Target 13.3** (FR2.2, FR2.3, FR5.3). |
| **No structured in-ride safety log or SOS** | Relies on informal chat arrangements without real-time emergency broadcast tools. | Persistent trip records (FR4.1), automated SOS dispatch with location payload (FR4.2), and community trust ratings (FR4.3). |
| **No natural-language trip parser** | Users must manually fill multi-step web forms while rushing to class. | Cloud LLM natural-language request parser converting free text into structured bookings (FR5.1). |
| **No ride-pooling aggregation** | Lacks clustering algorithms to group students departing from the same condominium complex. | AI pickup grouping and departure window recommendations for high-density areas like Tiara Damansara or Vista Angkasa (FR5.2). |
| **No institutional integration for UM** | Closed external system; university administration receives zero data on traffic reduction or carbon savings. | Anonymized weekly aggregate reporting for UM Sustainability and Transport units (FR5.3). |

---

## 2. Grab (Grab Group Ride / GrabShare)

**What it is:** Malaysia's primary on-demand commercial e-hailing superapp. Grab revived shared trips through its **Group Ride** feature (*"Kongsi Perjalanan, Kongsi Tambang"*).

* **Official Portal:** [https://www.grab.com/my/transport/](https://www.grab.com/my/transport/)
* **Mobile Apps:** [Grab on Google Play](https://play.google.com/store/apps/details?id=com.grabtaxi.passenger) | [Grab on Apple App Store](https://apps.apple.com/my/app/grab-superapp/id647268330)

**How it works:**
* Proprietary algorithms dynamically pair passengers traveling along overlapping routes into a single vehicle.
* Delivers fare savings of up to ~30–40% compared to standard solo GrabCar rides.

**Relevance & Limitations for UM Commuters:**
* **Surge Pricing:** During peak 8:00 AM lecture hours and torrential afternoon rain, dynamic surge pricing increases fares substantially (e.g. RM15–RM25 for a 3 km ride from Seksyen 17 to FSKTM).
* **Commercial Model:** Professional drivers operating for commercial profit rather than cost-sharing peers.
* **Campus Gate Friction:** External drivers unfamiliar with UM's gated entrances (PJ Gate, KL Gate, Lingkungan Budi) frequently drop students at gates rather than specific faculty blocks.

---

## 3. Riding Pink (Women-Only Ride Sharing)

**What it is:** Malaysia's pioneering dedicated transportation platform exclusively for female passengers and verified female drivers.

* **Official Portal:** [https://ridingpink.com/](https://ridingpink.com/)
* **Mobile Apps:** [Riding Pink on Google Play](https://play.google.com/store/apps/details?id=com.ridingpink.customer) | [Riding Pink on Apple App Store](https://apps.apple.com/my/app/riding-pink/id1162464790)

**How it works:**
* Female commuters schedule recurring rides (e.g. daily campus commutes, school runs) paired exclusively with verified female drivers.
* Operates primarily across the Klang Valley and Petaling Jaya.

**Relevance & Limitations for UM Commuters:**
* Addresses the safety and cultural comfort barrier for female students.
* However, it is an advance-booking, commercial private-hire service with limited instant availability and higher per-ride costs.

---

## 4. Kumpool (Community Bus-Pooling & Feeder Transit)

**What it is:** A Malaysian on-demand shared micro-transit service operating minibuses/vans within localized suburban zones (such as Petaling Jaya, Subang Jaya, and Bangsar South).

* **Official Portal:** [https://kumpool.com.my/](https://kumpool.com.my/)
* **Mobile Apps:** [Kumpool on Google Play](https://play.google.com/store/apps/details?id=com.kumpool.passenger) | [Kumpool on Apple App Store](https://apps.apple.com/my/app/kumpool/id1527780072)

**How it works:**
* Commuters book shared van seats within defined geographic zones using virtual stop points.
* Fixed flat-rate fares (often RM1.00 – RM2.00 per trip).

**Relevance & Limitations for UM Commuters:**
* Serves several neighborhoods near UM (Bangsar South, PJ Old Town, Seksyen 13).
* **Limitations:** Vans only drop passengers at designated perimeter virtual stops (cannot enter internal faculty roads or drop students at specific faculty blocks like FSKTM or Engineering). Schedules can experience congestion delays during morning rush hours.

---

## 5. BlaBlaCar

**What it is:** The global long-distance carpooling platform operating in Europe and expanding into regional intercity networks.

* **Official Portal:** [https://www.blablacar.com/](https://www.blablacar.com/)

**Relevance:**
* Matches drivers and passengers for **intercity** highway commuting (e.g. KL to Penang or Johor Bahru) by splitting petrol and toll fees.
* Not designed for intra-city daily 5 km campus commutes, but provides a proven model for legal non-commercial fuel-cost sharing.

---

## 6. Official UM Campus Shuttle & Transit Trackers

**What it is:** Universiti Malaya's internal campus bus system managed by the UM Transportation Unit, operating free routes connecting residential colleges, faculties, and external feeder points (KL Gateway - Universiti LRT).

* **UM Official Student Portal & App:** [UM Touch on Google Play](https://play.google.com/store/apps/details?id=my.edu.um.umtouch) | [UM Touch on Apple App Store](https://apps.apple.com/my/app/um-touch/id1457850029)
* **Live Campus Bus Tracking:** [BusMalaya iOS App](https://apps.apple.com/my/app/busmalaya/id1457850029) | [Moovit UM Transit Tracker](https://moovitapp.com/)
* **RapidKL Public Feeder Bus (T789, T790):** [MyRapid Pulse Journey Planner](https://myrapid.com.my/bus-mrt-rail-services/pulse-journey-planner/)

**Pain points validated by student surveys:**
* Bus crowding and capacity limits during peak morning hours (8:00 AM – 9:30 AM).
* Infrequent service intervals and delays due to external Federal Highway traffic.
* Missing direct routes to popular off-campus housing (e.g. Tiara Damansara, Seksyen 17, Pacific Star).

---

## Direct Comparison: UMPooling vs. Existing Alternatives

| Feature / Dimension | SAPU (`sapu-my.com`) | Grab Group Ride | Kumpool | Official UM Bus | UMPooling |
|---|---|---|---|---|---|
| **Platform Type** | Closed-community web/app | Commercial e-hailing app | On-demand van pooling | Campus shuttle bus | UM-only peer-to-peer mobile app |
| **Identity Verification** | Student credentials / manual | Public phone/ID | Public phone/ID | Student ID card | Verified `@siswa.um.edu.my` institutional email |
| **Pricing Structure** | Flat / negotiated student rates | Dynamic surge fare | Flat transit fare (RM1–2) | Free | Fuel-cost share capped at fuel rate (non-commercial) |
| **Door-to-Door Faculty Access** | Yes | Yes (often restricted at gate) | No (virtual stops only) | Fixed bus stops only | Yes (faculty block centroids) |
| **Automated Route Matching** | ❌ Manual list browsing | ✅ Dynamic pairing | ✅ Zone aggregation | ❌ Fixed routes | ✅ Radius overlap & departure window (FR2.1, FR2.2) |
| **Saved Frequent Routes** | ❌ | ❌ | ❌ | ❌ | ✅ FR2.1 |
| **Point-of-Decision CO2 Feedback** | ❌ | ❌ | ❌ | ❌ | ✅ Displayed on offers and notifications (FR2.2, FR2.3) |
| **Personal Sustainability Dashboard** | ❌ | ❌ | ❌ | ❌ | ✅ Green Commuter Tier & metrics (FR5.3) |
| **Campus-Wide Impact Analytics** | ❌ | ❌ | ❌ | ❌ | ✅ Anonymized view for UM admin (FR5.3) |
| **In-Ride Emergency SOS** | ❌ | ✅ In-app button | ❌ | ❌ | ✅ Pre-filled dispatch to UM Security / contacts (FR4.2) |
| **AI Request Parser** | ❌ | ❌ | ❌ | ❌ | ✅ Cloud LLM natural-language parser (FR5.1) |

---

## Strategic Value Proposition for the Project Report
While SAPU demonstrates that strong student demand exists for campus-specific ride-sharing, UMPooling elevates the concept from an informal booking tool into an **intelligent, climate-aligned campus mobility system**:
1. **Intelligent Dispatch:** Automating route overlap matching so drivers and passengers heading along the same corridor connect seamlessly.
2. **SDG Target 13.3 Alignment:** Embedding carbon feedback directly into daily commuting choices to raise climate awareness and quantify emissions avoided.
3. **Institutional Accountability:** Providing verified institutional email authentication and aggregate sustainability metrics for university administration.
