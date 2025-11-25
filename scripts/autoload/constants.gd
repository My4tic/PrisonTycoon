## Stałe globalne gry Prison Tycoon
## Autoload singleton dostępny jako Constants
extends Node

# =============================================================================
# GRID & TILES
# =============================================================================
const TILE_SIZE: int = 64  # Rozmiar pojedynczego tile'a w pikselach
const GRID_WIDTH: int = 100  # Maksymalna szerokość mapy w tile'ach
const GRID_HEIGHT: int = 100  # Maksymalna wysokość mapy w tile'ach

# =============================================================================
# CZAS GRY
# =============================================================================
const SECONDS_PER_GAME_MINUTE: float = 1.0  # 1 sekunda realna = 1 minuta w grze
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30

# Prędkości gry
const GAME_SPEEDS: Array[float] = [0.0, 1.0, 2.0, 4.0]  # Pauza, x1, x2, x4
const DEFAULT_GAME_SPEED_INDEX: int = 1  # x1

# =============================================================================
# EKONOMIA
# =============================================================================
const STARTING_CAPITAL: int = 30000

# Subwencje dzienne za więźnia (per kategoria)
const SUBSIDY_LOW_SECURITY: int = 500
const SUBSIDY_MEDIUM_SECURITY: int = 650
const SUBSIDY_HIGH_SECURITY: int = 800
const SUBSIDY_MAXIMUM_SECURITY: int = 1200

# Wydatki
const FOOD_COST_PER_PRISONER: int = 10  # dziennie
const FOOD_COST_TRAY_SERVICE: int = 15  # gdy dostarczane do cel
const UTILITY_BASE_COST: int = 50  # podstawowe media dziennie

# Pensje personelu (dziennie)
const SALARY_GUARD: int = 150
const SALARY_COOK: int = 100
const SALARY_MEDIC: int = 200
const SALARY_PSYCHOLOGIST: int = 250
const SALARY_JANITOR: int = 80
const SALARY_PRIEST: int = 120

# Pożyczka
const EMERGENCY_LOAN_AMOUNT: int = 20000
const EMERGENCY_LOAN_INTEREST: float = 0.10
const BANKRUPTCY_DAYS: int = 7  # Dni z ujemnym saldem do game over

# =============================================================================
# WIĘŹNIOWIE - POTRZEBY
# =============================================================================
# Decay rates (procent na godzinę gry)
const NEED_DECAY_HUNGER: float = 2.0
const NEED_DECAY_SLEEP: float = 1.5
const NEED_DECAY_HYGIENE: float = 3.0
const NEED_DECAY_FREEDOM: float = 2.0
const NEED_DECAY_SAFETY: float = 5.0  # Tylko gdy w pobliżu wrogów
const NEED_DECAY_ENTERTAINMENT: float = 1.0

# Progi potrzeb
const NEED_THRESHOLD_WARNING: float = 30.0
const NEED_THRESHOLD_CRISIS: float = 10.0

# Wartości zaspokojenia (procent)
const NEED_SATISFACTION_MEAL: float = 30.0
const NEED_SATISFACTION_SLEEP_HOUR: float = 12.5  # 8h = 100%
const NEED_SATISFACTION_SHOWER: float = 50.0
const NEED_SATISFACTION_YARD_HOUR: float = 15.0
const NEED_SATISFACTION_RECREATION_HOUR: float = 10.0

# =============================================================================
# WIĘŹNIOWIE - RYZYKO (procent)
# =============================================================================
const RISK_FIGHT_LOW: float = 5.0
const RISK_FIGHT_MEDIUM: float = 15.0
const RISK_FIGHT_HIGH: float = 30.0
const RISK_FIGHT_MAXIMUM: float = 50.0

const RISK_ESCAPE_LOW: float = 2.0
const RISK_ESCAPE_MEDIUM: float = 5.0
const RISK_ESCAPE_HIGH: float = 10.0
const RISK_ESCAPE_MAXIMUM: float = 20.0

# =============================================================================
# PERSONEL
# =============================================================================
# Ratio strażnik/więźniowie per kategoria
const GUARD_RATIO_LOW: int = 15
const GUARD_RATIO_MEDIUM: int = 10
const GUARD_RATIO_HIGH: int = 5
const GUARD_RATIO_MAXIMUM: int = 2

# Zasięgi detekcji (w tile'ach)
const GUARD_DETECTION_RANGE: int = 8
const CAMERA_DETECTION_RANGE: int = 5
const TOWER_DETECTION_RANGE: int = 20

# Efektywność detekcji kontrabandy (procent)
const DETECTION_METAL_DETECTOR: float = 80.0
const DETECTION_SEARCH: float = 60.0
const DETECTION_DOG: float = 70.0
const DETECTION_CAMERA: float = 40.0

# Czas pacyfikacji (sekundy gry)
const PACIFICATION_TIME: float = 30.0  # per 2 więźniów

# =============================================================================
# BUDYNKI - MINIMALNE ROZMIARY
# =============================================================================
const MIN_SIZE_CELL_SINGLE: Vector2i = Vector2i(3, 3)
const MIN_SIZE_CELL_DOUBLE: Vector2i = Vector2i(4, 4)
const MIN_SIZE_DORMITORY: Vector2i = Vector2i(8, 8)
const MIN_SIZE_KITCHEN: Vector2i = Vector2i(6, 6)
const MIN_SIZE_CANTEEN: Vector2i = Vector2i(10, 10)
const MIN_SIZE_YARD: Vector2i = Vector2i(10, 10)
const MIN_SIZE_WORKSHOP: Vector2i = Vector2i(8, 8)
const MIN_SIZE_INFIRMARY: Vector2i = Vector2i(5, 5)
const MIN_SIZE_SOLITARY: Vector2i = Vector2i(3, 3)

# =============================================================================
# KAMERA
# =============================================================================
const CAMERA_ZOOM_MIN: float = 0.5
const CAMERA_ZOOM_MAX: float = 2.0
const CAMERA_ZOOM_SPEED: float = 0.1
const CAMERA_PAN_SPEED: float = 500.0

# =============================================================================
# UI
# =============================================================================
const TOUCH_MIN_SIZE: int = 44  # Minimalna wielkość elementu dotyku (dp)
const ALERT_AUTO_DISMISS_TIME: float = 5.0  # Sekundy do auto-hide alertu

# =============================================================================
# KRYZYSY
# =============================================================================
const FIGHT_DAMAGE_PER_SECOND: float = 10.0
const ESCAPE_PENALTY_MONEY: int = 5000
const ESCAPE_PENALTY_REPUTATION: float = 0.5

const RIOT_MOOD_THRESHOLD: float = 30.0  # Procent nastroju więźniów
const RIOT_PARTICIPANT_PERCENT: float = 50.0  # Procent więźniów do triggera

# =============================================================================
# HARMONOGRAM - DOMYŚLNE GODZINY
# =============================================================================
const SCHEDULE_WAKE_UP: int = 6
const SCHEDULE_BREAKFAST: int = 7
const SCHEDULE_WORK_START: int = 9
const SCHEDULE_LUNCH: int = 12
const SCHEDULE_WORK_END: int = 17
const SCHEDULE_DINNER: int = 18
const SCHEDULE_FREE_TIME: int = 19
const SCHEDULE_LOCKDOWN: int = 22

# =============================================================================
# NAWIGACJA
# =============================================================================
const PATHFINDING_UPDATE_INTERVAL: float = 0.5  # Sekundy między aktualizacjami
