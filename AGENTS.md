# Ztoryc — AI Agent Rules

> This file is read automatically by Claude Code, Codex, Cursor, Copilot, and Windsurf.
> The canonical copy lives in `~/ZtorYc/AGENTS.md`.
> In the code repo (`/Volumes/ZioSam/tahoma2d-workspace/tahoma2d/`) CLAUDE.md is a
> symlink to this file, or a copy of it.

-----

## Project Overview

Ztoryc is a fork of Tahoma2D 1.6.0 that adds an integrated storyboard and animatic
pipeline for 2D animation pre-production. It is the first open-source storyboard tool
designed to work natively inside an animation application.

- **Repository:** https://github.com/matitanimata/ztoryc
- **Base:** Tahoma2D 1.6.0 (BSD 2-Clause License)
- **Code workspace (Claude Code):** `/Volumes/ZioSam/tahoma2d-workspace/tahoma2d`
- **Code backup (Cowork):** `~/ZtorYc/tahoma2d-workspace_local/tahoma2d`
- **Planning docs:** `~/ZtorYc/` (AGENTS.md, CHANGELOG.md, ANIMATIC_TASKS.md, DESIGN.md)
- **Language:** C++17, Qt5
- **Build system:** CMake + Ninja

-----

## Folder Structure

```
~/ZtorYc/
├── AGENTS.md                    ← questo file (canonical)
├── CHANGELOG.md                 ← symlink → Google Drive/Ztoryc/CHANGELOG.md
├── ANIMATIC_TASKS.md            ← symlink → Google Drive/Ztoryc/ANIMATIC_TASKS.md
├── DESIGN.md                    ← specifica funzionale
├── README.md                    ← readme pubblico
├── tahoma2d-workspace_local/    ← backup codice (rsync da ZioSam dopo ogni commit)
│   └── tahoma2d/
└── tahoma2d-workspace_bak/      ← snapshot storico (non modificare)
    └── tahoma2d/
```

> **CHANGELOG.md e ANIMATIC_TASKS.md sono symlink a Google Drive** (`Il mio Drive/Ztoryc/`).
> Qualsiasi scrittura su questi file aggiorna automaticamente Drive e quindi
> è visibile a Claudio Paddei (Claude su iPad). All'avvio di "nuova sessione"
> leggere sempre da `~/ZtorYc/` — se Claudio ha fatto modifiche su iPad,
> Drive le avrà sincronizzate e saranno già presenti via symlink.

-----

## Build & Run

> ⚠️ REGOLA OBBLIGATORIA: usare SEMPRE `./build_and_deploy.sh` per compilare.
> MAI eseguire ninja direttamente e poi aprire l'app — i binari helper
> `lzocompress`/`lzodecompress` non vengono copiati nel bundle e il salvataggio
> TLV crasha silenziosamente senza messaggi di errore.

```bash
# Build + deploy (SEMPRE usare questo)
cd /Volumes/ZioSam/tahoma2d-workspace/tahoma2d
./build_and_deploy.sh [file.cpp opzionale da toccare]

# Forza ricompilazione file specifico
./build_and_deploy.sh toonz/sources/toonz/ztoryanimatic.cpp
```

