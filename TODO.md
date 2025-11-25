# PLAN IMPLEMENTACJI: PRISON TYCOON

## Przegląd projektu
Prison Tycoon to mobilna gra symulacyjna typu management sim, gdzie gracz buduje i zarządza więzieniem. Projekt inspirowany Prison Architect, z kompleksowymi systemami ekonomii, AI więźniów, personelu i kryzysów.

**Szacowany czas MVP: 20 tygodni (full-time) lub 8-12 miesięcy (part-time)**

---

## FAZA 0: PRZYGOTOWANIE PROJEKTU ✅ UKOŃCZONA
**Czas: 1-2 dni | Priorytet: KRYTYCZNY**

### Struktura katalogów ✅
- [x] Utworzenie pełnej hierarchii folderów: assets/, scenes/, scripts/, data/
- [x] Podkatalogi: sprites, tilesets, audio, UI, buildings, entities
- [x] Organizacja zgodna z konwencją Godot

### Konfiguracja Godot ✅
- [x] Ustawienie rozdzielczości i orientacji mobile (landscape/portrait)
- [x] Konfiguracja input map dla touch gestures
- [x] Setup autoload singletons (GameManager, EconomyManager, etc.)
- [x] Konfiguracja layerów collision i renderowania

### Dokumentacja techniczna ✅
- [x] CLAUDE.md z architekturą systemów
- [x] Lista sygnałów (events) między komponentami (signals.gd)
- [x] Definicje enumów i stałych (enums.gd, constants.gd)
- [x] Konwencje nazewnictwa

### Dodatkowe (Mobile UI) ✅
- [x] SafeAreaContainer dla notchy/gesture bar
- [x] Responsywny theme z touch-friendly przyciskami
- [x] Pinch-to-zoom i multi-touch pan

---

## FAZA 1: FUNDAMENT - CORE SYSTEMS ✅ UKOŃCZONA
**Czas: 3-4 tygodnie | Priorytet: KRYTYCZNY**

### 1.1 GameManager (Singleton) ✅
- [x] Zarządzanie stanem gry (menu, gameplay, pauza)
- [x] System czasu in-game (dzień, godzina, minuty)
- [x] Prędkość gry (x1, x2, x4, pauza)
- [x] Save/Load system (JSON serialization) - SaveManager
- [x] Przełączanie scen i stanów

### 1.2 Sistema siatki i TileMap ✅
- [x] TileMap dla ścian, podłóg, terenu - GridManager z programowym TileSet
- [x] Grid-based positioning (wszystko na siatce 1x1) - w BuildingManager
- [x] Konwersja współrzędnych: world ↔ grid - w GameManager i GridManager
- [x] Funkcje pomocnicze: is_cell_occupied(), get_cells_in_rect() - w BuildingManager

### 1.3 Podstawowy system nawigacji ✅
- [x] NavigationRegion2D dla całego więzienia - NavigationManager (uproszczony)
- [x] Pathfinding A* - find_path(), is_point_reachable() via NavigationServer2D
- [x] Obsługa przeszkód - walkable cache w GridManager
- [ ] TODO: Rozbudować nawigację gdy pojawią się więźniowie (Faza 4)

### 1.4 Kamera i sterowanie mobile ✅
- [x] Camera2D z limitami obszaru
- [x] Touch gestures: drag (pan), pinch (zoom)
- [x] Zoom constraints (min/max levels)
- [x] Smooth interpolation
- [x] Double tap dla centrowania na obiekcie - z animacją i zoom-in

### 1.5 Podstawowy HUD ✅
- [x] Górny bar: logo, dzień, pause/speed, settings
- [x] Status bar: kapitał, liczba więźniów, reputacja
- [x] Dolne menu z ikonami kategorii
- [x] Placeholder dla alertów (AlertBadge)

---

## FAZA 2: SYSTEM BUDOWANIA ✅ UKOŃCZONA
**Czas: 2-3 tygodnie | Priorytet: KRYTYCZNY**

### 2.1 BuildingManager (Singleton) ✅
- [x] Katalog wszystkich typów budynków (loaded from JSON) - buildings.json
- [x] Funkcje: can_build(), place_building(), remove_building()
- [x] Walidacja: kolizje, budżet, wymagania techniczne
- [x] Integracja z EconomyManager dla kosztów

### 2.2 Building Base Class ✅
- [x] Area2D jako bazowa klasa - scripts/buildings/building.gd
- [x] Właściwości: type, size, cost, capacity, effects
- [x] Wykrywanie wejścia/wyjścia więźniów (sygnały)
- [x] Sprite rendering dopasowany do tile size (ColorRect placeholder)
- [x] Funkcja destroy() w BuildingManager.remove_building()

### 2.3 Podstawowe typy budynków (24 zdefiniowane w JSON) ✅
- [x] **Cell**: pojedyncza/podwójna/dormitorium/luksusowa/izolatka
- [x] **Canteen**: kantyna (eating satisfaction)
- [x] **Kitchen**: kuchnia (produkcja posiłków)
- [x] **Yard**: podwórko (freedom satisfaction)
- [x] **Workshop**: warsztat stolarski, pralnia, ogród, call center
- [x] Rekreacja: siłownia, biblioteka, kaplica, sala TV
- [x] Infrastruktura: ambulatorium, posterunek, recepcja, magazyn, prysznice
- [x] Bezpieczeństwo: kamery, detektory, alarmy, wieże, checkpointy

### 2.4 Build Mode UI ✅
- [x] Panel wyboru budynków z kategoriami - scenes/ui/build_menu.tscn
- [x] Ghost preview podczas umieszczania - scenes/buildings/build_ghost.tscn
- [x] Walidacja wizualna (zielony = OK, czerwony = błąd)
- [x] Wyświetlanie kosztu w czasie rzeczywistym
- [x] BuildModeController - scripts/controllers/build_mode_controller.gd
- [ ] TODO: Drag to create rectangle dla większych pomieszczeń (post-MVP)

