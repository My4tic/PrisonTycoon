## Enumeracje globalne gry Prison Tycoon
## Autoload singleton dostępny jako Enums
extends Node

# =============================================================================
# STAN GRY
# =============================================================================
enum GameState {
	MENU,           # Menu główne
	LOADING,        # Ładowanie
	PLAYING,        # Rozgrywka aktywna
	PAUSED,         # Pauza
	BUILD_MODE,     # Tryb budowania
	GAME_OVER,      # Koniec gry
	VICTORY         # Zwycięstwo (scenariusz)
}

# =============================================================================
# WIĘŹNIOWIE
# =============================================================================
enum SecurityCategory {
	LOW,            # Niskie zagrożenie (niebieski)
	MEDIUM,         # Średnie zagrożenie (pomarańczowy)
	HIGH,           # Wysokie zagrożenie (czerwony)
	MAXIMUM         # Maksymalne zabezpieczenie (czarny)
}

enum PrisonerState {
	IDLE,           # Bezczynny
	WALKING,        # Idzie do celu
	EATING,         # Je posiłek
	SLEEPING,       # Śpi
	SHOWERING,      # Kąpie się
	WORKING,        # Pracuje
	RECREATION,     # Rekreacja
	FIGHTING,       # Bójka
	ESCAPING,       # Ucieczka
	IN_SOLITARY,    # W izolatce
	IN_INFIRMARY,   # W ambulatorium
	LOCKDOWN        # Lockdown w celi
}

enum PrisonerNeed {
	HUNGER,         # Głód
	SLEEP,          # Sen
	HYGIENE,        # Higiena
	FREEDOM,        # Wolność
	SAFETY,         # Bezpieczeństwo
	ENTERTAINMENT   # Rozrywka
}

enum PrisonerTrait {
	AGGRESSIVE,     # Agresywny - zwiększone ryzyko bójek
	PEACEFUL,       # Spokojny - zmniejszone ryzyko bójek
	HARDWORKING,    # Pracowity - lepsza produktywność
	LAZY,           # Leniwy - gorsza produktywność
	INTELLIGENT,    # Inteligentny - szybsza nauka, lepsze ucieczki
	ESCAPIST,       # Zbieg - zwiększone ryzyko ucieczki
	SNITCH,         # Kapuś - informuje o kontrabandzie
	GANG_LEADER,    # Lider gangu
	ADDICT,         # Uzależniony - szuka narkotyków
	PSYCHOPATH,     # Psychopata - nieprzewidywalny
	STRONG,         # Silny - więcej obrażeń w bójce
	WEAK,           # Słaby - mniej obrażeń w bójce
	VOLATILE        # Wybuchowy - szybko reaguje agresją
}

enum CrimeType {
	THEFT,          # Kradzież
	BURGLARY,       # Włamanie
	FRAUD,          # Oszustwo
	DRUG_DEALING,   # Handel narkotykami
	ASSAULT,        # Pobicie
	ARMED_ROBBERY,  # Napad z bronią
	MURDER,         # Morderstwo
	SERIAL_MURDER,  # Seryjne morderstwo
	TERRORISM       # Terroryzm
}

# =============================================================================
# PERSONEL
# =============================================================================
enum StaffType {
	GUARD,          # Strażnik
	COOK,           # Kucharz
	MEDIC,          # Medyk
	PSYCHOLOGIST,   # Psycholog
	JANITOR,        # Sprzątacz
	PRIEST,         # Kapłan
	SNIPER,         # Snajper (wieża)
	WARDEN          # Naczelnik
}

enum StaffState {
	IDLE,           # Bezczynny
	PATROLLING,     # Patroluje
	RESPONDING,     # Reaguje na incydent
	PACIFYING,      # Pacyfikuje bójkę
	WORKING,        # Wykonuje pracę
	RESTING,        # Odpoczywa
	HEALING,        # Leczy (medyk)
	OFF_DUTY        # Po służbie
}

enum Shift {
	MORNING,        # 06:00 - 14:00
	AFTERNOON,      # 14:00 - 22:00
	NIGHT           # 22:00 - 06:00
}

