## Globalny bus sygnałów Prison Tycoon
## Autoload singleton dostępny jako Signals
## Służy do komunikacji między systemami bez bezpośrednich zależności
extends Node

# =============================================================================
# STAN GRY
# =============================================================================
## Emitowany gdy zmienia się stan gry
signal game_state_changed(old_state: int, new_state: int)

## Emitowany gdy gra zostaje zapauzowana/odpauzowana
signal game_paused(is_paused: bool)

## Emitowany gdy zmienia się prędkość gry
signal game_speed_changed(speed_index: int, speed_multiplier: float)

## Emitowany o północy (nowy dzień)
signal day_changed(day: int)

## Emitowany co godzinę w grze
signal hour_changed(hour: int)

# =============================================================================
# EKONOMIA
# =============================================================================
## Emitowany gdy zmienia się kapitał
signal capital_changed(old_value: int, new_value: int)

## Emitowany codziennie z podsumowaniem bilansu
signal daily_balance_calculated(revenue: int, expenses: int, balance: int)

## Emitowany gdy gracz jest bliski bankructwa
signal low_capital_warning(current_capital: int, days_in_debt: int)

## Emitowany przy bankructwie
signal bankruptcy()

## Emitowany gdy zaciągnięto pożyczkę
signal loan_taken(amount: int)

# =============================================================================
# BUDOWANIE
# =============================================================================
## Emitowany przy rozpoczęciu trybu budowania
signal build_mode_entered(building_type: int)

## Emitowany przy wyjściu z trybu budowania
signal build_mode_exited()

## Emitowany gdy budynek zostaje umieszczony
signal building_placed(building_type: int, position: Vector2i, size: Vector2i)

## Emitowany gdy budynek zostaje usunięty
signal building_removed(building_type: int, position: Vector2i)

## Emitowany gdy budowa się zakończyła
signal building_completed(building_id: int)

## Emitowany przy nieudanej próbie budowy
signal building_placement_failed(reason: String)

## Emitowany gdy siatka nawigacji wymaga aktualizacji
signal navigation_update_required()

## Emitowany gdy ściana zostaje postawiona
signal wall_placed(position: Vector2i, wall_type: int)

## Emitowany gdy ściana zostaje usunięta
signal wall_removed(position: Vector2i)

# =============================================================================
# WIĘŹNIOWIE
# =============================================================================
## Emitowany gdy nowy więzień przybywa
signal prisoner_arrived(prisoner_id: int, security_category: int)

## Emitowany gdy więzień opuszcza więzienie (koniec wyroku)
signal prisoner_released(prisoner_id: int)

## Emitowany gdy więzień ucieka
signal prisoner_escaped(prisoner_id: int)

## Emitowany gdy więzień umiera
signal prisoner_died(prisoner_id: int, cause: String)

## Emitowany gdy zmienia się stan więźnia
signal prisoner_state_changed(prisoner_id: int, old_state: int, new_state: int)

## Emitowany gdy potrzeba spada poniżej progu ostrzeżenia
signal prisoner_need_warning(prisoner_id: int, need_type: int, value: float)

## Emitowany gdy potrzeba spada poniżej progu krytycznego
signal prisoner_need_critical(prisoner_id: int, need_type: int, value: float)

## Emitowany gdy więzień zostaje przydzielony do celi
signal prisoner_assigned_cell(prisoner_id: int, cell_id: int)

## Emitowany gdy więzień zostaje przydzielony do pracy
signal prisoner_assigned_work(prisoner_id: int, workplace_id: int)

## Emitowany gdy więzień zostaje wysłany do izolatki
signal prisoner_sent_to_solitary(prisoner_id: int, days: int)

## Emitowany gdy zmienia się liczba więźniów
signal prisoner_count_changed(count: int)

# =============================================================================
# PERSONEL
# =============================================================================
## Emitowany gdy nowy pracownik zostaje zatrudniony (staff_type dla prostego API)
signal staff_hired(staff_type: int)