### 2.5 Ściany i drzwi ✅
- [x] 4 typy ścian (drewno, cegła, beton, stal) - w GridManager
- [x] Auto-walls przy umieszczaniu budynków wewnętrznych
- [x] System drzwi (DoorData, open/close/lock/unlock)
- [x] Kolizje dla pathfindingu (walkable_cache)
- [x] Wytrzymałość ścian (WALL_DURABILITY dla mechaniki ucieczek)
- [ ] TODO: UI do ręcznego umieszczania ścian/drzwi (post-MVP)

---

## FAZA 3: EKONOMIA ✅ UKOŃCZONA
**Czas: 1-2 tygodnie | Priorytet: KRYTYCZNY**

### 3.1 EconomyManager (Singleton) ✅
- [x] Kapitał (current money)
- [x] Tracking: revenue streams (źródła przychodów)
- [x] Tracking: expenses (kategorie wydatków)
- [x] Obliczanie daily balance
- [x] Timer: update ekonomii co 60s in-game (1 godzina)

### 3.2 Revenue system (przychody) ✅
- [x] Subwencja za więźnia (zależna od kategorii bezpieczeństwa)
- [x] Praca więźniów (produkcja w warsztatach)
- [ ] Kontrakty rządowe (milestone rewards) - post-MVP
- [ ] Bonusy za bezpieczeństwo i zero incydentów - post-MVP

### 3.3 Expense system (wydatki) ✅
- [x] Pensje personelu (daily per staff member)
- [x] Jedzenie (per prisoner per day)
- [x] Media: energia i woda (based on prison size)
- [x] Koszty budowy (one-time)
- [ ] Naprawy po zniszczeniach - post-MVP

### 3.4 Bankructwo i pożyczki ✅
- [x] Detekcja: kapitał < 0 przez 7 dni
- [x] Emergency loan system ($20,000 + 10% interest)
- [x] Game over condition jeśli brak rozwiązań

### 3.5 Economy UI Panel ✅
- [x] Szczegółowy breakdown przychodów i wydatków
- [ ] Wykres 30-dniowy (trend finansowy) - post-MVP
- [x] Predykcja daily balance
- [x] Alerty przy niskim kapitale (<$5,000)

---

## FAZA 4: WIĘŹNIOWIE - PODSTAWY ✅ UKOŃCZONA
**Czas: 3-4 tygodnie | Priorytet: KRYTYCZNY**

### 4.1 Prisoner Class (CharacterBody2D) ✅
- [x] **Identyfikacja**: name, ID, age, crime, sentence length
- [x] **Kategoria**: low/medium/high/maximum security
- [x] **Needs**: hunger, sleep, hygiene, freedom, safety, entertainment (0-100%)
- [x] **Traits**: array cech charakteru (pracowity, agresywny, inteligentny, etc.)
- [x] **Status**: health, mood, current location, current activity

### 4.2 System potrzeb (Needs System) ✅
- [x] Timer update co 1 sekundę dla wszystkich prisoners
- [x] Każda potrzeba degraduje według określonego rate
- [x] Satisfaction przez aktywności (np. eating → hunger +30%)
- [x] Thresholds: <30% warning, <10% crisis
- [x] Wpływ potrzeb na obliczanie mood

### 4.3 Prisoner AI - State Machine ✅
- [x] **Stany**: Idle, Walking, Working, Eating, Sleeping, Recreation, Fighting, Escaping
- [x] **Przejścia schedule-driven**: według harmonogramu dnia
- [x] **Przejścia need-driven**: głód → szukaj jedzenia
- [x] **Przejścia event-driven**: alarm → powrót do celi
- [x] Decision logic: priorytetyzacja potrzeb

### 4.4 Pathfinding integration ✅
- [x] NavigationAgent2D dla każdego więźnia
- [x] Target selection z ScheduleManager
- [x] Obstacle avoidance (inne postaci, ściany)
- [ ] Obsługa zablokowanych drzwi - post-MVP
- [ ] Queue system dla popularnych miejsc (kolejka do jedzenia) - post-MVP

### 4.5 Generowanie więźniów ✅
- [x] Proceduralne: losowe imię, wiek (18-65), wyrok, przestępstwo
- [x] Przypisanie kategorii (weighted random based on settings)
- [x] Przypisanie 1-3 losowych cech
- [x] Initial spawn location: reception building
- [x] Auto-przypisanie do wolnej celi

### 4.6 Kategorie zagrożenia (Security Categories) ✅
- [x] **Low Security** (niebieski): subsidy $500, risk 10%
- [x] **Medium Security** (pomarańczowy): subsidy $800, risk 30%
- [x] **High Security** (czerwony): subsidy $1000, risk 60%
- [x] **Maximum Security** (czarny): subsidy $1200, risk 90%
- [x] Różne wymagania nadzoru i bezpieczeństwa

---

## FAZA 5: HARMONOGRAM ✅ UKOŃCZONA
**Czas: 1-2 tygodnie | Priorytet: WYSOKI**

### 5.1 ScheduleManager (Singleton) ✅
- [x] Oddzielny harmonogram dla każdej kategorii więźniów
- [x] Format: Dict[kategoria][godzina] = aktywność
- [x] Domyślne harmonogramy (w kodzie)
- [x] Custom rules i override (np. godzina policyjna)
- [x] Sygnały: schedule_changed, lockdown_started

### 5.2 Typy aktywności ✅
- [x] **Sleep**: lockdown w celach (22:00-06:00)
- [x] **Eating**: kierowanie do kantyny (07:00, 12:00, 18:00)
- [x] **Hygiene**: prysznice (06:30, 20:00)
- [x] **Work**: warsztaty produkcyjne (09:00-12:00, 13:00-17:00)
- [x] **Recreation**: podwórko, siłownia, biblioteka
- [x] **Free time**: cells open, socjalizacja

### 5.3 Schedule UI Panel ✅
- [x] Tabela: godzina | aktywność | miejsce
- [x] Dropdown wyboru kategorii więźniów
- [x] Edycja: kliknięcie → wybór aktywności z listy
- [x] Template system: kopiuj harmonogram między kategoriami
- [x] Reset do domyślnego