# =============================================================================
# BUDYNKI
# =============================================================================
enum BuildingCategory {
	CELLS,          # Cele mieszkalne
	FOOD,           # Wyżywienie
	RECREATION,     # Rekreacja
	WORK,           # Praca i produkcja
	INFRASTRUCTURE, # Infrastruktura
	SECURITY        # Bezpieczeństwo
}

enum BuildingType {
	# Cele
	CELL_SINGLE,
	CELL_DOUBLE,
	DORMITORY,
	CELL_LUXURY,
	SOLITARY,

	# Wyżywienie
	KITCHEN,
	CANTEEN,

	# Rekreacja
	YARD,
	GYM,
	LIBRARY,
	CHAPEL,
	TV_ROOM,

	# Praca
	LAUNDRY,
	WORKSHOP_CARPENTRY,
	GARDEN,
	CALL_CENTER,

	# Infrastruktura
	INFIRMARY,
	GUARD_ROOM,
	RECEPTION,
	STORAGE,
	GENERATOR,
	SHOWER_ROOM,

	# Bezpieczeństwo
	CAMERA,
	METAL_DETECTOR,
	ALARM,
	GUARD_TOWER,
	CHECKPOINT
}

enum WallType {
	WOOD,           # Drewno - tanie, słabe
	BRICK,          # Cegła - standard
	CONCRETE,       # Beton - mocne
	STEEL           # Stal - maksymalne
}

enum DoorType {
	BASIC,          # Zwykłe drzwi
	LOCKED,         # Z zamkiem
	STEEL,          # Stalowe
	AUTOMATIC,      # Brama automatyczna
	CHECKPOINT      # Z detektorem
}

# =============================================================================
# HARMONOGRAM
# =============================================================================
enum ScheduleActivity {
	SLEEP,          # Sen (lockdown w celach)
	EATING,         # Posiłki
	HYGIENE,        # Prysznice
	WORK,           # Praca w warsztatach
	RECREATION,     # Rekreacja (podwórko, siłownia, biblioteka)
	FREE_TIME,      # Wolny czas
	LOCKDOWN        # Lockdown przymusowy
}

# =============================================================================
# KRYZYSY I WYDARZENIA
# =============================================================================
enum EventType {
	FIGHT,          # Bójka
	ESCAPE_ATTEMPT, # Próba ucieczki
	ESCAPE_SUCCESS, # Udana ucieczka
	CONTRABAND,     # Znaleziono kontrabandę
	RIOT,           # Bunt
	EPIDEMIC,       # Epidemia
	DEATH,          # Śmierć więźnia
	STAFF_INJURED,  # Ranny personel
	STAFF_KILLED,   # Zabity personel
	GANG_FORMED,    # Utworzono gang
	CONTRACT_OFFER, # Oferta kontraktu
	INSPECTION      # Inspekcja
}

enum AlertPriority {
	CRITICAL,       # Czerwony - natychmiastowa reakcja
	IMPORTANT,      # Pomarańczowy - ważne
	INFO,           # Żółty - informacja
	POSITIVE        # Zielony - pozytywne
}

enum CrisisState {
	NORMAL,         # Normalny stan
	TENSION,        # Napięcie (warning)
	CRISIS,         # Kryzys aktywny
	EMERGENCY       # Stan wyjątkowy
}

enum ContrabandType {
	PHONE,          # Telefon
	DRUGS,          # Narkotyki
	KNIFE,          # Nóż
	ALCOHOL,        # Alkohol
	TOOLS           # Narzędzia (do ucieczki)
}

# =============================================================================
# PROGRESJA
# =============================================================================
enum ReputationLevel {
	ONE_STAR,       # 1 gwiazdka
	TWO_STARS,      # 2 gwiazdki
	THREE_STARS,    # 3 gwiazdki
	FOUR_STARS,     # 4 gwiazdki
	FIVE_STARS      # 5 gwiazdek
}

enum GameMode {
	CAMPAIGN,       # Kampania
	SANDBOX,        # Sandbox
	SCENARIO        # Scenariusz
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}
