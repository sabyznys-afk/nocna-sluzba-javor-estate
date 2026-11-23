# NOČNÁ ZMENA: BLOK 14 — Map Layout & Coordinate Specification

All gameplay unfolds inside a single, densely detailed walled city block (**Blok 14 — Dvor sv. Kataríny**) measuring roughly `36m × 36m` horizontally across 4 vertical levels (`y = -3.2m` Sub-Cellar to `y = +7.2m` Rooftop Antenna).

## Coordinate System (Godot 3D: `+X` East, `+Z` South, `+Y` Up)

### Ground Level (`y = 0.0m`)
- **Courtyard (*Vnútorný dvor*)**: `X: -12m .. +12m`, `Z: -12m .. +12m`
  - **Medieval Well + Watchman's Clock #2 (`clock_well`)**: `(0.0, 0.0, 0.0)`
  - **Parked Škoda Favorit**: `(-5.5, 0.0, 4.5)`
  - **Trash Alcove (Milan "Krtko"'s Corner)**: `(9.5, 0.0, -8.0)`
  - **Overhead Flickering Sodium Lamp**: `(0.0, 5.8, 0.0)`
- **Vrátnica (Guard Booth) & Main Carriage Gate (*Brána*)**: South Wall `Z: +11m .. +15.5m`
  - **Main Iron Gate + Watchman's Clock #1 (`clock_gate`)**: `(0.0, 0.0, 14.5)`
  - **Guard Booth Interior**: `X: -5.5m .. -1.8m`, `Z: 10.5m .. 14.2m`
    - **Booth Desk / Dawn Logbook (`booth_desk`)**: `(-3.6, 0.9, 12.6)`
    - **Rotary Phone (`booth_phone`)**: `(-4.4, 1.0, 12.2)`
    - **Live 4-Camera CCTV CRT Monitor (`booth_cctv`)**: `(-2.8, 1.25, 11.8)`
- **Pasáž (Covered Arcade / West Wing)**: `X: -15.5m .. -12.0m`, `Z: -10m .. +10m`
  - **Hodinárstvo (Watchmaker's Shop + Backward Clock)**: `(-14.2, 0.0, 5.5)`
  - **Notary / Privatization Office**: `(-14.2, 0.0, -1.5)`
  - **Main Passage Fusebox (`fusebox_passage`)**: `(-12.3, 1.4, 2.0)`
  - **Dead Payphone (`payphone_passage`)**: `(-12.3, 1.4, -5.5)`

### Second Floor (`y = +3.6m`)
- **Pavlač (Open Tenement Gallery)**: Accessible via North-West Stone Staircase (`X: -10.5m`, `Z: -10.0m` → ascending East along `Z = -10.5m`).
  - **Watchman's Clock #3 (`clock_gallery`)**: `(0.0, 3.6, -10.6)`
  - **Flat 4 (Pani Mária's Apartment)**: `(-5.5, 3.6, -12.0)`
  - **Flat 7 (Enterable Vacant Flat + Sink/Mirror Anomaly)**: `(6.5, 3.6, -12.0)`
  - **Flat 9 (Mismatched Door)**: `(11.8, 3.6, -5.0)`
  - **13th Impossible Window Anchor (`ANOM_01`)**: `(12.0, 5.0, 2.0)` on East Courtyard Wall

### Rooftop & Attic (`y = +7.2m`)
- **Povala (Attic & STA Mast)**: Accessible via South-West Staircase (`X: -10.5m`, `Z: +7.5m` ascending from Pavlač).
  - **Jozef's Attic Stash (Brass Master Key & Tape #2)**: `(-9.5, 7.2, 9.0)`
  - **STA Rooftop TV Antenna Mast (`sta_antenna`)**: `(0.0, 7.2, -10.0)`

### Basement & Sub-Cellar (`y = -3.2m`)
- **Kotolňa & Pivnice (Boiler Room & Cellars)**: Accessible via North-East Cellar Stairs (`X: +10.0m`, `Z: -8.5m` descending South-East).
  - **Boiler Furnace & Pressure Valve (`boiler_valve`)**: `(10.0, -3.2, 3.5)`
  - **Watchman's Clock #4 (`clock_boiler`)**: `(7.2, -3.2, -3.5)`
  - **Jozef's Torn Page #1**: `(7.4, -2.0, -3.5)`
  - **The Red Iron Door (`red_door`)**: `(4.5, -3.2, 0.0)` leading West toward the medieval well root.
- **Bunker K-4 (1953 ŠtB Sub-Cellar Vault)**: `X: -4.0m .. +4.2m`, `Z: -4.0m .. +4.0m`, `y = -3.2m`
  - **Device K-4 Resonator Core (`device_k4`)**: `(0.0, -3.2, 0.0)`
  - **Jozef Bartoš NPC / Archive Key (`jozef_npc`)**: `(-2.5, -3.2, -2.0)`
  - **Elena's Concrete-Sealed Dossier (`elena_dossier`)**: `(1.8, -3.2, 2.8)`

---

## CCTV Camera Positions (`SubViewport 256×192` Cycles)
1. **CAM-01 — Courtyard Center**: Mounted high on South-West corner `(-11.0, 5.5, 10.5)` overlooking Well, Favorit, and North Gallery.
2. **CAM-02 — Pavlač Gallery**: Mounted at `(11.0, 5.2, -10.2)` looking West along the 2nd-floor wooden gallery and Flat 4 / Flat 7.
3. **CAM-03 — Vrátnica Exterior**: Mounted at `(-1.0, 3.4, 9.5)` pointing right back at the guard booth glass (`ANOM_08` Doppelgänger spawns here!).
4. **CAM-04 — Pasáž Arcade**: Mounted at `(-13.8, 3.2, 9.2)` looking North down the covered Passage past the Watchmaker's and Payphone.