### 5.4 Lockdown mode ✅
- [x] Ręczna aktywacja lub automatyczna (podczas kryzysu)
- [x] Wszyscy więźniowie → natychmiastowy powrót do cel
- [x] Override całego harmonogramu
- [ ] Mood penalty: -5% per dzień lockdownu - post-MVP
- [ ] Zwiększone koszty (jedzenie na tacach +50%) - post-MVP
- [x] Unlock command

---

## FAZA 6: PERSONEL ✅ UKOŃCZONA
**Czas: 2-3 tygodnie | Priorytet: WYSOKI**

### 6.1 Staff Base Class ✅
- [x] **Właściwości**: type, name, salary (daily), shift (1/2/3)
- [x] **Morale**: 0-100% (wpływa na efektywność)
- [x] **Skills/trainings**: array ukończonych szkoleń
- [x] **Current task**: patrol / respond / rest

### 6.2 Guard (Strażnik) - priorytet ✅
- [x] **State machine**: Patrolling, Responding, Pacifying, Resting
- [x] Patrol routes (waypoints do obchodzenia)
- [x] Response to fights (automatyczny w zasięgu)
- [x] Area2D detection range (8 tiles)
- [x] Pacification mechanics (30s per 2 prisoners)
- [ ] Upgrades: taser, walka wręcz, psy służbowe - post-MVP

### 6.3 Pozostałe typy personelu (struktura przygotowana) ✅
- [x] **Medic**: healing w ambulatorium - podstawowa struktura
- [x] **Cook**: produkcja w kuchni - podstawowa struktura
- [x] **Psychologist**: therapy sessions - podstawowa struktura
- [x] **Janitor**: sprzątanie - podstawowa struktura
- [x] **Priest**: chapel services - podstawowa struktura

### 6.4 Shift system (zmiany) ✅
- [x] **3 zmiany**: 06:00-14:00, 14:00-22:00, 22:00-06:00
- [x] Automatyczna rotacja personelu
- [x] Night shift bonus (+20% do salary)
- [ ] Fatigue tracking (zmęczenie wpływa na performance) - post-MVP
- [ ] Rest requirement (posterunek) - post-MVP

### 6.5 Staff morale ✅
- [x] **Czynniki obniżające**: nadgodziny, incydenty, śmierć kolegi, brak odpoczynku
- [x] **Skutki**: <50% efektywność -20%, <30% ryzyko odejścia
- [ ] **Poprawa**: posterunek wypoczynkowy, premie, szkolenia - post-MVP

### 6.6 Hiring UI ✅
- [x] Panel rekrutacji per typ personelu
- [x] Lista current staff: imię, zmiana, morale bar
- [x] Przyciski: Hire / Fire
- [x] Cost preview (daily)
- [ ] Training options (unlock po osiągnięciach) - post-MVP

---

## FAZA 7: KRYZYSY - PODSTAWOWE ✅ UKOŃCZONA
**Czas: 2-3 tygodnie | Priorytet: WYSOKI**

### 7.1 EventManager (Singleton) ✅
- [x] Kolejka aktywnych eventów
- [x] Checking trigger conditions co 5 sekund
- [x] Alert system integration
- [x] Crisis state management (normal/crisis/emergency)
- [x] Event resolution tracking

### 7.2 Bójki (Fights) ✅
- [x] **FightSystem** - Autoload singleton zarządzający bójkami
- [x] **Trigger conditions**: need <30% (safety/hunger), trait "agresywny" + brak guard
- [x] **Mechanika**: Fighting state, damage 2 HP/s, escalation (inni dołączają w zasięgu 3 tiles)
- [x] **Guard response**: auto w zasięgu 8 tiles, pacification 30s/2 prisoners
- [x] **Aftermath**: ranni → ambulatorium (po health <50%), agresorzy → izolatka
- [x] **Sygnały**: fight_started, fight_ended, prisoner_pacified

### 7.3 Ucieczki (Escapes) ✅
- [x] **EscapeSystem** - Autoload singleton zarządzający ucieczkami
- [x] **Trigger**: need freedom <30% + trait "zbieg" + niska obecność strażników
- [x] **Route calculation**: wybór najlepszego punktu ucieczki (krawędź mapy)
- [x] **Detection system**: strażnicy wykrywają uciekających w zasięgu
- [x] **Guard chase**: automatyczne wysyłanie strażników do pościgu
- [x] **Skutki ucieczki**: -$5,000 kara, usunięcie więźnia z gry
- [x] **Inteligentni więźniowie**: omijają patrolowane obszary

### 7.4 Kontrabanda ✅
- [x] **ContrabandSystem** - Autoload singleton zarządzający kontrabandą
- [x] **Mechanika**: 5% szansa/interwał/więzień na zdobycie
- [x] **Typy**: telefon, narkotyki, nóż, alkohol, narzędzia (do ucieczki)
- [x] **Efekty na potrzeby**: telefon → entertainment, nóż → safety, etc.
- [x] **Detection methods**: manual search 60%, metal detector 80%, dog 90% (narkotyki)
- [x] **Snitch system**: kapusie donoszą na innych więźniów
- [x] **Zapobieganie**: regularne rewizje, eventy wykrycia

### 7.5 Alert System UI ✅
- [x] **AlertPanel** - Panel UI z listą alertów
- [x] **4 priorytety**: krytyczny (czerwony), ważny (pomarańczowy), info (żółty), pozytywny (zielony)
- [x] **Filtrowanie**: dropdown do filtrowania alertów po priorytecie
- [x] Quick actions: Zobacz (focus camera), Zamknij (dismiss)
- [x] Lista aktywnych alertów z timestampem
- [x] Auto-show panel przy alertach krytycznych

---

## FAZA 8: KRYZYSY - ZAAWANSOWANE
**Czas: 2 tygodnie | Priorytet: ŚREDNI (post-MVP)**