**Solo per debug rapido (senza aprire l'app):**
```bash
touch [file] && ninja -j4 -C /Volumes/ZioSam/tahoma2d-workspace/tahoma2d/toonz/build 2>&1 | grep "error:" | head -10
# Poi OBBLIGATORIAMENTE: ./build_and_deploy.sh prima di aprire l'app
```

-----

## Main Ztoryc Files

```
toonz/sources/toonz/storyboardpanel.h/.cpp   — Board room, shot grid UI
toonz/sources/toonz/ztorymodel.h/.cpp        — Singleton data model
toonz/sources/toonz/ztoryanimatic.h/.cpp     — Animatic panel + viewer
toonz/sources/toonz/ztorybackpanel.h/.cpp    — Back to storyboard button
```

-----

## Architecture

### Core Concept

- Main xsheet = one column per shot
- Each shot = a sub-scene (subxsheet)
- Metadata saved in `.ztoryc` XML file alongside `.tnz`

### Key Classes

- `ZtoryModel` — singleton, owns `std::vector<ShotData>`
- `StoryboardPanel` — BOARD room, shot grid
- `ZtoryAnimaticPanel` — ANIMATIC room, NLE-style timeline
- `ZtoryAnimaticViewer` — inherits `BaseViewerPanel`, `m_alwaysMainXsheet=true`
- `ZtoryAnimaticTrack` — shot blocks, zoom, ripple edit
- `ZtoryAnimaticRuler` — time ruler

### Important Rules

- Shot duration = cells in main xsheet from `getRange()` (including empty/red cells)
- In/Out markers = play range inside sub-scene, NOT animatic duration
- Audio = main xsheet only, never in sub-scenes
- Camera = edited inside sub-scene only, not from animatic
- Thumbnail refresh = on `frameSwitched` with 1000ms debounce, NOT on `xsheetChanged`
- Copy = shared instance | Clone = fully independent sub-scene

### Board ↔ Animatic sync — REGOLA CRITICA

**Non emettere mai `shotAdded` o `shotRemovedAt` dopo `resequenceXsheet()` nelle
funzioni dell'Animatic.** Causa sempre un double-update nel Board:

```
resequenceXsheet()
  → emit modelReset()
    → StoryboardPanel::onModelResequenced()   ← Board già sincronizzato qui
      → refreshFromScene()  (quando xsheet count ≠ m_shots.size())

[poi]
emit shotAdded(col)
  → onShotInserted()  ← INSERISCE UN ALTRO SHOT → Board ha 1 di troppo ✗

emit shotRemovedAt(col)
  → onShotRemovedAt()  ← RIMUOVE UN ALTRO SHOT → Board ha 1 di meno ✗
```

**Il Board si sincronizza esclusivamente via `onModelResequenced()`** che usa il
conteggio reale delle colonne child-level nell'xsheet come ground truth
(NON `ZtoryModel::m_shots.size()` che può essere stale).

Funzioni Animatic già corrette (non toccare):
- `onRazorRequested()` — nessun emit post-resequence
- `onAddShot()` — nessun emit post-resequence
- `onMergeWithNext()` — nessun emit post-resequence
- `onMergeShots()` — nessun emit post-resequence

### Shared clipboard / selection — REGOLA

- `ZtoryModel::m_sharedClip` — sorgente unica per clipboard Board↔Animatic
- `ZtoryModel::m_sharedSelection` — xsheet columns selezionate, last-panel-wins
- Lo shared clip ha **sempre priorità** su `m_clipboard` locale del Board
- Board scrive shared clip in `onCopyShot/onCutShot/onCloneShot`
- Board scrive shared selection in `onPanelClicked`
- Animatic scrive shared selection su `selectionChanged` signal del track

-----

## Coding Conventions

### General

- Follow existing Tahoma2D code style
- C++17, Qt5 signals/slots
- Use descriptive names — no obscure abbreviations
- Keep functions focused and under ~50 lines; split if longer
- Add a comment explaining *why*, not *what*, for non-obvious logic

### File Editing on macOS (zsh)

**CRITICAL:** Always use Python scripts in `/tmp/` for file modifications.
Never use heredoc with special characters in zsh — it causes encoding issues.

```bash
# CORRECT way to edit files
cat > /tmp/fix_something.py << 'PYEOF'
fname = '/Volumes/ZioSam/.../file.cpp'
content = open(fname).read()
old = """exact text to replace"""
new = """replacement text"""
if old in content:
    open(fname, 'w').write(content.replace(old, new))
    print('Done')
else:
    print('ERROR - text not found')
PYEOF
python3 /tmp/fix_something.py
```

### Before Modifying Any File

Always verify the exact text exists first:

```bash
grep -n "text to find" path/to/file.cpp
```

### Qt Signals/Slots

Use new-style connect syntax where possible:

```cpp
connect(source, &SourceClass::signal, this, &ThisClass::slot);
```

Use old-style SIGNAL/SLOT macros only when connecting to existing Tahoma2D code
that uses them.

### Headers

- Include guards: `#pragma once`
- Group includes: Ztoryc → Tahoma2D → Qt → std

-----

## Tahoma2D Integration Rules

### Do NOT modify these classes without strong reason:

- `TXshSoundColumn` — audio data (read only from Ztoryc)
- `TFrameHandle` — global frame handle (create separate instance for animatic)
- `BaseViewerPanel` — viewer base class
- `TApp` — application singleton

### Reuse existing Tahoma2D functionality:

- Audio waveform: `soundLevel->getValueAtPixel(orientation, pixel, minmax)`
- Delete column: `ColumnCmd::deleteColumn(col)`
- Clone sub-scene: `cloneChildToPosition()`
- Save sub-scene: `IoCmd::saveScene(SAVE_SUBXSHEET)` — do NOT use `SILENTLY_OVERWRITE`
- Open/close sub-scene: `ztoryOpenSubXsheet()` / `ztoryCloseSubXsheet(int)`
- Resequence: `resequenceXsheet()` — call after any duration/order change

### Audio columns

```cpp
// Iterate all sound columns in main xsheet
TXsheet *xsh = TApp::instance()->getCurrentXsheet()->getXsheet();
for (int col = 0; col < xsh->getColumnCount(); col++) {
    TXshSoundColumn *sc = xsh->getColumn(col)->getSoundColumn();
    if (!sc) continue;
    // use sc
}
```

-----

## Before Submitting a PR to Tahoma2D

1. Run clang-format:

```bash
cd toonz/sources && ./beautification.sh
```

2. Verify no regressions in the modified area
3. PR candidates (fixes developed in Ztoryc, clean enough to contribute upstream):

   **🔴 Bug fix ad alto impatto — codice core, quasi certamente presenti in Tahoma2D:**
   - **ImageManager cache leak after render** (`imagemanager.cpp`, `rendercommand.cpp`) — dopo il render tutti i frame rimangono in cache (osservato: 10 GB residui su scene da 350 frame). Fix: `ImageManager::clear()` sui builder al completamento. Commit `be20f9512`.
   - **requireColumnSoundTrack alloca RAM proporzionale alla durata del file audio** (`TXshSoundColumn`) — su file audio da 2h a 24fps = 172.800 frame → ~1.3 GB per colonna × N colonne. Fix: cappare `toFrame` al frame count video, non alla durata audio. Commit `69a8b9043` (fix applicato in ztoryanimatic.cpp ma il pattern è nel core audio).
   - **Save Sub-Scene As path corruption** (`toonzscene.cpp`, `iocommand.cpp`) — il percorso della sub-scene viene corrotto al salvataggio. Commit nella history Ztoryc.
   - **Wrong column header thumbnail when sub-scenes share a name** (`icongenerator.cpp`) — `XsheetIconRenderer::getId` usa il puntatore della scena invece del nome → thumbnail sbagliata se due sub-scene hanno lo stesso nome.
   - **Set Key (Z) not showing keyframe diamond on peg columns** (`cellselectioncommand.cpp`) — `TCellSelection::setKeyframes()` usava `ColumnId(col)` invece di `xsh->getColumnObjectId(col)` che ritorna `PegbarId` per le peg.
   - **Peg column width reset after delete** (`columnfan.cpp`, 1 riga) — dopo aver eliminato una peg column, la colonna successiva ereditava la larghezza ridotta delle peg. Fix: `m_columns[c].m_width = 0` su reset in `shiftFoldedStates`. Commit `b8ddea829`.

   **🟠 Bug fix medi — probabilmente presenti:**
   - **getPreviewButtonStates null crash** (`viewerpane.cpp`) — crash se `m_previewButton`/`m_subcameraButton` non sono inizializzati. Fix: guard su `nullptr`. Commit `d7453d1eb`.
   - **Mesh sub-scenes wrong folder** (`meshifypopup.cpp`)
   - **New Scene missing save dialog** (`iocommand.cpp`)
   - **macOS "Unable to create a new document" on launch** (`BundleInfo.plist.in`) — aggiungere `NSQuitAlwaysKeepsWindows=false` e `NSApplicationSupportsSecureRestorableState=true`. Commit `a7a822704`.
   - **macOS CI deployment target** — senza `-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0` il binary embeds `minos` uguale al runner (macOS 15), bloccando utenti su macOS 12-14. Commit `940e895bc`.

   **🟡 Windows/MSVC compatibility (solo se Tahoma2D vuole supportare MSVC):**
   - `not`/`and`/`or` alternative tokens → `!`/`&&`/`||` (48 siti, `subscenecommand.cpp`, `tcenterlinecolors.cpp`, `borders_extractor.h`). Commit `105588c14`.
   - Variabile locale `near` → rinomina (collide con macro `windef.h`). Commit `8a4dbc294`.

   **🟢 Feature request (nuove funzionalità, da proporre come discussione):**
   - **Per-xsheet In/Out markers** (`subscenecommand.cpp`) — marker In/Out separati per xsheet principale e sub-scene, utile per chiunque lavori con sub-scene.
   - **Zoom-to-cursor nella timeline** (`columnfan.cpp` e timeline) — il frame sotto il cursore rimane fisso durante lo zoom con la rotella. Commit `b8ddea829`.
4. Commit format — Conventional Commits:
   - `feat:` new feature
   - `fix:` bug fix
   - `refactor:` code restructure, no behavior change
   - `docs:` documentation only
   - `chore:` build, config, tooling

-----

## Rooms & Workflow

| Room       | Purpose               | Key panels                               |
|------------|-----------------------|------------------------------------------|
| BOARD      | Storyboard drawing    | StoryboardPanel (shot grid)              |
| SHOTEDITOR | Pose/layout/animation | StoryStrip + ComboViewer + dual timeline |
| ANIMATIC   | Timing + audio        | ZtoryAnimaticPanel (viewer + track)      |

-----

## Known Bugs (do not regress)

- Frame handle shared between animatic viewer and normal viewer — moving playhead
  in animatic also moves frame in current sub-scene. Fix planned: separate TFrameHandle
  for ZtoryAnimaticPanel.
- Panel not removed when a drawing is deleted — `detectAndUpdatePanels` does not
  handle panel removal.
- Panels missing on scene open — `refreshFromScene` does not load all panels correctly.

-----

## Session Workflow (Claude Code)

### Trigger: "nuova sessione"

When the user says **"nuova sessione"** (with or without additional text), automatically:
1. Read `~/ZtorYc/AGENTS.md` (this file) for rules and architecture
2. Read `~/ZtorYc/CHANGELOG.md` for context — **ONLY the first 60 lines** (recent sessions)
3. Read `~/ZtorYc/ANIMATIC_TASKS.md` — **ONLY the Priority Order section** (last ~40 lines,
   starting from `## Priority Order`). Read full task details only when about to implement them.
4. Report briefly: last session summary + what you'll work on today (starting from
   the highest-priority pending task in ANIMATIC_TASKS.md)

