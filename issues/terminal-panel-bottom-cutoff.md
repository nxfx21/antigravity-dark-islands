# Terminal Panel Bottom Cutoff

## Problem

The bottom terminal panel's content extends behind the VS Code status bar, causing the last line of the terminal (including the cursor/typing indicator) to be cut off and invisible.

This occurs because the Islands Dark theme applies CSS borders to `.part.panel.bottom` for the floating glass-panel aesthetic:

```css
.part.panel.bottom {
  border-top: 6px solid var(--islands-bg-canvas);
  border-bottom: 1px solid rgba(255,255,255,0.06);
  box-sizing: border-box;
}
```

## Root Cause

VS Code's workbench layout engine uses JavaScript (`PartLayout.layout()`) to calculate panel dimensions via absolute positioning in a split-view system — not CSS grid or flexbox. The JS calculates the `.content` element's height as:

```
contentHeight = totalHeight - 35px (title bar height)
```

This calculation does **not** account for CSS borders on the panel element. With `box-sizing: border-box`, the 6px top border and 1px bottom border reduce the panel's available content area by 7px. However, the JS still sets `.content` height as if all `totalHeight` pixels are available.

The result: the `.content` div is 7px taller than the space it sits in. Combined with `overflow: hidden` on the panel, the bottom 7px of the terminal content is clipped behind the status bar.

### Why other approaches failed

| Approach | Result |
|---|---|
| `border-bottom` / `padding-bottom` on panel | Invisible — the bottom of the panel is literally behind the status bar |
| `margin-bottom` on panel | No effect — panel is absolutely positioned by VS Code's split-view |
| `height: calc(100% - Npx)` on `.content` | Content collapses — parent has no explicit CSS height (set by JS grid) |
| `display: flex` on panel with `height: auto` on `.content` | Content disappears — breaks the `height: 100%` chain used by inner elements |
| `margin-bottom` on `.pane-body.integrated-terminal` | Works but creates a visible gap between terminal and panel bottom edge |

## Fix

Pull `.content` upward by exactly 7px (the total border height) using negative margin, and ensure the title bar paints on top of the overlapping area:

```json
".part.panel.bottom > .composite.title": {
  "position": "relative !important",
  "z-index": "1 !important"
},
".part.panel.bottom > .content": {
  "margin-top": "-7px !important"
}
```

### How it works

1. `margin-top: -7px` on `.content` shifts the entire content block up by 7px, recovering the 7px at the bottom that was previously clipped behind the status bar.
2. `position: relative; z-index: 1` on the title bar (`.composite.title`) ensures it paints on top of the content area that now overlaps it by 7px.

The 7px value is derived from `border-top (6px) + border-bottom (1px) = 7px`.