### 8.1 Bunty (Riots)
- **Trigger conditions**: >50% prisoners mood <30%, lider gangu, brutal pacification, prolonged lockdown
- **Fazy**: Tension building (wskaźnik 0-100%, warning 24-48h) → Start → Escalation → Peak
- **Mechanika**: 10-30 prisoners refuse orders → niszczenie → +5 participants/min → hostages
- **Rozwiązania**: SWAT (siłowe, $10k, 30min), Negocjacje (psycholog, 1-3h), Kapitulacja
- **Skutki**: zniszczenia ($10k-100k), casualties, staff morale -50%, reputacja -1 gwiazdka, śledztwo

### 8.2 Epidemia
- **Trigger**: higiena średnia <40% przez 14 dni, brak ambulatorium, overcrowding >120%
- **Mechanika**: Patient zero → spread +2/dzień w tym samym pomieszczeniu
- **Symptoms**: -50% health, -30% productivity, sick mood
- **Resolution**: kwarantanna (izolacja), medycy (6h/osoba), sprzątaczki prevention
- **Mortality**: 10% jeśli bez leczenia

### 8.3 Gang System
- **Formowanie**: automatyczne po 30 dniach wspólnego pobytu
- **4 typy**: Bractwo, Mafia, Bandyci, Polityczni (różne style)
- **Struktura**: Lider (najsilniejszy) + członkowie (lojalność 0-100%)
- **Aktywności**: rekrutacja, rywalizacja o terytorium (kantyna, podwórko), coordinated attacks
- **Bójki międzygangowe**: większe, groźniejsze, większa eskalacja
- **Przeciwdziałanie**: izolacja liderów, mixing prevention, rehabilitacja

---

## FAZA 9: PROGRESJA I REPUTACJA
**Czas: 1-2 tygodnie | Priorytet: ŚREDNI**

### 9.1 Reputation System (gwiazdki)
- **5 poziomów**: 1-5 ⭐ (progresywnie trudniejsze)
- **Kryteria cumulative**: bezpieczeństwo (0 ucieczek, <10 bójek/miesiąc), warunki (nastrój >60%), rehabilitacja (programy aktywne), finanse (zysk dodatni)
- **Wpływ**: subwencja +10% do +100%, dostęp do groźnych więźniów, kontrakty premium
- **Utrata gwiazdek**: poważne incydenty (ucieczka -0.5, bunt -1, śmierć -0.5)

### 9.2 Kontrakty rządowe
- **Mechanika**: 1 nowy kontrakt/miesiąc (oferta)
- **Typy zadań**: 0 ucieczek przez 60 dni, nastrój >70%, rehabilitacja 20 prisoners, rozbudowa do X
- **Rewards**: $5,000-$15,000 (zależnie od trudności)
- **Brak kary** za failure (tylko brak nagrody)
- **Tracking UI**: progress bar w panelu kontraktów

### 9.3 Achievement System
- **10+ osiągnięć**: milestone-based (100 dni bez śmierci, pacyfikacja 5 buntów, 5⭐, 1000 prisoners total)
- **Rewards**: skiny budynków/uniformów, bonusy finansowe ($5k-$10k), unlock tryby gry
- **Integracja mobile**: Google Play Games, iOS Game Center
- **UI**: lista osiągnięć (locked/unlocked), progress tracking

### 9.4 Unlock System
- **Progresywne odblokowywanie**: budynki (tier 1 → 2 → 3), kategorie więźniów (low → max), szkolenia personelu, tryby gry
- **Warunki**: gwiazdki, osiągnięcia, kampania progress
- **Visual feedback**: ikony locked z wymaganiami

---

## FAZA 10: INTERFEJS UŻYTKOWNIKA
**Czas: 2-3 tygodnie | Priorytet: WYSOKI**

### 10.1 Main HUD (częściowo w Fazie 1)
- **Górny bar**: logo, dzień/godzina, pause/speed controls (x1/x2/x4), settings
- **Status bar**: kapitał ($), prisoners (current/max), reputacja (⭐), alert count
- **Dolne menu**: ikony kategorii (Build, Prisoners, Schedule, Staff, Stats, Alerts)
- **Minimap**: prawy górny róg, zoom indicators

### 10.2 Build Menu Panel
- **Kategorie tabs**: Pomieszczenia, Przedmioty, Bezpieczeństwo, Infrastruktura
- **Lista budynków**: scroll, ikona, nazwa, rozmiar (XxY), koszt ($), pojemność
- **Preview**: większa ikona po najechaniu
- **Button**: Buduj (otwiera build mode z ghost preview)
- **Filters**: unlocked/locked toggle

### 10.3 Prisoner Panel (po kliknięciu więźnia)
- **Header**: imię, ID, wiek, wyrok (lat pozostało), kategoria (color-coded)
- **Potrzeby**: 6 progress bars (hunger, sleep, hygiene, freedom, safety, entertainment)
- **Status**: zdrowie (HP bar), nastrój (emoji + %), location
- **Cechy**: lista traits z ikonami
- **Dodatkowe info**: gang affiliation, work assignment, cell number
- **Akcje**: Przenieś do celi, Izolatka, Historia zdarzeń

### 10.4 Schedule Panel
- **Dropdown**: wybór kategorii więźniów (low/medium/high/max)
- **Tabela 24h**: godzina | aktywność | miejsce (ikona budynku)
- **Edycja**: kliknięcie bloku → dropdown z dostępnymi aktywnościami
- **Templates**: Kopiuj z innej kategorii, Reset do domyślnego
- **Preview**: wpływ na potrzeby (visual indicators)

### 10.5 Staff Panel
- **Tabs**: Strażnicy, Medycy, Kucharze, Inni
- **Lista current staff**: imię, zmiana (1/2/3), morale (progress bar), szkolenia (ikony)
- **Akcje per staff**: Szczegóły (popup), Zwolnij (confirmation)
- **Hire new**: button z typem personelu, koszt preview (daily + monthly)
- **Summary**: total staff count, total monthly cost

