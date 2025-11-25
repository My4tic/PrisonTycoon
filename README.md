# 🏛️ PRISON TYCOON
## Game Design Document for Godot 4

---

## SPIS TREŚCI

1. [Wizja gry](#wizja-gry)
2. [Core Loop](#core-loop)
3. [Ekonomia i budżet](#ekonomia-i-budżet)
4. [System budowania](#system-budowania)
5. [Pomieszczenia](#pomieszczenia)
6. [Więźniowie](#więźniowie)
7. [Personel](#personel)
8. [Harmonogram dnia](#harmonogram-dnia)
9. [Kryzysy i wydarzenia](#kryzysy-i-wydarzenia)
10. [Progresja gry](#progresja-gry)
11. [Interfejs użytkownika](#interfejs-użytkownika)
12. [Sterowanie mobile](#sterowanie-mobile)
13. [Grafika i styl](#grafika-i-styl)
14. [Monetyzacja](#monetyzacja)
15. [Tryby gry](#tryby-gry)
16. [Implementacja w Godot 4](#implementacja-w-godot-4)

---

# WIZJA GRY

## Elevator Pitch

Zbuduj i zarządzaj własnym więzieniem. Balansuj bezpieczeństwo, budżet i prawa człowieka. Projektuj cele, ustalaj harmonogramy, zatrudniaj strażników i zapobiegaj buntom. Prosty top-down management sim w stylu Prison Architect dla mobile.

## Główne filary designu

| Filar | Opis |
|-------|------|
| **Budowanie** | Projektowanie więzienia z pomieszczeń na siatce |
| **Zarządzanie** | Harmonogramy, personel, finanse, polityki |
| **Więźniowie** | Jednostki z potrzebami, charakterem i zagrożeniami |
| **Equilibrium** | Balansowanie bezpieczeństwa vs koszty vs humanitaryzm |
| **Kryzysy** | Bunty, ucieczki, choroby - zarządzanie kryzysowe |

## Inspiracje

- **Prison Architect** – główna inspiracja, mechaniki, styl
- **RimWorld** – system potrzeb, emergent gameplay
- **Theme Hospital** – zarządzanie, humor, przystępność
- **Game Dev Tycoon** – jasna progresja, satysfakcja z budowania

---

# CORE LOOP

```
BUDUJ → PRZYJMUJ → HARMONOGRAMUJ → MONITORUJ → REAGUJ
  ↑                                                 │
  └─────────────────────────────────────────────────┘
```

## Szczegółowy opis pętli

1. **BUDUJ** – Gracz rozbudowuje więzienie dodając pomieszczenia (cele, kantynę, podwórko, warsztaty)
2. **PRZYJMUJ** – Nowi więźniowie przybywają (gracz dostaje subwencję rządową za każdego)
3. **HARMONOGRAMUJ** – Gracz ustala dzienny rozkład zajęć: jedzenie, praca, rekreacja, sen
4. **MONITORUJ** – Obserwuj potrzeby więźniów, nastroje, zagrożenia, finanse
5. **REAGUJ** – Zapobiegaj problemom (bójki, ucieczki) lub rozwiązuj kryzysy (bunty, epidemie)

## Cel gry

Zbudować efektywne, bezpieczne i rentowne więzienie, które:
- Generuje zysk
- Utrzymuje niski poziom przemocy
- Ma wysoką reputację rządową (ocena w gwiazdkach)
- Zapobiega ucieczkom i buntom

---

# EKONOMIA I BUDŻET

## Źródła przychodu

| Źródło | Kwota | Częstość | Uwagi |
|--------|-------|----------|-------|
| **Subwencja za więźnia** | $500/dzień | Dzienny | Podstawowe źródło |
| **Praca więźniów** | $50-200/dzień | Dzienny | Warsztaty, pralnia, kuchnia |
| **Kontrakty rządowe** | $5,000-20,000 | Jednorazowo | Za osiągnięcie celów |
| **Bonus za bezpieczeństwo** | $1,000 | Miesięczny | Jeśli 0 ucieczek |

## Wydatki

| Kategoria | Koszt | Częstość |
|-----------|-------|----------|
| **Pensje personelu** | $100-500/dzień/osoba | Dzienny |
| **Jedzenie** | $10/więzień/dzień | Dzienny |
| **Media** (energia, woda) | $50-500/dzień | Dzienny |
| **Budowa** | Różne | Jednorazowo |
| **Naprawy** | Różne | Po zniszczeniach |

## Zasady ekonomiczne

- Gracz widzi **dzienny bilans** (przychody - wydatki = zysk netto)
- Kapitał dostępny do wydania wyświetlany na górze ekranu
- **Bankructwo** (kapitał < $0 przez 7 dni) = game over
- Dostępna **pożyczka ratunkowa** ($20,000 z odsetkami 10%)

## Balansowanie

- Start: ~$30,000 kapitału
- Cel: osiągnąć dodatni bilans do końca miesiąca 1
- Pułapka: za szybka ekspansja = koszty rosną szybciej niż przychody
- Strategia: najpierw stabilizacja, potem ekspansja

---

# SYSTEM BUDOWANIA

## Podstawy

- Mapa podzielona na **siatką kwadratów 1x1**
- Wszystkie budynki i pomieszczenia budowane na siatce
- Minimum 3x3 dla najmniejszej celi
- Ściany zajmują 0.5 kwadratu (między dwoma kwadratami)

## Typy ścian

| Typ | Koszt | Wytrzymałość | Bezpieczeństwo | Uwagi |
|-----|-------|--------------|----------------|-------|
| Drewno | $50 | Niska | ⭐ | Więźniowie mogą przebić |
| Cegła | $150 | Średnia | ⭐⭐ | Standard |
| Beton | $300 | Wysoka | ⭐⭐⭐ | Bezpieczne |
| Stal | $500 | Bardzo wysoka | ⭐⭐⭐⭐ | Izolatki, maksymalne zabezpieczenie |

## Drzwi i bramy

| Typ | Koszt | Bezpieczeństwo | Funkcje |
|-----|-------|----------------|---------|
| Zwykłe drzwi | $100 | ⭐ | Podstawowe |
| Drzwi z zamkiem | $250 | ⭐⭐ | Zamykane zdalnie |
| Stalowe drzwi | $500 | ⭐⭐⭐ | Trudne do sforsowania |
| Brama automatyczna | $1,000 | ⭐⭐⭐ | Zdalne sterowanie, szybkie |
| Checkpoint | $2,000 | ⭐⭐⭐⭐ | Detektor metalu wbudowany |

## Zasady budowania

1. Wybierz typ pomieszczenia z menu
2. Przeciągnij na mapie aby wyznaczyć obszar (prostokąt)
3. System automatycznie dodaje ściany
4. Dodaj drzwi ręcznie (kliknij na ścianę)
5. Dodaj wyposażenie wewnątrz pomieszczenia
6. Potwierdź budowę - koloniści/robotnicy budują w czasie rzeczywistym

## Ograniczenia

- Pomieszczenia muszą być prostokątne
- Nie można budować na istniejących strukturach
- Trzeba zostawić przestrzeń na korytarze
- Niektóre pomieszczenia wymagają minimalnej wielkości
- Budżet musi wystarczyć na całą konstrukcję

---

# POMIESZCZENIA

## Cele mieszkalne

### Cela pojedyncza
- **Rozmiar:** 3x3
- **Pojemność:** 1 więzień
- **Wyposażenie:** Łóżko, toaleta
- **Koszt:** $1,500
- **Jakość:** Podstawowa
- **Efekt na nastrój:** Neutralny

### Cela podwójna
- **Rozmiar:** 4x4
- **Pojemność:** 2 więźniów
- **Wyposażenie:** 2 łóżka, toaleta, umywalka
- **Koszt:** $2,500
- **Jakość:** Średnia
- **Efekt na nastrój:** +5%

### Dormitorium
- **Rozmiar:** 8x8
- **Pojemność:** 8 więźniów
- **Wyposażenie:** 8 łóżek, 2 toalety, 2 umywalki
- **Koszt:** $6,000
- **Jakość:** Niska (przeludnienie)
- **Efekt na nastrój:** -10%

### Cela luksusowa
- **Rozmiar:** 5x5
- **Pojemność:** 1 więzień
- **Wyposażenie:** Łóżko, biurko, TV, łazienka prywatna
- **Koszt:** $5,000
- **Jakość:** Wysoka
- **Efekt na nastrój:** +20%
- **Uwaga:** Dostępna tylko dla więźniów z dobrym zachowaniem

## Wyżywienie

### Kuchnia
- **Rozmiar minimum:** 6x6
- **Koszt:** $3,000
- **Wyposażenie:** 2 kuchenki, 2 lodówki, blaty
- **Personel:** 2-4 kucharzy
- **Wydajność:** 50 posiłków/godzinę

### Jadalnia
- **Rozmiar minimum:** 10x10
- **Koszt:** $5,000
- **Wyposażenie:** Stoły + ławki
- **Stół:** 2x4, $200, pojemność 8 osób
- **Wydajność:** Zależy od liczby stolików

### Opcja alternatywna
- Posiłki dostarczane na tace do cel
- **Koszt:** $15/więzień/dzień (zamiast $10)
- **Efekt:** Gorsze jedzenie, -5% nastrój
- **Kiedy:** Gdy brak kantyny lub w lockdown

## Rekreacja

### Podwórko
- **Rozmiar minimum:** 10x10
- **Koszt:** $2,000
- **Wyposażenie:** Ławki, kosz do koszykówki, trawa/beton
- **Funkcja:** Spacery, sport, socjalizacja
- **Efekt:** +10% nastrój, -15% agresja

### Siłownia
- **Rozmiar minimum:** 6x6
- **Koszt:** $4,000
- **Wyposażenie:** Sprzęt fitness, hantle
- **Funkcja:** Ćwiczenia fizyczne
- **Efekt:** -20% agresja, +10% zdrowie

### Biblioteka
- **Rozmiar minimum:** 5x5
- **Koszt:** $3,000
- **Wyposażenie:** Półki z książkami, stoliki
- **Funkcja:** Czytanie, nauka
- **Efekt:** +15% nastrój, -10% recydywa

### Kaplica
- **Rozmiar minimum:** 6x8
- **Koszt:** $3,500
- **Wyposażenie:** Ławki, ołtarz
- **Personel:** Kapłan
- **Funkcja:** Nabożeństwa, wsparcie duchowe
- **Efekt:** +15% nastrój, -5% agresja

### Sala TV
- **Rozmiar minimum:** 6x6
- **Koszt:** $2,500
- **Wyposażenie:** Telewizor, kanapy
- **Funkcja:** Oglądanie TV
- **Efekt:** +10% nastrój, -10% nuda

## Praca i produkcja

### Pralnia
- **Rozmiar:** 6x6
- **Koszt:** $5,000
- **Wyposażenie:** 4 pralki, 4 suszarki
- **Personel:** 0 strażników (niskie ryzyko)
- **Więźniowie:** 4
- **Przychód:** $200/dzień
- **Efekt na więźniów:** -10% nuda

### Warsztat stolarski
- **Rozmiar:** 8x8
- **Koszt:** $8,000
- **Wyposażenie:** Piły, stoły robocze
- **Personel:** 2 strażników (wysokie ryzyko - narzędzia)
- **Więźniowie:** 6
- **Przychód:** $500/dzień
- **Efekt na więźniów:** -15% nuda, +umiejętności

### Ogród
- **Rozmiar:** 10x10 (zewnętrzny)
- **Koszt:** $3,000
- **Wyposażenie:** Grządki, narzędzia
- **Personel:** 1 strażnik
- **Więźniowie:** 4
- **Przychód:** $300/dzień
- **Efekt na więźniów:** -10% nuda, +5% nastrój (na świeżym powietrzu)

### Call center
- **Rozmiar:** 8x6
- **Koszt:** $10,000
- **Wyposażenie:** Stanowiska komputerowe, telefony
- **Personel:** 1 strażnik
- **Więźniowie:** 8 (tylko niskie zagrożenie!)
- **Przychód:** $800/dzień
- **Efekt na więźniów:** -20% nuda, +umiejętności

### Kuchnia (jako praca)
- Więźniowie mogą pracować w kuchni
- **Personel:** Zawsze nadzór kucharza
- **Więźniowie:** 3
- **Przychód:** $100/dzień
- **Efekt:** -5% nuda

## Infrastruktura

### Ambulatorium
- **Rozmiar:** 5x5
- **Koszt:** $4,000
- **Wyposażenie:** 3 łóżka medyczne, apteczka, biurko
- **Personel:** Pielęgniarka/lekarz
- **Funkcja:** Leczenie ran, chorób
- **Pojemność:** 3 pacjentów jednocześnie

### Izolatka
- **Rozmiar:** 3x3
- **Koszt:** $2,000
- **Wyposażenie:** Łóżko, toaleta, stalowe ściany
- **Funkcja:** Kara, odseparowanie groźnych więźniów
- **Efekt:** -50% nastrój, bezpieczne odizolowanie
- **Czas:** Max 7 dni (prawo)

### Posterunek strażników
- **Rozmiar:** 4x4
- **Koszt:** $2,500
- **Wyposażenie:** Biurka, szafki, mapa więzienia
- **Funkcja:** Odpoczynek strażników, koordynacja
- **Efekt:** +20% efektywność strażników w pobliżu

### Recepcja
- **Rozmiar:** 6x4
- **Koszt:** $3,000
- **Wyposażenie:** Biurko, komputer, kamera
- **Funkcja:** Przyjmowanie nowych więźniów, wizyty rodzin
- **Wymóg:** Przy wejściu głównym

### Magazyn
- **Rozmiar:** 6x6
- **Koszt:** $1,500
- **Wyposażenie:** Regały, palety
- **Funkcja:** Przechowywanie materiałów budowlanych, jedzenia
- **Efekt:** Zwiększa pojemność magazynową

### Generator
- **Rozmiar:** 4x4
- **Koszt:** $5,000
- **Funkcja:** Energia backup przy awarii
- **Paliwo:** $100/dzień gdy aktywny
- **Moc:** 100% potrzeb więzienia

## Bezpieczeństwo

### Kamera CCTV
- **Koszt:** $500
- **Zasięg:** 5x5 kwadratów
- **Funkcja:** Monitoring obszaru, nagrywanie
- **Efekt:** +15% wykrywalność kontrabandy, -20% ryzyko bójek
- **Wymóg:** Centrum monitoringu (1 strażnik/10 kamer)

### Detektor metalu
- **Koszt:** $1,000
- **Instalacja:** Na bramach, przejściach
- **Funkcja:** Wykrywa broń, narzędzia
- **Efekt:** 80% szansa wykrycia kontrabandy
- **Alarm:** Automatyczne powiadomienie strażników

### Alarm
- **Koszt:** $800
- **Zasięg:** Cały sektor
- **Funkcja:** Powiadomienie o zagrożeniu
- **Czas reakcji:** Strażnicy przybywają w 30 sekund

### Wieża strażnicza
- **Rozmiar:** 3x3
- **Koszt:** $3,000
- **Personel:** 1 snajper
- **Zasięg:** 20 kwadratów
- **Funkcja:** Zapobiega ucieczkom przez ogrodzenie
- **Efekt:** 95% skuteczność zatrzymania ucieczki w zasięgu

### Szlaban
- **Koszt:** $1,500
- **Instalacja:** Na drogach, przejściach
- **Funkcja:** Kontrola przepływu pojazdów/więźniów
- **Sterowanie:** Zdalne lub automatyczne

---

# WIĘŹNIOWIE

## Podstawowe atrybuty

Każdy więzień posiada:

### Identyfikacja
- **Imię i nazwisko** (generowane losowo)
- **Numer więźnia** (unikalny ID)
- **Wiek:** 18-65 lat
- **Wygląd:** Randomizowany sprite

### Prawne
- **Wyrok:** 1-30 lat
- **Pozostały czas:** Odliczany
- **Przestępstwo:** Typ (kradzież, napad, morderstwo, etc.)
- **Kategoria zagrożenia:** Niska / Średnia / Wysoka / Maksymalna

### Status
- **Zdrowie:** 0-100%
- **Nastrój:** 0-100% (wpływa na zachowanie)
- **Lokalizacja:** Aktualna pozycja w więzieniu
- **Aktywność:** Co robi w danym momencie

## Kategorie zagrożenia

### Niskie zagrożenie (Niebieski)
- **Przestępstwa:** Drobne kradzieże, oszustwa, wykroczenia
- **Zachowanie:** Spokojne, przestrzegają zasad
- **Wymagania:** Podstawowa opieka, normalna cela
- **Nadzór:** 1 strażnik / 15 więźniów
- **Subwencja:** $500/dzień
- **Ryzyko:** 5% bójki, 2% ucieczki

### Średnie zagrożenie (Pomarańczowy)
- **Przestępstwa:** Włamania, napady bez przemocy, handel narkotykami
- **Zachowanie:** Czasami problematyczne, wymagają uwagi
- **Wymagania:** Więcej nadzoru, checkpoint na przejściach
- **Nadzór:** 1 strażnik / 10 więźniów
- **Subwencja:** $650/dzień
- **Ryzyko:** 15% bójki, 5% ucieczki

### Wysokie zagrożenie (Czerwony)
- **Przestępstwa:** Napady z bronią, pobicia, morderstwa
- **Zachowanie:** Agresywne, niebezpieczne
- **Wymagania:** Stalowe drzwi, częste patrole, oddzielne skrzydło
- **Nadzór:** 1 strażnik / 5 więźniów
- **Subwencja:** $800/dzień
- **Ryzyko:** 30% bójki, 10% ucieczki, 5% napad na strażnika

### Maksymalne zabezpieczenie (Czarny)
- **Przestępstwa:** Seryjni mordercy, terroryści, liderzy gangów
- **Zachowanie:** Bardzo niebezpieczne, nieprzewidywalne
- **Wymagania:** Izolatki, stal, 24/7 monitoring, SWAT w gotowości
- **Nadzór:** 1 strażnik / 2 więźniów
- **Subwencja:** $1,200/dzień
- **Ryzyko:** 50% bójki, 20% ucieczki, 15% próba zabójstwa

## System potrzeb

Każda potrzeba ma wartość 0-100%. Im niższa, tym większe problemy.

### Głód (🍎)
- **Zaspokajanie:** Posiłki w kantynie lub tace do cel
- **Częstość:** 3x dziennie (śniadanie, obiad, kolacja)
- **Spadek:** -2%/godzinę bez jedzenia
- **Skutki braku (<30%):**
  - 30-20%: Zły nastrój, -10% nastrój
  - 20-10%: Bardzo zły nastrój, -25% nastrój, +15% agresja
  - <10%: Bójki o jedzenie, próby kradzieży, -50% nastrój

### Odpoczynek (😴)
- **Zaspokajanie:** Sen w celi (8h zalecane)
- **Spadek:** -5%/godzinę bez snu
- **Skutki braku (<30%):**
  - 30-20%: Zmęczenie, -10% produktywność w pracy
  - 20-10%: Bardzo zmęczony, -25% produktywność, +10% choroby
  - <10%: Kolaps, trafia do ambulatorium

### Higiena (🚿)
- **Zaspokajanie:** Prysznice, toaleta, umywalka w celi
- **Spadek:** -3%/godzinę
- **Skutki braku (<30%):**
  - 30-20%: Brudny, -10% nastrój
  - 20-10%: Bardzo brudny, -20% nastrój, +15% ryzyko choroby
  - <10%: Choroby (grypa, infekcje), rozprzestrzenianie

### Wolność (🌳)
- **Zaspokajanie:** Podwórko, rekreacja, spacery
- **Spadek:** -2%/godzinę zamknięcia w celi
- **Skutki braku (<30%):**
  - 30-20%: Frustracja, -10% nastrój
  - 20-10%: Depresja, -25% nastrój, +20% agresja
  - <10%: Próby ucieczki, samookaleczenia

### Bezpieczeństwo (🛡️)
- **Zaspokajanie:** Odseparowanie od wrogich więźniów/gangów, obecność strażników
- **Spadek:** -5%/godzinę gdy w pobliżu wrogów
- **Skutki braku (<30%):**
  - 30-20%: Stres, -10% nastrój
  - 20-10%: Strach, -20% nastrój, unika niektórych pomieszczeń
  - <10%: Panika, prośba o ochronę (izolatka), ewentualnie atak wyprzedzający

### Rozrywka (🎮)
- **Zaspokajanie:** TV, biblioteka, sport, gry
- **Spadek:** -1%/godzinę
- **Skutki braku (<30%):**
  - 30-20%: Nuda, -5% nastrój
  - 20-10%: Bardzo znudzony, -15% nastrój, +10% agresja
  - <10%: Szuka zajęcia (kontrabanda, gangi, bójki)

## Cechy charakteru

Każdy więzień ma 1-3 cechy (losowane przy generacji).

### Pozytywne cechy

| Cecha | Efekt | Rzadkość |
|-------|-------|----------|
| **Pracowity** | +25% produktywność w pracy | 15% |
| **Spokojny** | -30% szansa na bójkę | 20% |
| **Zdyscyplinowany** | Przestrzega harmonogramu, nie próbuje uciekać | 10% |
| **Towarzyski** | +10% nastrój sąsiadów w celi | 15% |
| **Silny** | +50% zdrowie, szybciej wygrywa bójki | 10% |
| **Inteligentny** | Szybciej się uczy (programy rehabilitacji), +20% wartość w pracy | 10% |

### Negatywne cechy

| Cecha | Efekt | Rzadkość |
|-------|-------|----------|
| **Agresywny** | +50% szansa na bójkę | 20% |
| **Leniwy** | -30% produktywność w pracy | 15% |
| **Kłamca** | Ukrywa kontrabandę (-30% wykrywalność) | 15% |
| **Zbieg** | +40% próby ucieczki | 10% |
| **Lider gangu** | Organizuje grupy, bunty | 5% |
| **Chory psychicznie** | Nieprzewidywalny, losowe zachowania | 10% |
| **Słaby** | -50% zdrowie, przegrywa bójki | 10% |
| **Samotnik** | -20% nastrój w celach wieloosobowych | 15% |

## Zachowania więźniów

### Normalne zachowania

- **Chodzenie:** Poruszanie się po więzieniu zgodnie z harmonogramem
- **Jedzenie:** Udanie się do kantyny, jedzenie, powrót
- **Praca:** Wykonywanie przydzielonych zadań
- **Rekreacja:** Korzystanie z podwórka, siłowni, biblioteki
- **Sen:** Powrót do celi, sen
- **Socjalizacja:** Rozmowy z innymi więźniami

### Problematyczne zachowania

| Zachowanie | Trigger | Mechanika | Rozwiązanie |
|------------|---------|-----------|-------------|
| **Bójka** | Niska potrzeba + agresywna cecha + brak nadzoru | 2 więźniów atakuje się, inni mogą dołączyć (zasięg 3 kwadraty) | Strażnicy pacyfikują, agresorzy do izolatki |
| **Kradzież** | Głód <20% + okazja | Próba ukraść jedzenie z kuchni/magazynu | Strażnicy nakrywają (50% szansa), kara |
| **Ucieczka** | Wolność <10% + okazja (dziura, brak strażników) | Więzień ucieka w stronę ogrodzenia/bramy | Snajperzy/strażnicy łapią lub ucieka (game over dla więźnia) |
| **Kontrabanda** | Brak nadzoru + kontakty zewnętrzne | Więzień ma nielegalny przedmiot (telefon, narkotyki, nóż) | Rewizje, detektory metalu wykrywają |
| **Odmowa pracy** | Nastrój <30% | Więzień nie idzie do pracy | Kara (izolatka) lub poprawa warunków |
| **Samookaleczenie** | Nastrój <10% + brak pomocy psychologa | Więzień rani się, trafia do ambulatorium | Psycholog, poprawa warunków |

## Gangi i hierarchia

Z czasem więźniowie formują nieformalne grupy (automatyczne, na podstawie cech i czasu wspólnie spędzonego).

### Typy gangów

| Gang | Charakterystyka | Zachowanie | Liczebność |
|------|-----------------|------------|------------|
| **Bractwo** | Lojalność, ochrona | Bronią swoich członków w bójkach | 5-15 członków |
| **Mafia** | Handel, kontrola | Monopolizują kontrabandę, wymuszenia | 8-20 członków |
| **Bandyci** | Agresja, terror | Atakują słabszych, bójki o dominację | 5-10 członków |
| **Polityczni** | Inteligencja, retoryka | Organizują protesty, bunty ideologiczne | 10-25 członków |

### Mechanika gangów

- **Rekrutacja:** Więzień dołącza do gangu po 30 dniach wspólnego spędzania czasu
- **Lider:** Najsilniejszy/najinteligentniejszy członek
- **Rywalizacja:** Różne gangi walczą o terytorium (kantyna, podwórko)
- **Skutki:** 
  - Bójki międzygangowe (większe, groźniejsze)
  - Organizacja buntów (lider koordynuje)
  - Kontrola kontrabandy (trudniej wykryć)

### Przeciwdziałanie

- Odseparowanie liderów (izolatka, inne skrzydło)
- Mieszanie więźniów różnych gangów minimalizowane
- Programy rehabilitacji (zmniejszają lojalność wobec gangu)
- Psycholog pracujący z liderem

---

# PERSONEL

## Typy pracowników

### Strażnik
- **Pensja:** $150/dzień
- **Funkcja:** Nadzór, pacyfikacja bójek, patrole, eskortowanie więźniów
- **Efektywność:** 1 strażnik / 10 więźniów (średnio)
- **Wyposażenie:** Pałka (standard), taser (po szkoleniu), pies (po szkoleniu)
- **Zmęczenie:** Wymaga odpoczynku co 8h (3 zmiany na dobę)

### Snajper
- **Pensja:** $200/dzień
- **Funkcja:** Obsługa wieży strażniczej, zapobieganie ucieczkom
- **Efektywność:** 1 wieża / sektor więzienia
- **Zasięg:** 20 kwadratów od wieży
- **Skuteczność:** 95% zatrzymania ucieczki w zasięgu
- **Uwaga:** Może zabić więźnia (negatywne konsekwencje prawne)

### Pielęgniarka/Lekarz
- **Pensja:** $180/dzień
- **Funkcja:** Leczenie ran, chorób, pierwsza pomoc
- **Efektywność:** 1 medyk / 20 więźniów
- **Miejsce pracy:** Ambulatorium
- **Szybkość leczenia:** Rana (1h), choroba (6h), poważne obrażenia (24h)

### Kucharz
- **Pensja:** $120/dzień
- **Funkcja:** Przygotowywanie posiłków
- **Efektywność:** 1 kucharz / 50 więźniów
- **Miejsce pracy:** Kuchnia
- **Jakość jedzenia:** Im więcej kucharzy, tym lepsze jedzenie (+nastrój)

### Psycholog
- **Pensja:** $250/dzień
- **Funkcja:** Terapia, zmniejszanie agresji, programy rehabilitacji
- **Efektywność:** 1 psycholog / 15 więźniów
- **Efekt:** -20% agresja, -15% recydywa, +10% nastrój
- **Czas sesji:** 1 sesja/więzień/tydzień, 2h/sesja

### Kapłan
- **Pensja:** $100/dzień
- **Funkcja:** Nabożeństwa, wsparcie duchowe
- **Efektywność:** 1 kapłan / 30 więźniów
- **Miejsce pracy:** Kaplica
- **Efekt:** +15% nastrój, -5% agresja

### Nauczyciel
- **Pensja:** $150/dzień
- **Funkcja:** Programy edukacyjne, kursy zawodowe
- **Efektywność:** 1 nauczyciel / 20 więźniów
- **Miejsce pracy:** Biblioteka/sala lekcyjna
- **Efekt:** -20% recydywa, +umiejętności (zwiększa wartość w pracy)

### Elektryk
- **Pensja:** $200/dzień
- **Funkcja:** Naprawy systemów elektrycznych, instalacje
- **Efektywność:** 1 elektryk / cały obiekt
- **Czas naprawy:** Zależy od uszkodzenia (1-6h)

### Sprzątaczka
- **Pensja:** $80/dzień
- **Funkcja:** Utrzymanie czystości pomieszczeń
- **Efektywność:** 1 sprzątaczka / sektor
- **Efekt:** -30% ryzyko chorób

## Szkolenia personelu (opcjonalne)

Strażnicy mogą być szkoleni w różnych specjalizacjach:

| Szkolenie | Koszt | Czas | Efekt |
|-----------|-------|------|-------|
| **Walka wręcz** | $500 | 3 dni | +50% skuteczność w bójkach |
| **Pierwsza pomoc** | $300 | 2 dni | Może ratować życie do przyjazdu medyka |
| **Taser** | $400 | 1 dzień | Pacyfikacja bez obrażeń (bezpieczniejsze) |
| **Psy patrolowe** | $800 | 5 dni | +40% wykrywanie kontrabandy |
| **SWAT** | $1,500 | 7 dni | Elite unit, wysłany podczas buntów |

## System zmian

- Personel pracuje w **zmianach 8-godzinnych**
- Potrzeba 3 zmian aby pokryć 24h
- **Zmiana 1:** 06:00-14:00
- **Zmiana 2:** 14:00-22:00
- **Zmiana 3:** 22:00-06:00 (nocna, +20% pensja)

## Morale personelu

Personel również ma morale (0-100%):

### Czynniki obniżające morale
- Nadgodziny (>8h/dzień): -10%/godzinę
- Niebezpieczne sytuacje (bójki, bunty): -20% po incydencie
- Brak posterunku (odpoczynku): -5%/godzinę
- Śmierć kolegi: -30%

### Skutki niskiego morale
- <50%: -20% efektywność
- <30%: Ryzyko zwolnienia (odchodzi sam)
- <10%: Sabotaż (otwiera cele, pomaga w ucieczce)

### Poprawa morale
- Posterunek strażników: +10%
- Premie ($500): +20%
- Brak incydentów przez 30 dni: +15%
- Szkolenia: +10%

---

# HARMONOGRAM DNIA

## Przykładowy harmonogram

Gracz może skonfigurować harmonogram dla każdej kategorii więźniów osobno.

### Domyślny harmonogram (średnie zagrożenie)

| Godzina | Aktywność | Lokalizacja | Uwagi |
|---------|-----------|-------------|-------|
| 00:00-06:00 | 😴 Sen | Cele (lockdown) | Drzwi zamknięte |
| 06:00-07:00 | 🍳 Śniadanie | Kantyna | Kolejka, 8 min/osoba |
| 07:00-08:00 | 🚿 Higiena | Prysznice | Rotacja grup |
| 08:00-12:00 | 🔧 Praca | Warsztaty | Produkcja, przychód |
| 12:00-13:00 | 🍽️ Obiad | Kantyna | Kolejka |
| 13:00-17:00 | 🔧 Praca / 📚 Programy | Warsztaty / Biblioteka | Opcjonalnie |
| 17:00-18:00 | 🏋️ Podwórko | Na zewnątrz | Rekreacja |
| 18:00-19:00 | 🍽️ Kolacja | Kantyna | Ostatni posiłek |
| 19:00-22:00 | 📺 Wolny czas | Cele otwarte, TV | Socjalizacja |
| 22:00-00:00 | 😴 Sen | Cele (lockdown) | Cisza nocna |

## Różnice między kategoriami

### Niskie zagrożenie
- Więcej wolnego czasu (+ 2h)
- Dłuższa rekreacja (+ 1h)
- Brak eskort strażników
- Cele otwarte do 23:00

### Wysokie/Maksymalne zagrożenie
- Mniej wolnego czasu (- 2h)
- Eskorty strażników (zawsze)
- Lockdown 20:00-06:00
- Pojedyncze cele (brak dormitoriów)
- Ograniczenie kontaktu z innymi

## Specjalne reguły

Gracz może ustawić dodatkowe reguły harmonogramu:

| Reguła | Efekt | Koszt morale |
|--------|-------|--------------|
| **Godzina policyjna** | Lockdown od 19:00 zamiast 22:00 | -10% nastrój |
| **Dodatkowa rekreacja** | +1h podwórko/dzień | +15% nastrój, -5% produkcja |
| **Brak podwórka** | Rekreacja tylko w celach | -20% nastrój, oszczędność strażników |
| **Praca dobrowolna** | Więźniowie wybierają czy pracują | +10% nastrój pracujących, -40% produkcja |
| **Przedłużony sen** | +1h snu, -1h pracy | +10% nastrój, -10% produkcja |
| **24h lockdown** | Wszyscy w celach (kryzys) | -50% nastrój/dzień, bezpieczne |

## Tryb lockdown

- **Aktywacja:** Ręcznie przez gracza lub automatycznie (bunt, ucieczka)
- **Efekt:** Wszyscy więźniowie natychmiast wracają do cel, drzwi zamknięte
- **Trwanie:** Do odwołania przez gracza
- **Skutki:**
  - Bezpieczeństwo: 100% (brak bójek, ucieczek)
  - Nastrój: -20%/dzień lockdownu
  - Produkcja: 0 (brak pracy)
  - Koszty: Jedzenie dostarczane na tace (+50% koszt)

---

# KRYZYSY I WYDARZENIA

## Bójki

### Trigger (warunki wystąpienia)
- Niska potrzeba (głód <30%, bezpieczeństwo <30%)
- Rywalizacja gangów (dwóch członków wrogich gangów w zasięgu 3 kwadraty)
- Więzień z cechą "agresywny" + brak nadzoru strażnika

### Mechanika

**Faza 1: Początek**
- 2 więźniów zaczyna bójkę (animacja ataku)
- Zasięg eskalacji: 3 kwadraty
- Inni więźniowie w zasięgu mogą dołączyć (30% szansa, 60% jeśli ten sam gang)

**Faza 2: Eskalacja**
- Co 10 sekund +1 uczestnik (jeśli w zasięgu)
- Obrażenia: 10 HP/10 sekund dla każdego uczestnika
- Jeśli uczestników >5 → ryzyko rozrostu do buntu

**Faza 3: Pacyfikacja**
- Strażnicy interweniują (automatycznie gdy w zasięgu 8 kwadratów)
- Czas pacyfikacji: 30 sekund/2 więźniów/strażnik
- Po pacyfikacji: Agresorzy → izolatka (3 dni)

### Skutki
- Ranni (trafiają do ambulatorium)
- Spadek morale świadków (-10%)
- Koszty leczenia ($100-500)
- Reputacja: -0.1 gwiazdki jeśli >5 uczestników

### Zapobieganie
- Wystarczająco strażników (1/10 więźniów)
- Odseparowanie wrogich gangów
- Karmienie na czas (głód >50%)
- Programy agresji (psycholog, siłownia)

## Ucieczki

### Trigger
- Potrzeba "wolność" <10%
- Cecha "zbieg"
- Okazja: dziura w ścianie, brak strażników, podczas bójki

### Fazy

**Faza 1: Planowanie (ukryta)**
- Więzień planuje ucieczkę przez 3-7 dni
- Zbiera narzędzia (kontrabanda: łyżka, pilnik)
- Obserwuje patrole strażników
- Znajduje słaby punkt (stara ściana, brak kamer)

**Wskaźniki (dla gracza):**
- Potrzeba wolność <10%
- Częste przebywanie przy ogrodzeniu
- Kontrabanda wykryta (narzędzia)

**Faza 2: Wykonanie**
- Więzień ucieka w stronę ogrodzenia/bramy
- Próba przedarcia się przez/pod ogrodzenie (dziura w ścianie, przekop)
- Albo próba ucieczki podczas transportu

**Faza 3: Pościg**
- Alarm aktywowany (automatycznie lub przez strażnika)
- Snajperzy mają 95% szansę zatrzymania (jeśli w zasięgu wieży)
- Strażnicy ścigają (prędkość: strażnik 1.5x więzień)
- Czas ucieczki: 60 sekund od alarmu do granicy mapy

### Skutki ucieczki

**Jeśli złapany:**
- Kara: izolatka 14 dni
- Cecha "zbieg" wzmocniona (+20% szansa następnej próby)
- Koszty: naprawa uszkodzeń ($500-2,000)

**Jeśli uciekł:**
- Utrata subwencji (-$500/dzień za tego więźnia)
- Kara finansowa (-$5,000)
- Reputacja: -0.5 gwiazdki
- Śledztwo rządowe (jeśli >3 ucieczki/miesiąc)

### Zapobieganie
- Wieże strażnicze przy ogrodzeniu
- Kamery CCTV przy murach
- Regularne patrole
- Solidne ściany (beton/stal)
- Detektory metalu (wykrywają narzędzia)
- Zadowolenie więźniów (wolność >40%)

## Bunty

Najbardziej niebezpieczne wydarzenie.

### Trigger
- >50% więźniów ma nastrój <30%
- Lider gangu organizuje (cecha "lider gangu" + gang >10 osób)
- Brutalna pacyfikacja wcześniejszej bójki (użycie SWAT z ofiarami)
- Drastyczne pogorszenie warunków (24h+ lockdown, brak jedzenia)

### Fazy

**Faza 0: Narastanie napięcia (24-48h przed)**
- Ostrzeżenie w UI: "⚠️ NAPIĘCIE ROŚNIE"
- Wskaźnik ryzyka buntu: 0-100%
- +5%/dzień jeśli warunki złe
- +20% jeśli lider gangu aktywny
- Gracz ma czas na reakcję (poprawa warunków, izolacja lidera)

**Faza 1: Początek**
- Grupa 10-30 więźniów odmawia posłuszeństwa
- Zbierają się w kantynie/podwórku
- Żądania:
  - Lepsze jedzenie
  - Więcej wolnego czasu
  - Zwolnienie z izolatki
  - Wymiana dyrektora (gracza)

**Faza 2: Eskalacja**
- Niszczenie mebli, okien, drzwi
- Podpalenia (kuchnia, magazyn)
- Wzięcie zakładników (strażnicy, więźniowie inni)
- Rozrost: +5 uczestników/minutę
- Blokada wejść (barykady)

**Faza 3: Szczyt**
- 50%+ więźniów uczestniczy
- Całe skrzydło opanowane
- Strażnicy wycofani lub uwięzieni
- Wyłączona energia (sabotaż generatora)
- Próby ucieczki masowej

### Rozwiązanie

Gracz ma 3 opcje:

**Opcja 1: SWAT (siłowe)**
- **Koszt:** $10,000
- **Czas:** SWAT przybywa w 10 minut
- **Skutek:**
  - Pacyfikacja w 30 minut
  - Ranni: 30-50% uczestników
  - Zabici: 5-15% uczestników
  - Zniszczenia: 70% infrastruktury w sektorze
- **Konsekwencje:**
  - Śledztwo rządowe
  - Pozew zbiorowy ($50,000)
  - Reputacja: -2 gwiazdki
  - Późniejsze bunty bardziej prawdopodobne

**Opcja 2: Negocjacje (dyplomatyczne)**
- **Wymóg:** Psycholog w zespole
- **Czas:** 1-3 godziny rozmów
- **Żądania:** Gracz musi spełnić 2-3 z 5 żądań
- **Skutek:**
  - Pokojowe zakończenie
  - Lider gangu do izolatki
  - Brak ofiar
  - Minimalne zniszczenia
- **Konsekwencje:**
  - Koszty spełnienia żądań ($5,000-15,000)
  - Reputacja: bez zmian lub -0.5 gwiazdki
  - Precedens (kolejne bunty mogą mieć większe żądania)

**Opcja 3: Ustępstwa (kapitulacja)**
- **Wymóg:** Brak
- **Czas:** Natychmiast
- **Skutek:**
  - Spełnienie wszystkich żądań
  - Pokojowe zakończenie
  - Brak ofiar
- **Konsekwencje:**
  - Bardzo wysokie koszty ($20,000-40,000)
  - Utrata autorytetu
  - Reputacja: -1 gwiazdka
  - Wysoka szansa na kolejne bunty (w ciągu 30 dni)

### Skutki po buncie

- **Zniszczenia:** Koszt naprawy $10,000-100,000 (zależy od rozwiązania)
- **Ranni/zabici:** Koszty leczenia, pozwy rodzin
- **Morale:** Wszyscy więźniowie -50% nastrój
- **Personel:** 50% strażników zwolni się (strach)
- **Reputacja:** Spadek gwiazdek, utrata kontraktów rządowych
- **Śledztwo:** Wizytacja za 7 dni, musi być wszystko naprawione

### Zapobieganie

- Monitoruj wskaźnik napięcia
- Utrzymuj nastrój >40%
- Izoluj liderów gangów
- Spełniaj podstawowe potrzeby
- Psycholog regularnie z więźniami
- Unikaj przedłużonych lockdownów
- Reaguj na ostrzeżenia wcześnie

## Inne wydarzenia

### Inspekcja rządowa

**Częstość:** Co 3 miesiące (obowiązkowa)

**Ocena:**
- Bezpieczeństwo (0 ucieczek, <5 bójek/miesiąc)
- Warunki bytowe (nastrój średni >60%)
- Finanse (zysk netto dodatni)
- Programy rehabilitacji (minimum 1 aktywny)

**Skutki:**
- 5 gwiazdek: +50% subwencja, bonus $10,000
- 3-4 gwiazdki: bez zmian
- 1-2 gwiazdki: -25% subwencja, ostrzeżenie
- 0 gwiazdek: zamknięcie więzienia (game over)

### Epidemia

**Trigger:**
- Higiena średnia <40% przez 14 dni
- Brak ambulatorium lub medyka
- Przeludnienie (>120% pojemności)

**Mechanika:**
- Patient zero: 1 więzień zachoruje
- Rozprzestrzenianie: +2 chorych/dzień w tym samym pomieszczeniu
- Symptomy: -50% zdrowie, -30% produktywność

**Rozwiązanie:**
- Kwarantanna chorych (izolacja)
- Medyk leczy (6h/osobę)
- Sprzątaczki czyszczą (+50% szybciej zakończenie)

**Skutki:**
- Koszt leczenia: $200/chory
- Śmierć jeśli brak leczenia (10% chorych)
- Panika (-20% nastrój wszystkich)

### Kontrabanda

**Częstość:** Często (10% szansa/dzień/więzień)

**Typy przedmiotów:**
- Telefon komórkowy (koordynacja gangów, ucieczek)
- Narkotyki (handel, agresja, uzależnienie)
- Nóż/broń improvised (bójki, napady)
- Alkohol (nastrój, ale agresja)
- Narzędzia (łyżka, pilnik - do ucieczek)

**Mechanika:**
- Więzień próbuje przemycić (podczas wizyty rodzin, dostaw)
- Wykrycie:
  - Detektor metalu: 80% szansa (broń, narzędzia)
  - Rewizja celi: 60% szansa (wszystko)
  - Psy patrolowe: 70% szansa (narkotyki)
  - Kamery: 40% szansa (obserwacja transakcji)

**Skutki posiadania:**
- Nóż: +100% szansa zabójstwa w bójce
- Telefon: +50% koordynacja gangów/ucieczek
- Narkotyki: +30% agresja, uzależnienie

**Rozwiązanie:**
- Regularne rewizje cel (1x/tydzień)
- Detektory metalu na wszystkich przejściach
- Kamery w obszarach ryzyka
- Psy patrolowe

### Wizyta VIP

**Częstość:** Rzadka (5% szansa/miesiąc)

**Mechanika:**
- Senator/dziennikarz chce zwiedzić więzienie
- Dostaje 2h na przygotowanie
- Ocenia: czystość, bezpieczeństwo, warunki, nastrój więźniów

**Skutki:**
- Pozytywna ocena: +$5,000 bonus, +0.5 gwiazdki
- Negatywna ocena: Krytyka w mediach, -0.5 gwiazdki

### Transfer groźnego więźnia

**Częstość:** Okazjonalnie (10% szansa/miesiąc)

**Mechanika:**
- Rząd oferuje transfer "special prisoner" (maksymalne zagrożenie)
- Oferta: +$2,000/dzień subwencja (zamiast $1,200)
- Ale: Ryzyko 50% bójki, 20% ucieczki, 10% zabójstwa
- Cecha specjalna: "Sławny" (media obserwują)

**Decyzja gracza:**
- Przyjąć (wysokie ryzyko, wysoka nagroda)
- Odrzucić (bezpiecznie)

### Kontrakt rządowy

**Częstość:** Co miesiąc

**Typy kontraktów:**
- "Osiągnij 0 ucieczek przez 60 dni" → Bonus $8,000
- "Utrzymaj średni nastrój >70% przez 30 dni" → Bonus $5,000
- "Zrehabilituj 20 więźniów (programy)" → Bonus $10,000
- "Rozbuduj więzienie do 100 miejsc" → Bonus $15,000

**Mechanika:**
- Gracz może przyjąć 1 kontrakt naraz
- Czas na wykonanie: 30-90 dni
- Nagroda po ukończeniu
- Brak kary za niepowodzenie (ale utrata szansy)

---

# PROGRESJA GRY

## Faza 1: Startup (Dzień 1-30)

### Stan początkowy
- Kapitał: $30,000
- Więźniowie: 0 (przybędą po zbudowaniu cel)
- Personel: 0 (gracz zatrudnia)
- Budynki: 0 (gracz buduje od zera)

### Cele fazy
- Zbuduj 20 cel (pojedynczych lub podwójnych)
- Zbuduj kantynę + kuchnię
- Zbuduj podwórko
- Zatrudnij 5 strażników, 2 kucharzy, 1 medyka
- Przyjmij pierwszych 20 więźniów (tylko niska kategoria)
- Osiągnij dodatni bilans finansowy

### Wyzwania
- Ograniczony budżet (łatwo zbankrutować)
- Brak doświadczenia (gracz uczy się mechanik)
- Pierwsze bójki (niska liczba strażników)
- Balans harmonogramu (głód, sen, praca)

### Milestone
✅ **"Stabilizacja"** - 30 dni z dodatnim bilansem, 0 ucieczek, 20 więźniów

## Faza 2: Ekspansja (Dzień 30-90)

### Cele fazy
- Rozbuduj do 50 cel
- Dodaj warsztaty (pralnia, stolarka)
- Zbuduj programy rehabilitacji (biblioteka, psycholog)
- Przyjmij więźniów średniej kategorii
- Osiągnij zysk netto >$2,000/dzień

### Wyzwania
- Pierwsze bunty (nastrój management)
- Mieszanie kategorii (bójki międzygrupowe)
- Zarządzanie personelem (3 zmiany, morale)
- Optymalizacja kosztów

### Milestone
✅ **"Rozwój"** - 50 więźniów, 2 warsztaty działają, reputacja 3 gwiazdki

## Faza 3: Dojrzałość (Dzień 90-180)

### Cele fazy
- 100+ więźniów
- Wszystkie kategorie zagrożenia (w tym maksymalna)
- Pełna infrastruktura (wszystkie typy pomieszczeń)
- Maksymalna efektywność ekonomiczna
- Reputacja 4+ gwiazdki

### Wyzwania
- Gangi (formowanie, rywalizacja)
- Groźni więźniowie (więcej incydentów)
- Utrzymanie bezpieczeństwa przy skali
- Koordynacja dużej liczby personelu

### Milestone
✅ **"Profesjonalista"** - 100 więźniów, zysk >$5,000/dzień, 4 gwiazdki

## Faza 4: Imperium (Dzień 180+)

### Cele fazy
- 200+ więźniów
- Wielosektorowe więzienie (podziały na skrzydła)
- Wszystkie technologie/ulepszenia odblokowane
- Najwyższa reputacja (5 gwiazdek)
- Samowystarczalność (zero dotacji rządowych)

### Wyzwania
- Skoordynowane bunty (wiele gangów naraz)
- Utrzymanie jakości przy ogromnej skali
- Minimalizacja kosztów przy maksymalizacji bezpieczeństwa
- Zarządzanie wieloma kryzysami jednocześnie

### Milestone
✅ **"Imperator"** - 200+ więźniów, 5 gwiazdek, zysk >$10,000/dzień, 365 dni bez ucieczek

## System reputacji (gwiazdki)

| Ocena | Wymagania | Bonusy |
|-------|-----------|--------|
| ⭐ | Podstawowe standardy (jedzenie, cele, bez tortur) | Brak bonusów |
| ⭐⭐ | + 0 ucieczek, <10 bójek/miesiąc, <5 śmierci/rok | +10% subwencja |
| ⭐⭐⭐ | + Programy rehabilitacji (min. 2 aktywne), nastrój śr. >60% | +25% subwencja |
| ⭐⭐⭐⭐ | + Niska recydywa (<20%), kontrakty spełniane | +50% subwencja, dostęp do groźnych więźniów |
| ⭐⭐⭐⭐⭐ | + Wzorcowe więzienie, wszystkie KPI na 100% | +100% subwencja, prestiż, specjalne kontrakty |

## Osiągnięcia (achievements)

| Osiągnięcie | Warunek | Nagroda |
|-------------|---------|---------|
| 🏆 **Nowy początek** | Przyjmij pierwszego więźnia | - |
| 🏆 **Bez ofiar** | 100 dni bez śmierci | Skin: "Humanitarne więzienie" |
| 🏆 **Twardogłowy** | Pacyfikuj bunt bez ustępstw (SWAT) | Skin: "Militarne" |
| 🏆 **Dyplomata** | Rozwiąż 5 buntów negocjacjami | Skin: "Nowoczesne" |
| 🏆 **Humanitarny** | Osiągnij 5⭐ z programami rehabilitacji | Bonus: +$10,000 |
| 🏆 **Alcatraz** | Zbuduj więzienie 200+ więźniów | Odblokowanie: Tryb "Maksimum" |
| 🏆 **Żelazna ręka** | Żadnej ucieczki przez 365 dni | Bonus: Specjalny kontrakt |
| 🏆 **Ekonomista** | Zysk >$10,000/dzień | Bonus: +$20,000 |
| 🏆 **Reformator** | 50 więźniów ukończyło rehabilitację | Skin: "Szwedzkie" |
| 🏆 **Przetrwanie** | Przetrwaj 3 bunty w ciągu roku | Odblokowanie: Tryb "Hardcore" |

---

# INTERFEJS UŻYTKOWNIKA

## Główny ekran gry

### Layout

```
┌─────────────────────────────────────────────────────────┐
│ [≡] Prison Tycoon    Dzień 45    [⏸️] [▶️x2] [⚙️]      │  Górny bar
├─────────────────────────────────────────────────────────┤
│ 💰 $45,000  |  👤 56/80  |  ⭐⭐⭐  |  ⚠️ 2 alerty      │  Status bar
├─────────────────────────────────────────────────────────┤
│                                                         │
│                                                         │
│                [WIDOK WIĘZIENIA]                        │  Główny viewport
│              Top-down, izometryczny                     │
│           Pinch zoom, przeciągnij kamera               │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏗️]   [👤]   [📅]   [💼]   [📊]   [⚡]              │  Dolny menu
│  Buduj  Więźn  Harmon Perso Stats  Alert              │
│         iowie  ogram  nel                              │
└─────────────────────────────────────────────────────────┘
```

### Elementy

**Górny bar:**
- [≡] Menu (pauza, opcje, zapisz, wyjdź)
- Dzień (licznik dni)
- [⏸️] Pauza
- [▶️] / [▶️x2] / [▶️x4] Prędkość gry
- [⚙️] Ustawienia

**Status bar:**
- 💰 Kapitał dostępny
- 👤 Więźniowie (aktualni/max pojemność)
- ⭐ Reputacja (gwiazdki)
- ⚠️ Alerty aktywne (kliknij → lista)

**Dolny menu:**
- Ikony kategorii akcji
- Kliknięcie otwiera panel z boku/dołu

## Panel budowy

Otwierany po kliknięciu [🏗️]

### Layout

```
┌────────────────────────────────────┐
│ 🏗️ BUDOWA                       X │
├────────────────────────────────────┤
│ [Pomieszczenia] [Przedmioty]       │
│ [Bezpieczeństwo] [Infrastruktura]  │
├────────────────────────────────────┤
│ ┌──────────────────────┐           │
│ │ 🛏️ Cela pojedyncza  │           │
│ │ 3x3 | 💰 $1,500      │           │
│ │ Pojemność: 1        │           │
│ │ [Buduj]             │           │
│ └──────────────────────┘           │
│                                    │
│ ┌──────────────────────┐           │
│ │ 🍽️ Kantyna          │           │
│ │ Min 10x10           │           │
│ │ 💰 $5,000           │           │
│ │ [Buduj]             │           │
│ └──────────────────────┘           │
│                                    │
│ ... (scroll więcej)                │
└────────────────────────────────────┘
```

### Tryb budowania

1. Gracz wybiera pomieszczenie
2. Widok przełącza się na "tryb budowy"
3. Prostokąt-siatka podświetla się (zielony = OK, czerwony = nie można)
4. Gracz przeciąga palcem aby wyznaczyć obszar
5. Pojawia się podgląd (transparentny budynek)
6. [✅ Potwierdź] [❌ Anuluj]

## Panel więźnia

Otwierany po kliknięciu na więźnia

### Layout

```
┌────────────────────────────────────┐
│ 👤 JOHN SMITH                  X  │
├────────────────────────────────────┤
│ #12345 | 32 lata                   │
│ Wyrok: 8 lat | Pozostało: 5 lat   │
│ Kategoria: 🟠 Średnia              │
├────────────────────────────────────┤
│ POTRZEBY:                          │
│ 🍎 Głód      ████████░░ 80%       │
│ 😴 Sen       ██████████ 100%      │
│ 🚿 Higiena    ████░░░░░░ 40%  ⚠️  │
│ 🌳 Wolność   ██████░░░░ 60%       │
│ 🛡️ Bezpiecz  ████░░░░░░ 40%  ⚠️  │
│ 🎮 Rozrywka  ████████░░ 75%       │
├────────────────────────────────────┤
│ ❤️ Zdrowie: 92%   😊 Nastrój: 68% │
├────────────────────────────────────┤
│ CECHY:                             │
│ ✅ Pracowity   ⚠️ Agresywny         │
├────────────────────────────────────┤
│ GANG: Bractwo (członek)            │
│ PRACA: Pralnia (08:00-12:00)       │
│ CELA: B-12 (podwójna)              │
├────────────────────────────────────┤
│ [Przenieś do innej celi]           │
│ [Wyślij do izolatki]               │
│ [Historia zachowania]              │
└────────────────────────────────────┘
```

## Panel harmonogramu

Otwierany po kliknięciu [📅]

### Layout

```
┌────────────────────────────────────┐
│ 📅 HARMONOGRAM                  X │
├────────────────────────────────────┤
│ Kategoria: [Niska ▼]               │
├────────────────────────────────────┤
│ Godzina  │ Aktywność    │ Miejsce  │
│──────────┼──────────────┼──────────│
│ 00-06    │ 😴 Sen       │ Cele     │
│ 06-07    │ 🍳 Śniadanie │ Kantyna  │
│ 07-08    │ 🚿 Higiena   │ Prysznic │
│ 08-12    │ 🔧 Praca     │ Warsztat │
│ 12-13    │ 🍽️ Obiad     │ Kantyna  │
│ ...                                 │
├────────────────────────────────────┤
│ [Edytuj godzinę] [Dodaj regułę]    │
│ [Kopiuj z innej kategorii]         │
│ [Reset do domyślnego]              │
└────────────────────────────────────┘
```

### Edycja

- Kliknięcie na godzinę otwiera dropdown z aktywnościami
- Możliwość przesunięcia bloków czasowych (drag)
- Zapisywanie customowych szablonów

## Panel personelu

Otwierany po kliknięciu [💼]

### Layout

```
┌────────────────────────────────────┐
│ 💼 PERSONEL                     X │
├────────────────────────────────────┤
│ [Strażnicy] [Medycy] [Inni]        │
├────────────────────────────────────┤
│ 👮 STRAŻNICY (12/15)               │
│                                    │
│ ┌──────────────────────┐           │
│ │ Mike Johnson         │           │
│ │ Zmiana: 1 (06-14)    │           │
│ │ Morale: 85%  ████████░│           │
│ │ Szkolenia: Walka, Taser│          │
│ │ [Szczegóły] [Zwolnij]│           │
│ └──────────────────────┘           │
│                                    │
│ ... (lista więcej)                 │
│                                    │
├────────────────────────────────────┤
│ [➕ Zatrudnij nowego] $150/dzień   │
└────────────────────────────────────┘
```

## Panel statystyk

Otwierany po kliknięciu [📊]

### Layout

```
┌────────────────────────────────────┐
│ 📊 STATYSTYKI                   X │
├────────────────────────────────────┤
│ [Finanse] [Bezpieczeństwo] [Więźn]│
├────────────────────────────────────┤
│ 💰 FINANSE                         │
│                                    │
│ Dzienny bilans:                    │
│   Przychody:     $8,500            │
│   Wydatki:      -$6,200            │
│   ─────────────────────            │
│   Zysk netto:   +$2,300/dzień     │
│                                    │
│ Kapitał: $45,000                   │
│                                    │
│ Wykres (30 dni):                   │
│ [Wykres liniowy przychodów]        │
│                                    │
├────────────────────────────────────┤
│ Szczegóły:                         │
│ - Subwencje:        $6,000         │
│ - Praca więźniów:   $1,500         │
│ - Kontrakty:        $1,000         │
│ - Pensje:          -$3,600         │
│ - Jedzenie:        -$1,400         │
│ - Media:           -$1,200         │
└────────────────────────────────────┘
```

Zakładki:
- **Finanse:** Bilans, wykresy, breakdown kosztów
- **Bezpieczeństwo:** Liczba bójek, ucieczek, incydentów (wykres trendu)
- **Więźniowie:** Nastrój średni, potrzeby, demografika

## Alerty

Pojawiają się jako powiadomienia push w interfejsie.

### Typy alertów

```
🔴 KRYTYCZNY (czerwony)
   Bunt w sektorze C!
   12 więźniów uczestniczy
   [Zobacz lokalizację] [SWAT]

🟠 WAŻNY (pomarańczowy)
   10 więźniów głodnych
   Harmonogram: Śniadanie za późno
   [Harmonogram] [OK]

🟡 INFORMACJA (żółty)
   Nowy więzień przybył
   John Doe - Średnie zagrożenie
   [Przypisz celę]

🟢 POZYTYWNY (zielony)
   Kontrakt rządowy ukończony
   Nagroda: +$8,000
   [Odbierz]
```

### Panel alertów

Lista wszystkich aktywnych alertów, sortowane po priorytecie.

```
┌────────────────────────────────────┐
│ ⚡ ALERTY                       X │
├────────────────────────────────────┤
│ 🔴 Bunt w sektorze C (5 min temu) │
│ 🟠 Bójka w kantynie (teraz)       │
│ 🟠 10 więźniów głodnych            │
│ 🟡 Inspekcja za 7 dni              │
│ 🟢 Dostawa z Ziemi dotarła        │
└────────────────────────────────────┘
```

## Legenda graficzna (minimap)

W prawym górnym rogu miniaturowa mapa całego więzienia.

**Kolory:**
- Szary: Budynki
- Niebieski: Niskie zagrożenie (więźniowie)
- Pomarańczowy: Średnie
- Czerwony: Wysokie
- Czarny: Maksymalne
- Granatowy: Strażnicy
- 🔴 Pulsujące: Incydent (bójka, alarm)

---

# STEROWANIE (MOBILE)

## Gesty podstawowe

| Gest | Działanie |
|------|-----------|
| **Przeciągnij** (1 palec) | Przesuń kamerę/widok mapy |
| **Pinch** (2 palce) | Zoom in/out |
| **Tap** | Zaznacz więźnia/budynek/strażnika |
| **Double tap** | Wyśrodkuj kamerę na obiekcie |
| **Long press** | Menu kontekstowe (więcej opcji) |
| **Swipe up** (dolny panel) | Rozwiń menu budowy/statystyk |

## Budowanie

**Tryb 1: Prostokąt (pomieszczenia)**
1. Wybierz pomieszczenie z menu [🏗️]
2. Ekran przełącza się w "tryb budowy"
3. **Przeciągnij** palcem aby narysować prostokąt
4. Podgląd pokazuje się w czasie rzeczywistym
5. **Tap [✅]** aby potwierdzić lub **[❌]** anuluj

**Tryb 2: Pojedynczy obiekt (drzwi, kamery)**
1. Wybierz obiekt
2. **Tap** na miejscu docelowym
3. Obiekt się stawia natychmiast

**Tryb 3: Ściana/ogrodzenie**
1. Wybierz typ ściany
2. **Przeciągnij** aby narysować linię
3. Ściana buduje się wzdłuż linii

## Selekcja i zarządzanie

**Zaznaczenie:**
- **Tap** na więźniu → Panel więźnia
- **Tap** na strażniku → Panel strażnika
- **Tap** na budynku → Panel budynku (info, demolish)
- **Tap** na pustym miejscu → Odznacz

**Multi-select (opcjonalnie):**
- **Long press + drag** → Zaznacz obszar
- Wszyscy więźniowie/strażnicy w obszarze → Grupowa akcja

## Skróty

- **Tap na alert** (górny bar) → Automatyczne przeniesienie kamery do incydentu
- **Double tap na minimap** → Przeskok kamery
- **Pinch na panelu** → Zwiń/rozwiń

---

# GRAFIKA I STYL

## Styl wizualny

**Inspiracja:** Prison Architect (główna), RimWorld (mechaniki), Theme Hospital (UI humor)

### Ogólny look
- **Widok:** Top-down (widok z góry), lekko izometryczny (2.5D)
- **Grafika:** 2D sprite-based, low-poly, minimalistyczna
- **Paleta:** Ograniczona, czytelna
- **Animacje:** Proste, funkcjonalne (nie przesadzone)

## Paleta kolorów

### Budynki i infrastruktura
- **Ściany zewnętrzne:** Szare, betonowe (#808080)
- **Ściany wewnętrzne:** Jaśniejsze szare (#A0A0A0)
- **Podłogi:** Jasny beton (#D0D0D0), lino (#C8C8A0)
- **Drzwi:** Brązowe drewno (#8B4513) lub szara stal (#606060)

### Pomieszczenia (identyfikacja)
- **Cele:** Szary + pomarańczowy akcent (łóżko)
- **Kantyna:** Brązowy (stoły drewniane)
- **Podwórko:** Zielony (trawa) lub betonowy (#B0B0B0)
- **Warsztaty:** Niebieski (maszyny)
- **Ambulatorium:** Biały + czerwony krzyż

### Postacie

**Więźniowie:**
- **Niskie zagrożenie:** Niebieski kombinezon (#4169E1)
- **Średnie:** Pomarańczowy (#FF8C00)
- **Wysokie:** Czerwony (#DC143C)
- **Maksymalne:** Czarny (#1C1C1C)

**Strażnicy:**
- Granatowy mundur (#000080)
- Czapka/hełm
- Pałka na pasku

**Personel cywilny:**
- Kucharz: Biały fartuch
- Medyk: Biały kitel + czerwony krzyż
- Psycholog: Garnitur szary
- Sprzątaczka: Zielony uniform

### UI i akcenty
- **Główny:** Ciemny granatowy (#1A237E)
- **Akcenty:** Niebieski (#2196F3)
- **Sukces:** Zielony (#4CAF50)
- **Ostrzeżenie:** Pomarańczowy (#FF9800)
- **Błąd:** Czerwony (#F44336)
- **Info:** Szary (#9E9E9E)

## Elementy graficzne

### Budynki (widok z góry)

**Cela (przykład):**
```
┌────────┐
│ 🛏️ 🚽  │  - Łóżko (sprite)
│        │  - Toaleta (sprite)
│        │  - Ściany grube linie
└────────┘
```

**Kantyna:**
```
┌──────────────┐
│ 🍽️ 🍽️ 🍽️     │  - Stoły (brązowe prostokąty)
│ 🍽️ 🍽️ 🍽️     │  - Ławki (ciemniejsze)
│              │
└──────────────┘
```

**Podwórko:**
```
┌──────────────┐
│ 🏀     🌳     │  - Kosz (sprite)
│       🏋️      │  - Drzewo (sprite zielony)
│     🏋️        │  - Ławki
└──────────────┘
```

### Postacie (sprite)

Proste sprite'y widziane z góry (jak w RimWorld):

**Więzień:**
- Owal/koło (głowa)
- Prostokąt (tułów)
- 2 linie (nogi)
- Kolor według kategorii
- Imię nad głową (tekst, mały)

**Strażnik:**
- Podobnie jak więzień
- Granatowy uniform
- Czapka/hełm (szczegół)
- Ikona pałki na pasku

**Animacje:**
- **Chodzenie:** 4 kierunki (góra, dół, lewo, prawo), 2 klatki (nogi)
- **Praca:** Ruch rąk (2 klatki)
- **Bójka:** Ruch w kierunku przeciwnika, efekt cząsteczek (uderzenie)
- **Sen:** Leżący sprite w celi

### Efekty specjalne

| Efekt | Wygląd | Kiedy |
|-------|--------|-------|
| **Bójka** | Chmura pyłu, gwiazdy, okrzyki "!" | Podczas bójki |
| **Alarm** | Czerwone migające światło, sygnał dźwiękowy | Kryzys |
| **Ogień** | Animowane płomienie (sprite, 3 klatki) | Pożar |
| **Krew** | Czerwone plamy na podłodze | Po bójce/zabiciu |
| **Dym** | Szare cząsteczki unoszące się | Pożar, generator |

### Ikony

Proste, czytelne ikony (flat design):

- 🍎 Jedzenie
- 💧 Woda
- ⚡ Energia
- 💰 Pieniądze
- 😴 Sen
- 🚿 Higiena
- 🏋️ Rekreacja
- 🔨 Budowa
- ⚠️ Ostrzeżenie
- 🔴 Kryzys

## Dźwięk i muzyka

### Muzyka
- **Menu główne:** Spokojny, industrialny ambient
- **Gra (normalna):** Napięta, ale nie przytłaczająca muzyka w tle
- **Gra (kryzys):** Intensywna, rytmiczna (bębny)
- **Bunt:** Dramatyczna, wysokie napięcie

### Efekty dźwiękowe

| Wydarzenie | Dźwięk |
|------------|--------|
| Kliknięcie UI | Subtelne "klik" |
| Budowa rozpoczęta | Młotki, piły (krótko) |
| Budowa ukończona | Dzwonek sukcesu |
| Bójka | Uderzenia, krzyki |
| Alarm | Głośna syrena (pulsująca) |
| Ucieczka | Gwizd, bieganie |
| Więzień głodny | Burczenie w brzuchu |
| Śmierć | Dramatyczny dźwięk, cisza |

### Ambient (tło)

- Ciche rozmowy więźniów (mruczenie)
- Kroki (tupanie)
- Zamykanie drzwi (metaliczne "klank")
- Szczęk kluczy (strażnicy)
- Odgłosy pracy (w warsztatach)

---

# MONETYZACJA

## Model biznesowy: Free-to-play (uczciwый)

### Wersja darmowa (100% rozgrywki)

**Zawiera:**
- Pełna kampania (wszystkie etapy)
- Tryb sandbox
- Wszystkie budynki i mechaniki
- Zapisywanie gry (3 sloty)
- Osiągnięcia

**Ograniczenia:**
- Reklamy opcjonalne (rewarded)
- Brak kosmetycznych dodatków

### Reklamy (opcjonalne, nie wymuszone)

**Rewarded ads** (gracz wybiera czy oglądać):

| Nagroda | Co dostaje | Częstość |
|---------|------------|----------|
| **Bonus gotówki** | $5,000 natychmiast | 1x/godzinę |
| **Przyspieszenie budowy** | Budynek gotowy od razu | 1x/dzień |
| **Uspokojenie napięcia** | -50% ryzyko buntu | 1x/dzień |
| **Leczenie masowe** | Wszyscy chorzy wyleczeni | 1x/dzień |

**NIE MA:**
- ❌ Wymuszone reklamy (full-screen interstitial)
- ❌ Banery podczas gry
- ❌ Reklamy wideo po każdej akcji

### Premium ($4.99 jednorazowo)

**Co kupujesz:**
- ❌ **Zero reklam** (opcja rewarded znika)
- 🏆 **Dodatkowe scenariusze:**
  - Więzienie kobiece (inne mechaniki)
  - Juvenile detention (młodociani)
  - Supermax (tylko najgroźniejsi)
- 🎨 **Ekskluzywne skiny:**
  - Futurystyczne (cyberpunk)
  - Retro (lata 60)
  - Luksusowe (5-gwiazdkowy hotel-więzienie)
- 📊 **Zaawansowane statystyki:**
  - Heatmapy (gdzie są bójki)
  - Predykcja buntów (AI)
  - Porównanie z innymi graczami
- 💾 **Nielimitowane sloty zapisu** (zamiast 3)

### IAP (In-App Purchases)

**Paczki kosmetyczne ($0.99-2.99):**
- Paczka skinów budynków "Nowoczesne" ($1.99)
- Paczka uniformów personelu "Militarne" ($0.99)
- Paczka dekoracji "Ogrody" ($1.99)

**Starter pack ($2.99):**
- $50,000 kapitału start
- 10 doświadczonych strażników
- Wszystkie pomieszczenia Tier 1 odblokowane
- Zalecane dla początkujących

**Scenariusze challenge ($0.99 każdy):**
- "Przejęcie" – napraw zrujnowane więzienie w 60 dni
- "Przeludnienie" – 200 więźniów, 100 miejsc
- "Zero budżetu" – zarabiaj tylko z pracy więźniów

### CZEGO NIE MA (anty-P2W)

- ❌ **Gemy/diamenty/premium currency**
- ❌ **Przyspieszenie za prawdziwe pieniądze** (poza rewarded ads)
- ❌ **Pay-to-win mechaniki** (płatne bonusy do bezpieczeństwa/produkcji)
- ❌ **Energia limitująca grę**
- ❌ **Timewalls** (oczekiwanie godzinami na budowę)
- ❌ **Lootboxy**
- ❌ **Subskrypcje**

---

# TRYBY GRY

## 1. Kampania (główny tryb)

### Struktura
- **10 rozdziałów** z progresywną trudnością
- Każdy rozdział = nowy kontrakt rządowy + wyzwania
- Tutorial wpleciony w pierwsze 3 rozdziały
- Narracja: transmisje od ministra sprawiedliwości

### Rozdziały (przykłady)

**Rozdział 1: "Nowy początek"**
- Cel: Zbuduj więzienie 20 cel, przyjmij 20 więźniów (niskie zagrożenie)
- Trudność: Łatwa
- Nagroda: $10,000 bonus

**Rozdział 2: "Rozbudowa"**
- Cel: Rozszerz do 50 więźniów, dodaj warsztaty
- Trudność: Łatwa
- Nagroda: Odblokowanie średniej kategorii więźniów

**Rozdział 3: "Pierwsze problemy"**
- Cel: Przetrwaj pierwszą bójkę, powstrzymaj ucieczkę
- Trudność: Średnia
- Nagroda: Odblokowanie szkoleń personelu

**Rozdział 5: "Zróżnicowanie"**
- Cel: Obsługuj wszystkie kategorie zagrożenia jednocześnie
- Trudność: Średnia
- Nagroda: $20,000 + reputacja 3⭐

**Rozdział 7: "Kryzys"**
- Cel: Przetrwaj organizowany bunt
- Trudność: Wysoka
- Nagroda: Odblokowanie SWAT team

**Rozdział 10: "Imperium"**
- Cel: 200 więźniów, 5⭐, zysk >$10,000/dzień
- Trudność: Bardzo wysoka
- Nagroda: Ukończenie kampanii, odblokowanie wszystkich trybów

## 2. Sandbox (kreatywny)

### Ustawienia

Gracz konfiguruje:
- **Kapitał startowy:** $10,000 - $1,000,000 - Nielimitowany
- **Wielkość mapy:** Mała / Średnia / Duża / Ogromna
- **Więźniowie:** Włącz/wyłącz kategorie
- **Kryzysy:** Włącz/wyłącz (bójki, ucieczki, bunty)
- **Trudność ekonomii:** Łatwa / Normalna / Trudna

### Cel
- Brak celów – swobodna kreatywność
- Gracz buduje więzienie swoich marzeń
- Testowanie mechanik
- Screenshoty (dla community)

## 3. Scenariusze (premium/IAP)

### Przejęcie
- **Stan:** Zrujnowane więzienie (50% budynków zniszczone)
- **Więźniowie:** 80, wszyscy niezadowoleni (nastrój 20%)
- **Kapitał:** $15,000 (dług $30,000)
- **Cel:** Napraw i osiągnij 3⭐ w 60 dni
- **Trudność:** Wysoka

### Maksimum
- **Więźniowie:** Tylko maksymalne zagrożenie (20 najgroźniejszych)
- **Kapitał:** $100,000
- **Cel:** Przetrwaj 180 dni bez ucieczek i buntów
- **Trudność:** Bardzo wysoka

### Przeludnienie
- **Więźniowie:** 200 więźniów
- **Miejsca:** 100 (cele dla 100)
- **Kapitał:** $50,000
- **Cel:** Zarządzaj kryzysem, rozbuduj do 200 miejsc w 90 dni
- **Trudność:** Wysoka

### Reforma
- **Więźniowie:** 100, mieszane kategorie
- **Kapitał:** $80,000
- **Cel:** Osiągnij 5⭐ w 365 dni (wzorcowe więzienie)
- **Trudność:** Średnia (wymaga strategii long-term)

### Więzienie kobiece (premium)
- **Mechanika:** Różne potrzeby (bezpieczeństwo vs wolność bardziej ważne)
- **Bójki:** Mniej częste, ale bardziej dramatyczne
- **Specjalnie:** Oddział matek z dziećmi (żłobek w więzieniu)

### Juvenile (premium)
- **Więźniowie:** 13-18 lat
- **Mechanika:** Edukacja > Praca
- **Cel:** Rehabilitacja (zmniejsz recydywę do <10%)
- **Specjalnie:** Szkoła obowiązkowa, psycholodzy

## 4. Daily Challenge

### Mechanika
- Każdy dzień nowe wyzwanie (generowane proceduralnie)
- Jedna próba (permadeath)
- Leaderboard globalny (top 100)
- Nagroda: Kosmetyki, osiągnięcia

### Przykłady

**Poniedziałek: "Szybka rozbudowa"**
- Start: $20,000, 0 więźniów
- Cel: 50 więźniów w 30 dni
- Ranking: Im szybciej, tym wyżej

**Wtorek: "Zero budżetu"**
- Start: $5,000, 20 więźniów
- Cel: Osiągnij zysk >$5,000/dzień w 60 dni
- Ranking: Wielkość zysku

**Środa: "Przetrwanie"**
- Start: Normalnie
- Trudność: Podwojone ryzyko bójek/ucieczek
- Cel: Przetrwaj 90 dni bez game over
- Ranking: Dni przetrwania

---

# IMPLEMENTACJA W GODOT 4

## Mocne strony Godot dla tej gry

### TileMap
- Wbudowany system tile-based (idealny dla więzienia na siatce)
- TileSet można skonfigurować z różnymi typami ścian, podłóg
- Automatyczne collision detection
- Łatwe rendering tysięcy tile'ów wydajnie

### Navigation2D
- Wbudowany pathfinding (A*)
- Więźniowie i strażnicy automatycznie znajdują drogę
- NavigationRegion2D dla pomieszczeń
- Można definiować koszty przejścia (korytarz vs cela)

### Area2D + CollisionShape2D
- Detekcja zasięgu (kamery CCTV, wieże strażnicze)
- Triggery (więzień wszedł do kantyny → jedzenie)
- Łatwe sprawdzanie "kto jest w pomieszczeniu"

### Signals (eventy)
- Event-driven gameplay
- Przykłady: "prisoner_started_fight", "building_completed", "riot_started"
- Łatwa komunikacja między systemami

### Node system
- Naturalna hierarchia:
  - Prison (root)
    - Buildings (Node2D)
      - Cell_01 (Area2D)
      - Canteen (Area2D)
    - Prisoners (Node2D)
      - Prisoner1 (CharacterBody2D)
    - Staff (Node2D)
- Możliwość tworzenia prefabów (scen) dla budynków, postaci

### Groups
- Łatwe grupowanie:
  - "prisoners_low", "prisoners_medium", etc.
  - "guards", "medics"
- Szybkie wyszukiwanie: `get_tree().get_nodes_in_group("guards")`

### CanvasLayer
- UI jako oddzielna warstwa (zawsze na wierzchu)
- Łatwe overlay (alerty, panele)

## Architektura wysokiego poziomu

### Struktura projektu

```
PrisonTycoon/
├── assets/
│   ├── sprites/
│   │   ├── buildings/
│   │   ├── prisoners/
│   │   ├── staff/
│   │   └── ui/
│   ├── tilesets/
│   │   ├── walls.tres
│   │   ├── floors.tres
│   │   └── outdoor.tres
│   └── audio/
│       ├── music/
│       ├── sfx/
│       └── ambient/
├── scenes/
│   ├── main.tscn                # Główna scena gry
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── build_menu.tscn
│   │   ├── prisoner_panel.tscn
│   │   └── alert.tscn
│   ├── buildings/
│   │   ├── cell.tscn
│   │   ├── canteen.tscn
│   │   ├── workshop.tscn
│   │   └── ...
│   ├── entities/
│   │   ├── prisoner.tscn
│   │   ├── guard.tscn
│   │   └── medic.tscn
│   └── menus/
│       ├── main_menu.tscn
│       └── settings.tscn
├── scripts/
│   ├── autoload/               # Singletons
│   │   ├── game_manager.gd
│   │   ├── economy_manager.gd
│   │   ├── schedule_manager.gd
│   │   └── event_manager.gd
│   ├── systems/
│   │   ├── pathfinding.gd
│   │   ├── needs_system.gd
│   │   ├── crisis_system.gd
│   │   └── gang_system.gd
│   ├── entities/
│   │   ├── prisoner.gd
│   │   ├── guard.gd
│   │   └── building.gd
│   └── ui/
│       ├── hud.gd
│       ├── build_menu.gd
│       └── ...
└── data/
    ├── buildings.json          # Dane budynków (koszt, rozmiar, etc.)
    ├── prisoner_names.json     # Imiona do generowania
    └── events.json             # Kryzysy, wydarzenia
```

### Główne systemy (singletony)

**GameManager** (autoload)
- Zarządzanie stanem gry (pauza, save/load)
- Czas gry (dzień, godzina)
- Prędkość gry (x1, x2, x4)

**EconomyManager**
- Kapitał, przychody, wydatki
- Obliczanie dziennego bilansu
- Bankructwo detection

**ScheduleManager**
- Harmonogramy dla każdej kategorii więźniów
- Aktualna aktywność dla każdego więźnia
- Powiadomienia o zmianach (pora jedzenia, lockdown)

**EventManager**
- Obsługa kryzysów (bójki, ucieczki, bunty)
- Losowe wydarzenia (inspekcja, kontrakty)
- System alertów dla gracza

### Kluczowe komponenty

**Prisoner (CharacterBody2D)**
- Atrybuty: needs (Dict), traits (Array), gang (String)
- Pathfinding (NavigationAgent2D)
- State machine: Idle, Walking, Working, Eating, Sleeping, Fighting, Escaping
- Sygnały: needs_changed, fight_started, died

**Guard (CharacterBody2D)**
- Patrol routes (Array of Vector2)
- State: Patrolling, Responding, Fighting, Resting
- Sygnały: prisoner_caught, fight_pacified

**Building (Area2D)**
- Typ, rozmiar, koszt
- Prisoners inside (Array)
- Production (dla warsztatów)
- Sygnały: prisoner_entered, prisoner_exited, destroyed

**Prison (Node2D - root)**
- TileMap (ściany, podłogi)
- NavigationRegion2D
- Kontenery na budynki, więźniów, personel

### Przepływ danych

1. **Inicjalizacja:**
   - Wczytaj dane z JSON (buildings, events, names)
   - Utwórz więzienie (TileMap, navigation)
   - Spawn początkowych więźniów/personelu

2. **Game Loop:**
   - `_process(delta)`: Update czasu gry, UI
   - `_physics_process(delta)`: Update pozycji postaci (pathfinding)
   - Timery dla: sprawdzanie potrzeb (co 1s), ekonomia (co 60s = 1h gry)

3. **Eventy:**
   - Prisoner.needs_changed → sprawdź czy trigger kryzysu
   - Building.prisoner_entered → aktualizuj stan (np. eating w kantynie)
   - EventManager.riot_started → powiadom gracza, zmień stan gry

4. **Zapisywanie:**
   - Serializacja do JSON: pozycje budynków, stany więźniów, kapitał, czas
   - Godot Resource system dla save slots

## Najważniejsze mechaniki do zaimplementowania

### 1. Budowanie (Tile-based)

- Gracz wybiera budynek
- Kamera przełącza się w tryb "ghost" (transparentny podgląd)
- Gracz przeciąga aby wyznaczyć prostokąt
- Walidacja (kolizje, budżet)
- Po potwierdzeniu: spawn sceny budynku, odejmij kapitał
- Automatyczne update NavigationRegion2D (więźniowie mogą chodzić)

### 2. Pathfinding więźniów

- Każdy więzień ma NavigationAgent2D
- Cel: get_target_position() z ScheduleManager (np. kantyna o 12:00)
- Agent automatycznie znajduje drogę
- Na końcu ścieżki: zmień stan (np. Eating)

### 3. System potrzeb

- Timer co 1s: update wszystkich prisoners
- Każda potrzeba (głód, sen, etc.) spada według formuły
- Jeśli potrzeba <30% → trigger zachowania (np. szukaj jedzenia)
- Jeśli potrzeba <10% → kryzys (bójka, ucieczka)

### 4. Bójki

- Trigger: 2 więźniów blisko siebie + warunki (niski nastrój, gang)
- Zmień state na Fighting
- Animacja (prosta)
- Co 1s: obrażenia (health -= 10)
- Strażnicy w zasięgu → automatycznie interweniują
- Pacyfikacja: zmień state na Restrained, teleport do izolatki

### 5. Harmonogram

- ScheduleManager: Dict[kategoria] → Dict[godzina] → aktywność
- Co godzinę (in-game): sygnał do wszystkich więźniów
- Więzień: sprawdź harmonogram → zmień cel (target_position)
- Lockdown: sygnał → wszyscy więźniowie → cel = cela

### 6. Ekonomia

- Timer co 60s (1h in-game)
- Update kapitału: += przychody, -= wydatki
- Przychody: subwencja (liczba więźniów) + praca (budynki produkcyjne)
- Wydatki: pensje (liczba personelu) + jedzenie + media

### 7. Eventy (losowe)

- Timer co 24h (in-game): losowanie wydarzenia
- RNG: szansa na inspekcję, epidemię, kontrabandę, etc.
- EventManager.trigger_event("epidemic") → mechanika specyficzna

## Optymalizacje wydajności

- **Object pooling:** Nie twórz/usuwaj więźniów często, użyj puli
- **Culling:** Renderuj tylko to co widać (Godot robi automatycznie)
- **Spatial hashing:** Dla detekcji kolizji (bójki) - grupuj więźniów wg obszaru
- **Throttling:** Nie aktualizuj AI co frame, np. co 0.1s

---

# PODSUMOWANIE

## Kluczowe wyróżniki gry

| Aspekt | Prison Tycoon | Konkurencja (Prison Architect) |
|--------|---------------|--------------------------------|
| **Platforma** | Mobile-first (touch optimized) | PC (mouse+keyboard) |
| **Głębokość** | Średnia, przystępna | Bardzo złożona |
| **Czas sesji** | 10-30 min (casual) | 1-3h (hardcore) |
| **Monetyzacja** | F2P uczciwa (bez P2W) | Płatna ($30) |
| **Grafika** | Minimalistyczna 2D | Bardziej detale |
| **Tutorial** | Wpleciony w kampanię | Osobne poziomy |

## Priorytety developmentu

### MVP (Minimum Viable Product)

**Faza 1 (4-6 tygodni):**
- System budowania (5 typów pomieszczeń)
- Więźniowie (podstawowe potrzeby: głód, sen)
- Harmonogram (prosty, stały)
- Ekonomia (przychody, wydatki, bilans)
- UI (HUD, build menu)

**Faza 2 (6-8 tygodni):**
- Więcej pomieszczeń (15 typów)
- Personel (strażnicy, kucharze, medycy)
- Kryzysy (bójki, ucieczki)
- Kategorie więźniów (niska, średnia, wysoka)
- Kampania (pierwsze 5 rozdziałów)

**Faza 3 (4-6 tygodni):**
- Gangi i hierarchia
- Bunty (pełna mechanika)
- Więcej eventów
- Sandbox mode
- Polish (animacje, dźwięki, balance)

**Launch (16-20 tygodni total)**

### Post-launch roadmap

**Wersja 1.1 (1 miesiąc po launch):**
- Daily challenges
- Leaderboardy
- Więcej osiągnięć

**Wersja 1.2 (3 miesiące):**
- Premium content (więzienie kobiece, juvenile)
- Nowe scenariusze

**Wersja 2.0 (6 miesięcy):**
- Multiplayer (wizyta w więzieniu znajomego)
- Współpraca (wymiana personelu)
- Rankingi globalne

## Sukces gry zależy od:

1. ✅ **Balance** – trudność nie może być frustrująca
2. ✅ **Feedback** – gracz musi widzieć skutki decyzji
3. ✅ **Progresja** – satysfakcja z rozbudowy
4. ✅ **Kryzysy** – napięcie, ale nie przytłaczające
5. ✅ **UI/UX** – intuicyjne dla mobile
6. ✅ **Performance** – 60 FPS nawet z 200 więźniami
7. ✅ **Monetyzacja** – uczciwa, bez P2W

---

**Koniec dokumentu**

Prison Tycoon - Mobile Management Sim
Wersja 1.0 - Game Design Document