This keeps startup token cost low. Do NOT read full ANIMATIC_TASKS.md upfront.

> **IMPORTANTE:** il trigger "nuova sessione" funziona SOLO se Claude Code ha già letto
> questo file all'avvio (cioè se è aperto nella directory del progetto con CLAUDE.md presente).
> Se il contesto non viene trovato, usare questo messaggio esplicito come primo messaggio:
>
> ```
> nuova sessione — leggi ~/ZtorYc/AGENTS.md, le prime 60 righe di ~/ZtorYc/CHANGELOG.md,
> e la sezione "Priority Order" di ~/ZtorYc/ANIMATIC_TASKS.md. Poi fammi un recap.
> ```

### Context window — avviso token

⚠️ **CRITICO: avvisare PRESTO, non tardi.**

Monitor context window usage continuously. When you estimate that roughly
**40% of the context window remains** (i.e. ~60% used), stop immediately
and warn the user:

> ⚠️ **Token in esaurimento** — siamo al ~60% del contesto. Suggerisco di
> chiudere la sessione ora con "sessione chiusa" così aggiorno CHANGELOG e faccio
> il commit prima di perdere il contesto.

Do this **before** starting any new task or tool call. The "sessione chiusa"
procedure itself (CHANGELOG write + git add + commit + push + rsync + cp 3 docs)
consumes ~15–20% of context. You need that margin.