### 10.6 Stats Panel
- **Tab Finanse**: current balance, bilans dzienny, wykres 30-dni (line chart), breakdown table
- **Tab Bezpieczeństwo**: liczba bójek/ucieczek/incydentów (month), trend arrows
- **Tab Więźniowie**: nastrój średni (gauge), potrzeby średnie (radar chart), demografia (kategorie pie chart)
- **Tab Budynki**: lista z capacity/current occupancy

### 10.7 Alerts Panel
- **Lista aktywnych**: sorted by priority (krytyczny → info)
- **Toast notifications**: popup na górze (auto-hide po 5s)
- **Ikona z licznikiem** w status bar
- **Color-coding**: czerwony/pomarańczowy/żółty/zielony
- **Quick actions**: Zobacz (camera focus), Rozwiąż (quick fix), Dismiss

### 10.8 Mobile Gestures Implementation
- **Single finger drag**: pan camera (smooth inertia)
- **Pinch**: zoom in/out (min 0.5x, max 2x)
- **Tap**: select object (prisoner/building/staff)
- **Double tap**: center camera on selection
- **Long press**: context menu (budynek: info/demolish, więzień: info/assign)
- **Swipe up**: expand collapsed panel

---

## FAZA 11: CONTENT - BUDYNKI
**Czas: 1-2 tygodnie | Priorytet: ŚREDNI**

### 11.1 Rozszerzenie typów budynków (20+ total)
- **Cele**: pojedyncza, podwójna, dormitorium (8), luksusowa (2, max security only)
- **Wyżywienie**: kuchnia (ready w Fazie 2), jadalnia/kantyna
- **Rekreacja**: podwórko, siłownia, biblioteka, kaplica, sala TV
- **Praca**: pralnia, warsztat stolarski, ogród warzywny, call center (produkcja revenue)
- **Infrastruktura**: ambulatorium, izolatka, posterunek strażników, recepcja, magazyn, generator
- **Bezpieczeństwo**: CCTV (kamery), detektor metalu, system alarmowy, wieża strażnicza, szlaban

### 11.2 Data-driven approach
- **JSON database**: buildings.json z wszystkimi właściwościami
- **Format**: type, name, category, size (WxH), cost, capacity, effects (Dict), requirements (Dict)
- **Dynamic loading**: BuildingManager wczytuje z pliku
- **Łatwe dodawanie**: nowe budynki bez zmiany kodu (tylko JSON + sprite)

### 11.3 Building effects system
- **Satisfaction effects**: które potrzeby budynek zaspokaja (eating +30% hunger)
- **Production effects**: revenue generation (workshop $50/day per working prisoner)
- **Detection effects**: kamery 40% kontrabanda detection w zasięgu
- **Security effects**: wieża strażnicza +2 range dla guards

---

## FAZA 12: TRYBY GRY
**Czas: 2-3 tygodnie | Priorytet: WYSOKI (kampania), ŚREDNI (sandbox/scenariusze)**

### 12.1 Campaign Mode (10 rozdziałów)
- **Struktura**: każdy rozdział = scena z initial state + cele do osiągnięcia
- **Progresywna trudność**: więcej więźniów, trudniejsze kategorie, ograniczenia budżetu
- **Tutorial integrated**: rozdziały 1-3 z tooltips i guided tasks
- **Przykłady**:
  - Rozdział 1: "Nowy początek" (20 cel, 20 prisoners low, $50k budżet)
  - Rozdział 2: "Rozbudowa" (cel: 50 prisoners, 2 warsztaty, zysk $5k/dzień)
  - Rozdział 3: "Pierwsze problemy" (survive bójka, zapobiegnij ucieczce)
  - Rozdział 5: "Zróżnicowanie" (wszystkie kategorie, 100 prisoners)
  - Rozdział 10: "Imperium" (200 prisoners, 5⭐ reputacja, $100k kapitał)
- **Cutscenes**: tekstowe komunikaty od ministra (dialog boxes)

### 12.2 Sandbox Mode
- **Custom settings menu**: kapitał startowy ($10k-$500k), wielkość mapy (small/medium/large), max prisoners (50-500)
- **Toggle options**: kategorie więźniów (które dostępne), kryzysy on/off, trudność ekonomii (easy/normal/hard)
- **Brak celów**: free build bez ograniczeń czasowych
- **Wszystkie budynki unlocked** od startu
- **Multiple save slots**: 3 sloty dla różnych sandboxów

### 12.3 Scenarios (premium content)
- **Przejęcie**: zrujnowane więzienie (50% zniszczone), mood 20%, 60 dni na naprawę
- **Maksimum**: tylko maximum security prisoners, 180 dni survival
- **Przeludnienie**: 200 prisoners, 100 capacity, repair economy + build
- **Unlock**: po ukończeniu kampanii lub IAP ($1.99)

---

## FAZA 13: GRAFIKA I AUDIO
**Czas: 2-3 tygodnie | Priorytet: WYSOKI (równolegle z kodem)**

### 13.1 Sprites - budynki i obiekty
- **Style**: minimalistyczny 2D, top-down view, inspiracja Prison Architect
- **Buildings**: wszystkie typy (20+), rozmiary dopasowane do tile grid
- **Objects**: meble (łóżka, stoły, ławki), equipment (detektory, kamery)
- **Ściany i drzwi**: 4 typy ścian, różne drzwi (wood/metal/reinforced)
- **Paleta kolorów**: szarości + akcenty (niebieski/pomarańczowy/czerwony/czarny dla kategorii)

### 13.2 Sprites - postacie
- **Prisoners**: sprite sheets z 4-kierunkową animacją (walk), color variants dla kategorii
- **Staff**: różne uniformy (guard/medic/cook/etc.), także 4-kierunkowe
- **Animacje**: walk cycle (4 frames), idle, action-specific (fighting, eating, sleeping)
- **Effects**: chmura bójki, blood splatter (optional, toggle), tool icons

### 13.3 UI Graphics
- **Buttons**: flat design, 3 stany (normal/hover/pressed)
- **Panels**: ciemne tła z przezroczystością, borders
- **Icons**: 48x48 i 64x64 dla UI (potrzeby, budynki, akcje)
- **Progress bars**: health, needs, morale (color-coded)
- **Minimap**: simplified view z color-coded zones

