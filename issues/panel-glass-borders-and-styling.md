# Panel Glass Borders, Color Matching & Bottom Line Cleanup

## Problems

Several visual issues with the bottom panel's glass styling:

1. **Faint shadow/padding visible against canvas**: The panel had an outer `box-shadow: 0 2px 8px rgba(0,0,0,0.3)` that bled visibly against the canvas background between the panel and status bar.

2. **Bottom glass line didn't follow the right curve**: The `border-bottom: 1px` met `border-right: 6px` (canvas-colored gap border) at the bottom-right corner. Different border widths on adjacent sides create a diagonal corner transition, breaking the smooth curve.

3. **Terminal background color mismatch**: The terminal xterm background (`rgb(25,29,33)` / `#191d21`) was 1 shade darker per channel than the panel background (`rgb(26,30,34)` / `#1a1e22`), creating a visible rectangle within the panel.

4. **Missing left glass border on terminal**: The panel's inset box-shadows (`inset 1px 0 0 0 rgba(255,255,255,0.06)`) render behind child content. The terminal's opaque xterm canvas backgrounds painted over the inset shadows, hiding the left glass line.

5. **Missing bottom-left rounded corner on terminal**: Same root cause — the terminal's opaque background covered the panel's inner border-radius clipping. Since the backgrounds matched after the color fix, the clipped corner was invisible.

6. **Double/phantom bottom line under terminal tabs**: The global `.tabs-container` rule used `background-image: linear-gradient(to top, #2a2d34 1px, transparent 1px)` to draw a 1px separator line at the bottom of editor tabs. This also matched the terminal tabs container in the panel, creating an unwanted bottom line.

## Root Causes

### Inset shadows are behind children
CSS inset box-shadows paint in this order: background → inset shadows → children. Any child element with an opaque background covers the inset shadows. This affects the terminal (xterm has inline `background-color`) but not views like Problems (whose `.message-box-container` has margins exposing the panel edges).

### Border width mismatch at corners
When `border-bottom: 1px` meets `border-right: 6px`, CSS renders a diagonal join at the corner. This makes thin glass lines look jagged rather than smoothly curved.

### Global selectors hitting panel elements
The `.tabs-container` background-image rule was intended for editor tabs only but the selector also matched the terminal tabs container inside the bottom panel.

## Fixes

### Panel-level changes (`.part.panel.bottom`)
```json
"background-color": "var(--islands-bg-surface) !important"
```
Matches the terminal's `#191d21` so there's no visible color difference.

```json
"border-bottom": "none !important"
```
Removed the bottom border entirely — with the glass aesthetic, no bottom line is needed (the panel sits flush above the status bar).

```json
"box-shadow": "inset 0 1px 0 0 rgba(255,255,255,0.1), inset 1px 0 0 0 rgba(255,255,255,0.06), inset -1px 0 0 0 rgba(255,255,255,0.02) !important"
```
Removed the outer shadow (`0 2px 8px`) and the bottom inset shadow. Kept top, left, and right inset glass lines for views where content has margins (e.g. Problems).

### Terminal-specific glass border (`.part.panel.bottom .terminal-outer-container`)
```json
"border-left": "1px solid rgba(255,255,255,0.06) !important",
"border-radius": "0 0 0 18px !important",
"box-sizing": "border-box !important",
"overflow": "hidden !important"
```
Adds a left glass line directly on the terminal container (since inset shadows on the panel are covered by xterm's opaque canvas). The `border-radius` + `overflow: hidden` clips the terminal content to a rounded bottom-left corner. Also applied `border-radius: 0 0 0 18px` to `.terminal.xterm` so the xterm's own background follows the curve.

### Content clipping (`.part.panel.bottom > .content`)
```json
"border-radius": "0 0 18px 18px !important",
"overflow": "hidden !important"
```
Clips all panel content to rounded bottom corners (18px = panel radius 24px minus border gap 6px).

### Bottom line suppression
Multiple elements within the panel had bottom borders from VS Code's default CSS or from the theme's `panelSection.border`:
```json
".part.panel.bottom .pane":            { "border-bottom": "none !important" },
".part.panel.bottom .pane-body":       { "border-bottom": "none !important" },
".part.panel.bottom .split-view-view": { "border-bottom": "none !important" },
".part.panel.bottom .composite":       { "border-bottom": "none !important" },
".part.panel.bottom .monaco-pane-view":{ "border-bottom": "none !important" },
".part.panel.bottom .output-view":     { "border-bottom": "none !important" }
```

### Terminal tabs bottom line fix (`.part.panel.bottom .tabs-container`)
```json
"background-image": "none !important"
```
Overrides the global `.tabs-container` gradient that was drawing a 1px line at the bottom of the terminal tabs list.