**Non aspettare che sia troppo tardi.** Se stai per iniziare un task lungo
e sei già al 50% del contesto, avvisa prima di iniziare.

---

### Trigger: "sessione chiusa"

When the user says **"sessione chiusa"**, automatically:

1. **Update `~/ZtorYc/CHANGELOG.md`** — prepend a new entry:
   ```
   ## [YYYY-MM-DD] — title
   ### Fixed / Added / Modified / Upstream candidates / Notes
   ```

2. **Commit and push:**
   ```bash
   cd /Volumes/ZioSam/tahoma2d-workspace/tahoma2d
   git add -A
   git commit -m "descrizione sintetica"
   git push
   ```

3. **Sync code to local backup:**
   ```bash
   rsync -av --delete \
     /Volumes/ZioSam/tahoma2d-workspace/tahoma2d/ \
     ~/ZtorYc/tahoma2d-workspace_local/tahoma2d/
   ```

4. **Copy planning docs back to repo** (keep them in git history):
   ```bash
   cp ~/ZtorYc/CHANGELOG.md /Volumes/ZioSam/tahoma2d-workspace/tahoma2d/CHANGELOG.md
   cp ~/ZtorYc/ANIMATIC_TASKS.md /Volumes/ZioSam/tahoma2d-workspace/tahoma2d/ANIMATIC_TASKS.md
   cp ~/ZtorYc/AGENTS.md /Volumes/ZioSam/tahoma2d-workspace/tahoma2d/AGENTS.md
   ```
   > CHANGELOG.md e ANIMATIC_TASKS.md sono symlink a Google Drive — il `cp` qui
   > legge da Drive e scrive nel repo. Drive è già aggiornato automaticamente
   > da ogni scrittura via `~/ZtorYc/`. Non serve un passo separato per Drive.

5. Confirm to the user: commit hash + files synced.

> **Why two locations:** Cowork (Claude desktop app) reads from `~/ZtorYc/` because
> `/Volumes/ZioSam/` is not accessible from the Cowork sandbox.
> `tahoma2d-workspace_local/` is the live mirror; `tahoma2d-workspace_bak/` is a
> historical snapshot — do not overwrite it.

-----

## Do NOT

- Use `SILENTLY_OVERWRITE` when saving sub-scenes (bypasses asset copy)
- Modify camera from the animatic timeline
- Add audio to sub-scenes (audio lives in main xsheet only)
- Use heredoc with special characters in zsh shell scripts
- Use `widget->screen()` for DPR on macOS — use `widget->windowHandle()->screen()`
- Add global mutable state outside `ZtoryModel`