### 13.4 Audio - Muzyka
- **Main menu**: ambient industrialny, spokojny
- **Gameplay normal**: napięta ale lekka, non-intrusive loop
- **Gameplay crisis**: intensywna, bębny, rising tension
- **Riot**: dramatyczna, chaotyczna
- **Victory/Success**: triumfalna, krótka
- **Format**: OGG dla kompatybilności, loop points

### 13.5 Audio - SFX
- **UI**: klik (button), sukces (ding), błąd (buzz), hover (subtle)
- **Budowa**: młotek, piła, construction sounds, completion bell
- **Bójka**: uderzenia (punch), krzyki (muffled), pacyfikacja (whistle)
- **Alarm**: syrena pulsująca, emergency beep
- **Ambient**: rozmowy prisoners (mumble loop), kroki (footsteps), drzwi (open/close), klucze (jingle)
- **Notification**: alert sounds (3 poziomy: critical/warning/info)

---

## FAZA 14: OPTYMALIZACJE I POLISH
**Czas: 2 tygodnie | Priorytet: KRYTYCZNY (balancing), WYSOKI (performance)**

### 14.1 Performance Optimizations
- **Object pooling**: prisoners i staff (pre-instantiate, reuse)
- **Culling**: renderowanie tylko widocznych sprites (VisibleOnScreenNotifier2D)
- **Spatial hashing**: szybkie collision detection, bójki detection
- **Throttling AI**: update logic co 0.1s zamiast każdy frame
- **Batching draw calls**: MultiMeshInstance2D dla identycznych sprites
- **Cel**: 60 FPS z 200+ więźniami na mid-range mobile

### 14.2 Balancing (KRYTYCZNE)
- **Ekonomia**: starting capital ($50k), income rates ($500-$1200 per prisoner), expense rates (staff $100-$200/day, food $10/prisoner)
- **Needs decay**: rates dostrojone (hunger -2%/h, sleep -1.5%/h, etc.)
- **Fight triggers**: aggression threshold (potrzeby <20% zamiast 30%)
- **Riot conditions**: mood threshold (<25% zamiast 30%)
- **Building costs**: balance risk/reward (expensive security vs cheap but risky)
- **Staff effectiveness**: guards pacification time, medic heal rate
- **Metoda**: playtesting + iteracja (minimum 10h testowania)

### 14.3 Bug Fixing Pass
- **Focus areas**: pathfinding edge cases (stuck prisoners), UI responsiveness (touch lag), save/load corruption, event triggers (duplicate fires), memory leaks (orphan nodes)
- **Testing**: regression testing po każdej zmianie
- **Logging**: debug mode z detailed logs
- **Crash reporting setup**: przygotowanie do Firebase Crashlytics

### 14.4 Animacje i Juice (polish)
- **Smooth transitions**: tween dla UI panels (slide in/out), camera movements
- **Particle effects**: iskry (bójka), dym (zniszczenia), confetti (osiągnięcia)
- **Screen shake**: subtelny przy bójce, mocny przy buncie
- **Visual feedback**: button press animation, object selection highlight (outline shader), building placement ghost
- **Sound feedback**: każda akcja UI ma SFX

### 14.5 Tutorial System
- **Tooltips**: popup hints przy pierwszym użyciu feature
- **Highlight UI elements**: pulsujące obramowanie na ważnych buttonach
- **Step-by-step guidance**: task list w rozdziałach 1-3 kampanii
- **Skip option**: dla doświadczonych graczy (checkbox w settings)
- **Contextual help**: ikona "?" przy skomplikowanych panelach

---

## FAZA 15: MONETYZACJA I MOBILE
**Czas: 1-2 tygodnie | Priorytet: ŚREDNI (pre-launch)**

### 15.1 Rewarded Ads Integration
- **SDK**: AdMob (Android) lub Unity Ads (multiplatform)
- **4 typy nagród**: bonus cash (+$5k), przyspieszenie budowy (-50% time remaining), uspokojenie mood (+20% all prisoners), leczenie (heal all to 100%)
- **Frequency limits**: max 1x/godzinę realtime, max 5x/dzień
- **Opcjonalne**: nigdy wymuszone, tylko jako pomoc
- **UI**: przycisk "Watch Ad" w panelach (economy, crisis)

### 15.2 IAP System (In-App Purchases)
- **Premium Pack** ($4.99): remove ads, unlock extra scenarios, cosmetic skins, advanced stats, unlimited save slots
- **Cosmetic packs** ($0.99-$2.99): skiny budynków (themes: modern/industrial/futuristic), uniformy personelu
- **Starter pack** ($2.99): $50k kapitał, 5 strażników, unlock tier 2 buildings
- **Integracja**: Google Play Billing (Android), iOS StoreKit (Apple)
- **Receipt validation**: server-side (prevent piracy)

### 15.3 Mobile Optimizations
- **Touch controls polish**: larger hit areas (minimum 44x44 dp), clear visual feedback
- **Battery optimization**: throttle updates w background, pause heavy calculations
- **Screen sizes**: support phones (5-7"), tablets (8-13"), aspect ratios (16:9, 18:9, 19.5:9)
- **Orientation**: landscape primary, optional portrait support
- **Low-end device testing**: test na urządzeniach <2GB RAM, optimize accordingly
- **Loading times**: reduce initial load (<3s), async loading, progress bar

### 15.4 Cloud Save (opcjonalnie)
- **Google Play Games Services**: cloud save slots, achievements integration
- **iOS Game Center**: iCloud save backup
- **Sync between devices**: automatic when logged in
- **Manual backup**: export/import save file (JSON)

---

## FAZA 16: TESTING I LAUNCH
**Czas: 2-3 tygodnie | Priorytet: WYSOKI**

