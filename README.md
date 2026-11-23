# NIGHT SHIFT: THE JAVOR ESTATE (*Nočná Služba*)

> ### 🤖 FOR AI AGENTS & COLLABORATORS — START HERE!
> **Read [`TODO.md`](./TODO.md) and [`AGENTS.md`](./AGENTS.md) immediately upon opening this repository.**
> `TODO.md` contains the complete, priority-ordered handoff checklist for **Prompt 09 (Major Immersion Update)** — clearly separating completed work from the exact next tasks to implement and verify.

---

## Overview

**NIGHT SHIFT: THE JAVOR ESTATE** is a 1996 Central European PS1-inspired 3D pixelated first-person psychological horror thriller built in **Godot 4 (`GL Compatibility`)**.

You play as **Martin Kováč**, a new night security guard assigned to six escalating midnight-to-dawn shifts across a foggy prefabricated residential estate (**Súbor Javor / Block 14**). Armed only with a physical shift notebook, halogen flashlight, guard keyring, VHF radio, taser, and Walkman headphones, you patrol apartment blocks, courtyards, garages, shops, parks, and hidden maintenance corridors alongside veteran mentor **Jozef Varga** as ordinary residential routine gradually unravels into a grounded criminal mystery.

## Key Features Implemented
- **PS1-Inspired Low-Poly 3D Pixelated Visual Pipeline**: Configurable internal resolution (`426×240` / `512×288` / `640×360`), Bayer 4×4 ordered dithering, vertex snapping, nearest-neighbor textures, dynamic shadow-casting flashlight, and readable night lighting with live calibration settings.
- **Organic Low-Poly Character Cast (Prompt 09 Part 2 Complete)**: 14 custom Blender low-poly models (`assets/models/char_*.glb`) with sculpted organic heads (jawline, cheekbones, 3D nose, 3D ears), sculpted 3D hairstyles, and `256×256` / `128×128` / `64×64` pixelated face textures (`assets/textures/ps1_faces/`).
- **Physical Navigation & Companion AI**: Baked estate `NavigationRegion3D` (2,006 walkable polygons), solid `CharacterBody3D` collision on Jozef Varga and residents, hinged physical doors with locks & latches, and `F8` live navigation debugger.
- **Immersive Diegetic Interface**: Zero permanent HUD quest clutter — Martin relies on his 4-section physical paper **Shift Notebook** (`SHIFT | MAP | NOTES | EVIDENCE`), bottom equipment hotbar (`0–6` / mouse wheel), and Walkman headphones (calms strain while muffling environmental threat audio).
- **6-Night Campaign & 3 Endings**: Full story progression with interactive 8-stage Night 1 training tutorial, 48 English neural voice clips, spatial resident speech, CCTV monitoring, evidence collection, and multiple endings.

## Controls
| Input | Action |
|---|---|
| `WASD` / `Mouse` | Move / Look |
| `Shift` | Sprint (uses stamina) |
| `E` | Interact / Talk / Open Door / Inspect |
| `L` | Lock / Unlock Door (with Keys equipped) |
| `F` | Toggle Flashlight ON / OFF |
| `0–6` / `Mouse Wheel` | Switch Belt Gear (`0` Empty Hands, `1` Torch, `2` Taser, `3` Keys, `4` Radio, `5` Watch, `6` Logbook) |
| `Tab` / `N` | Open / Close Shift Notebook |
| `H` | Toggle Walkman Headphones |
| `F8` | Toggle Developer Navigation Debugger |
| `Esc` | Pause / Close Modal |

## Running the Game
1. Install **Godot 4.7+** (GL Compatibility renderer).
2. Double-click `play_game.bat` (or open `project.godot` in Godot Editor and press `F5`).

## Automated Verification Suites
```powershell
godot --headless --path . --import --quit
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/verify_game.gd
godot --headless --path . --script res://tests/verify_campaign.gd
godot --headless --path . --script res://tests/verify_ps1_transformation.gd
godot --headless --path . --script res://tests/verify_prompt08_acceptance.gd
```

## Active Development Roadmap
See **[`TODO.md`](./TODO.md)** for the complete Prompt 09 task breakdown and acceptance checklist.