## Emitowany gdy pracownik zostaje zwolniony (staff_type dla prostego API)
signal staff_fired(staff_type: int)

## Emitowany gdy pracownik zostaje ranny
signal staff_injured(staff_id: int)

## Emitowany gdy pracownik ginie
signal staff_killed(staff_id: int)

## Emitowany gdy zmienia się morale pracownika
signal staff_morale_changed(staff_id: int, new_morale: float)

## Emitowany gdy pracownik odchodzi z pracy (niskie morale)
signal staff_quit(staff_id: int)

# =============================================================================
# HARMONOGRAM
# =============================================================================
## Emitowany gdy zmienia się aktywność w harmonogramie
signal schedule_activity_changed(security_category: int, hour: int, activity: int)

## Emitowany gdy rozpoczyna się nowa aktywność
signal schedule_activity_started(security_category: int, activity: int)

## Emitowany gdy włączony zostaje lockdown
signal lockdown_started(reason: String)

## Emitowany gdy lockdown zostaje wyłączony
signal lockdown_ended()

# =============================================================================
# KRYZYSY I WYDARZENIA
# =============================================================================
## Emitowany gdy rozpoczyna się bójka
signal fight_started(location: Vector2i, prisoner_ids: Array)

## Emitowany gdy bójka się kończy
signal fight_ended(location: Vector2i, injuries: int)

## Emitowany gdy wykryto próbę ucieczki
signal escape_attempt_detected(prisoner_id: int, location: Vector2i)

## Emitowany gdy rozpoczyna się bunt
signal riot_started(participant_count: int)

## Emitowany gdy bunt się kończy
signal riot_ended(damages: int, casualties: int)

## Emitowany gdy napięcie rośnie
signal tension_rising(tension_level: float)

## Emitowany gdy znaleziono kontrabandę
signal contraband_found(prisoner_id: int, contraband_type: int)

## Emitowany gdy rozpoczyna się epidemia
signal epidemic_started(disease_type: String)

## Emitowany gdy epidemia się kończy
signal epidemic_ended()

## Emitowany gdy tworzony jest nowy gang
signal gang_formed(gang_id: int, leader_id: int)

# =============================================================================
# ALERTY UI
# =============================================================================
## Emitowany gdy trzeba wyświetlić alert
signal alert_triggered(priority: int, title: String, message: String, location: Vector2i)

## Emitowany gdy alert zostaje zamknięty
signal alert_dismissed(alert_id: int)

# =============================================================================
# KAMERA
# =============================================================================
## Emitowany gdy kamera ma się skupić na lokacji
signal camera_focus_requested(position: Vector2, zoom: float)

## Emitowany gdy zoom się zmienia
signal camera_zoom_changed(zoom_level: float)

# =============================================================================
# PROGRESJA
# =============================================================================
## Emitowany gdy zmienia się reputacja
signal reputation_changed(old_level: int, new_level: int)

## Emitowany gdy dostępny jest nowy kontrakt
signal contract_available(contract_id: int)

## Emitowany gdy kontrakt zostaje ukończony
signal contract_completed(contract_id: int, reward: int)

## Emitowany gdy osiągnięcie zostaje odblokowane
signal achievement_unlocked(achievement_id: String)

# =============================================================================
# ZAPIS/WCZYTANIE
# =============================================================================
## Emitowany gdy gra zostaje zapisana
signal game_saved(slot: int)

## Emitowany gdy gra zostaje wczytana
signal game_loaded(slot: int)

## Emitowany gdy zapis się nie udał
signal save_failed(reason: String)

# =============================================================================
# INPUT
# =============================================================================
## Emitowany gdy obiekt zostaje wybrany (klik/tap)
signal object_selected(object_type: String, object_id: int)

## Emitowany gdy selekcja zostaje anulowana
signal selection_cleared()

## Emitowany przy długim przytrzymaniu
signal long_press(position: Vector2)

## Emitowany przy podwójnym kliknięciu/tap
signal double_tap(position: Vector2)