### 16.1 Internal Testing (Alpha)
- **Zakres pełny**: przejście całej kampanii (10 rozdziałów), sandbox prolonged play (symulacja 365 dni), wszystkie scenariusze, force trigger wszystkich kryzysów
- **Edge cases**: 0 prisoners, 500 prisoners, $0 kapitał, wszystkie building types, każda kombinacja
- **Performance profiling**: FPS monitoring, memory usage, load times
- **Bug tracking**: Google Sheets lub Notion z priorytetami

### 16.2 Beta Testing (Closed)
- **Rekrutacja**: 50-100 testerów (social media, game dev communities)
- **Platformy**: Google Play Internal/Closed Testing, TestFlight (iOS)
- **Feedback collection**: Google Forms z pytaniami (fun factor, difficulty, bugs, improvement suggestions)
- **Crash reporting**: Firebase Crashlytics integration
- **Iteracja**: 2 rundy beta (fix bugs → retest)
- **Cel**: <1% crash rate, >4.0/5 satisfaction

### 16.3 Localization (opcjonalnie MVP, ale zalecane)
- **Polski** (priorytet): już jest w README, finalizacja all UI strings
- **Angielski**: tłumaczenie wszystkich tekstów (UI, tutorial, kampania, alerts)
- **System**: TranslationServer w Godot, CSV z kluczami
- **Testowanie**: native speakers review
- **Pozostałe języki**: post-launch (niemiecki, francuski, hiszpański)

### 16.4 Marketing Materials
- **Screenshots** (8 najlepszych): różne scenariusze (budowa, bójka, UI panels, więzienie pełne), high quality (1080p+)
- **App icon**: 512x512, memorable, prison theme (bars? guard tower?), testować A/B variants
- **Feature graphic**: Google Play header (1024x500), kluczowe visual selling points
- **Trailer video**: 30-60s gameplay (buduj → zarządzaj → reaguj na kryzysy → sukces), muzyka epic, text overlay z features
- **Description**: store listing (krótki pitch, features list, screenshots caption), ASO keywords (prison, tycoon, management, simulation)

### 16.5 Soft Launch
- **Strategia**: launch w 1 kraju testowym (Polska? Kanada?)
- **Monitoring**: retention (Day 1, Day 7, Day 30), crash rate (cel <2%), revenue (ARPU, conversion rate IAP/ads), user feedback (reviews)
- **Analytics**: Firebase Analytics, custom events (key actions tracking)
- **Iteracja**: 2-4 tygodnie soft launch, fix critical issues, adjust balancing na podstawie danych
- **Decision**: expand jeśli metrics OK (retention D1 >40%, D7 >20%)

### 16.6 Full Launch (Global)
- **Przygotowanie**: global release (Android Google Play + iOS App Store)
- **Press kit**: dla blogów gaming (screenshots, trailer, description, dev contact)
- **Social media**: Twitter/X, Reddit (r/godot, r/prisonarchitect, r/AndroidGaming, r/iosgaming), TikTok/Instagram (short clips)
- **Community building**: Discord server (opcjonalnie), devlog (itch.io lub blog)
- **Launch discount**: starter pack -50% przez pierwszy tydzień (tactic)

---

## FAZA 17: POST-LAUNCH
**Czas: Ongoing | Priorytet: Maintenance + New Content**

### 17.1 Daily Challenges (update 1.1)
- **Implementacja**: proceduralne wyzwania z unique seed (daily generated)
- **Format**: survive X dni z specific constraints (limited budget, only max security, no lockdown allowed)
- **Leaderboard**: Firebase Realtime Database lub PlayFab, ranking by time/efficiency
- **Rewards**: kosmetyki (badges, skins), bonus kapitał
- **Priorytet**: 1 miesiąc po launch

### 17.2 Additional Content Updates
- **Wersja 1.2**: więcej osiągnięć (20 total), leaderboards (longest survival, richest prison), cloud save integration
- **Wersja 1.3**: premium scenarios (Więzienie kobiece, Juvenile detention, Military prison)
- **Wersja 2.0**: multiplayer concept (wizyta w więzieniu znajomego, compare stats, send challenges)
- **Seasonal events**: holiday themes (Christmas decorations, Halloween event)

### 17.3 Community Support i Maintenance
- **Bug fixes**: hotfix w ciągu 24-48h dla critical bugs, patch co 2 tygodnie dla minor bugs
- **Feature requests**: community voting (Discord/Reddit), priorytetyzacja top 5
- **Balance updates**: na podstawie analytics data (jeśli wszyscy failują rozdział 5 → rebalance)
- **Regular communication**: devlog co miesiąc (what's new, what's coming), respond to reviews
- **Monitoring**: daily checks analytics (crash rate, retention, revenue), weekly reports

---

## PODSUMOWANIE: PRIORYTETY I MVP

### MVP Definition (Minimum Viable Product)
**Co MUSI być w pierwszym release (Fazy 0-7, częściowo 10, 12-14, 16):**
1. ✅ Core systems (GameManager, TileMap, Navigation, Camera) - UKOŃCZONE
2. ✅ System budowania (minimum 5 typów budynków) - UKOŃCZONE (24 typy)
3. ✅ Ekonomia (przychody, wydatki, bankructwo) - UKOŃCZONE
4. ✅ Więźniowie (3 kategorie, potrzeby, AI, pathfinding) - UKOŃCZONE (4 kategorie)
5. ✅ Harmonogram (podstawowy, edytowalny) - UKOŃCZONE
6. ✅ Personel (strażnicy, kucharze, medycy) - UKOŃCZONE
7. ✅ Kryzysy podstawowe (bójki, ucieczki, alert system) - UKOŃCZONE
8. ✅ UI (HUD, Build Menu, Prisoner Panel, Alerts - podstawowe) - UKOŃCZONE
9. ⏳ Kampania (minimum 5 rozdziałów z tutorialem) - DO ZROBIENIA
10. ⏳ Grafika i audio (podstawowe, wystarczające do grania) - CZĘŚCIOWO (placeholder sprites)
11. ⏳ Balancing i bug fixing (gra grywalna i fun) - W TRAKCIE

### Aktualny status (Listopad 2025):
**UKOŃCZONE FAZY: 0, 1, 2, 3, 4, 5, 6, 7**
- Wszystkie core systemy działają
- Więźniowie i strażnicy poruszają się i reagują na harmonogram
- System kryzysów (bójki, ucieczki, kontrabanda) aktywny
- UI podstawowe kompletne

**DO ZROBIENIA dla MVP:**
1. **Faza 12.1 - Kampania** (priorytet WYSOKI)
   - [ ] 5-10 rozdziałów z progresywną trudnością
   - [ ] Tutorial w rozdziałach 1-3
   - [ ] System celów i warunków zwycięstwa

2. **Faza 13 - Grafika** (priorytet ŚREDNI)
   - [ ] Sprite'y budynków (obecnie ColorRect placeholdery)
   - [ ] Sprite'y postaci (więźniowie, personel)
   - [ ] Animacje chodzenia

3. **Faza 13 - Audio** (priorytet NISKI dla MVP)
   - [ ] Muzyka tła
   - [ ] Efekty dźwiękowe UI
   - [ ] Dźwięki wydarzeń (bójki, alarmy)

4. **Faza 14 - Polish** (priorytet WYSOKI)
   - [ ] Balansowanie ekonomii
   - [ ] Balansowanie potrzeb więźniów
   - [ ] Bug fixing
   - [ ] Performance optimization dla 100+ więźniów

### Post-MVP (Nice-to-have, można dodać w updateach)
- ⏳ Bunty i epidemia (zaawansowane kryzysy)
- ⏳ System gangów
- ⏳ Wszystkie budynki (20+ typów - MVP może mieć 10-12)
- ⏳ Sandbox mode (MVP fokus na kampanię)
- ⏳ Scenariusze premium
- ⏳ Zaawansowane statystyki i wykresy
- ⏳ Daily challenges
- ⏳ Multiplayer features

---

## TIMELINE ESTIMATE

### Solo Developer (Full-time):
- **Miesiąc 1**: Fazy 0-1 (Przygotowanie + Core Systems)
- **Miesiąc 2**: Fazy 2-3 (Budowanie + Ekonomia)
- **Miesiąc 3**: Fazy 4-5 (Więźniowie + Harmonogram)
- **Miesiąc 4**: Fazy 6-7 (Personel + Kryzysy podstawowe)
- **Miesiąc 5**: Fazy 10-11-12 (UI + Content + Kampania - równolegle z Fazą 13)
- **Miesiąc 6**: Fazy 14-16 (Optymalizacje + Testing + Launch)

**TOTAL: 6 miesięcy (24 tygodnie) dla MVP**

### Solo Developer (Part-time, 20h/tydzień):
**TOTAL: 10-12 miesięcy dla MVP**

### Zespół 2-3 osób:
**TOTAL: 3-4 miesiące dla MVP**

---

## KLUCZOWE RYZYKA

### Ryzyko 1: Balansowanie zbyt trudne / gra frustrating
**Mitygacja**: Wczesne playtesting (od Fazy 7), iteracyjne dostrajanie, difficulty settings (easy/normal/hard)

### Ryzyko 2: Performance issues z 200+ więźniami
**Mitygacja**: Object pooling od początku, profilowanie wcześnie (Faza 10), throttling AI updates, spatial hashing

### Ryzyko 3: UI zbyt skomplikowane na mobile
**Mitygacja**: Prototype UI wcześnie, user testing z touch controls, simplify where possible, tutorial comprehensive

### Ryzyko 4: Scope creep (za dużo features, never finish)
**Mitygacja**: Stick to MVP ruthlessly, post-MVP features zapisz do backlog, clear priorities, no feature additions mid-development

### Ryzyko 5: Monetyzacja nie działa (no revenue)
**Mitygacja**: A/B testing IAP offers, analytics (retention, ARPU, conversion), adjust pricing, rewarded ads jako safety net

---

## SUCCESS METRICS

### Pre-Launch Targets:
- [ ] 60 FPS stabilne z 200 więźniami na mid-range device
- [ ] Kampania 10 rozdziałów completable w 8-12 godzin
- [ ] <1% crash rate w closed beta
- [ ] >4.0/5 satisfaction od beta testerów (minimum 50 responses)

### Post-Launch Targets (30 dni):
- [ ] 10,000+ downloads (organic + marketing)
- [ ] Day 1 retention >40%, Day 7 >20%, Day 30 >10%
- [ ] <2% crash rate w production
- [ ] Rating >4.0 w Google Play i App Store
- [ ] ARPU >$0.50 (average revenue per user)
- [ ] >100 reviews (engagement indicator)

### Long-term Goals (6 miesięcy):
- [ ] 50,000+ downloads
- [ ] Active daily users 1,000+
- [ ] Profitable (revenue > development costs)
- [ ] Community established (Discord 100+ members)
- [ ] 2+ content updates released

---

## NOTES

### Development Philosophy:
- **Iterate fast**: prototype → test → refine → repeat
- **Fun first**: mechanika musi być fun przed polish
- **Data-driven**: używaj analytics do decisions post-launch
- **Community feedback**: słuchaj graczy, ale filtruj (nie wszystkie sugestie dobre)

### Tech Stack:
- **Engine**: Godot 4.x (2D, mobile export)
- **Language**: GDScript (szybki development, easy to learn)
- **Version control**: Git + GitHub
- **Analytics**: Firebase (Analytics + Crashlytics)
- **Monetization**: AdMob (ads) + Google Play Billing (IAP)

### Resources Needed:
- **Art**: albo self-made (pixel art tools), albo asset packs (itch.io, Kenney), albo commissioned ($500-$2000 budget)
- **Audio**: asset packs (Incompetech, Freesound), albo commissioned ($300-$1000)
- **Testing devices**: minimum 3 devices (low/mid/high-end Android, 1 iOS)

---

**GOOD LUCK! 🚀**

*Ten dokument jest żywym dokumentem - aktualizuj według postępów i odkryć podczas developmentu.*