---
name: Gaadi Manager
colors:
  surface: '#0e131e'
  surface-dim: '#0e131e'
  surface-bright: '#343946'
  surface-container-lowest: '#090e19'
  surface-container-low: '#171b27'
  surface-container: '#1b1f2b'
  surface-container-high: '#252a36'
  surface-container-highest: '#303541'
  on-surface: '#dee2f2'
  on-surface-variant: '#bcc9cd'
  inverse-surface: '#dee2f2'
  inverse-on-surface: '#2b303c'
  outline: '#869397'
  outline-variant: '#3d494c'
  surface-tint: '#4cd7f6'
  primary: '#4cd7f6'
  on-primary: '#003640'
  primary-container: '#06b6d4'
  on-primary-container: '#00424f'
  inverse-primary: '#00687a'
  secondary: '#adc6ff'
  on-secondary: '#002e6a'
  secondary-container: '#0566d9'
  on-secondary-container: '#e6ecff'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#1bbd85'
  on-tertiary-container: '#00452e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#acedff'
  primary-fixed-dim: '#4cd7f6'
  on-primary-fixed: '#001f26'
  on-primary-fixed-variant: '#004e5c'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0e131e'
  on-background: '#dee2f2'
  surface-variant: '#303541'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
  stat-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  stat-currency:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system powers an executive-grade, dark-mode-first fleet mobility and financial ledger platform tailored specifically for vehicle rental operators in India. The brand aesthetic merges the high-density analytical rigor of modern B2B fintech tools with the responsive ergonomics required for high-velocity field management (e.g., roadside drop-offs, garage vehicle inspections, fast UPI reconcilement).

The visual philosophy relies on **Dark Tonal Stratification with Precision Accents**:
- **Atmosphere:** Deep obsidian-navy canvas tones create a distraction-free, low-glare working cockpit suitable for high outdoor glare and nocturnal dispatch routines.
- **Fintech Precision:** Financial summaries, daily collections, and security deposits are framed with geometric clarity, sharp contrast ratios, and prominent Indian Rupee (`₹`) styling.
- **Ergonomics & Density:** Touch ergonomics ensure thumb-driven single-handed operation on mobile devices, pairing minimum 48px tactile zones with structured, micro-badged data grids.

## Colors
The color architecture utilizes deep multi-tiered navy neutrals to construct depth without washing out contrast, paired with an electric cyan/blue core and an uncompromising semantic status system.

### Palette Roles
- **Canvas Base:** `#0B101B` serves as the primary canvas; `#111827` and `#161F30` form lower sub-layers and inset modules.
- **Elevated Surfaces:** `#1B2538` represents interactive cards; `#202D45` marks hover states and elevated sheets.
- **Brand Core (Electric Cyan-Blue):** Primary actions use `#06B6D4` fading into `#3B82F6` and deep `#2563EB` for high-impact buttons, selection rings, and navigation indicators.
- **Hairline Dividers:** `rgba(255, 255, 255, 0.08)` or solid `#2A3854` provide architectural framing without visual noise.

### Semantic Tones
- **Operational Green (Emerald):** `#10B981` (primary text/fill) and `#059669` (borders/active states) for *Available*, *Paid*, *Security Returned*, and positive yield metrics.
- **Urgency Amber (Gold):** `#F59E0B` and `#D97706` for *Pending Clearance*, *Due Today*, *Partial Collateral*, and alerts.
- **Critical Red (Coral):** `#EF4444` and `#DC2626` for *Overdue Return*, *Challan Alert*, *Accidental Damage*, and defaulted balances.
- **Metadata Slate:** `#94A3B8` for secondary text, units, and timestamps; `#64748B` for placeholders, captions, and dormant borders.

## Typography
The system uses **Plus Jakarta Sans** as the unified typographic engine across all contexts, offering modern geometry, high legibility in low-light environments, and clean numeric proportions.

### Typographic Hierarchy & Guidelines
- **Financial & KPI Rendering:** Monetary sums combine `stat-currency` for the `₹` symbol with `stat-display` for numerals, using tabular figures (`tnum`) to keep rapidly updating totals aligned.
- **Registration Plate Data:** Vehicle plate badges and chassis codes use uppercase `label-md` with tracking (`+0.05em`) to ensure legibility when reading registration IDs at a glance.
- **Labels vs. Body:** Field tags, operational metrics, and statuses must strictly use medium-to-bold weights (`600`/`700`) to guarantee legibility against deep `#1B2538` card backgrounds.

## Layout & Spacing
The layout follows a mobile-first, thumb-driven fluid grid system anchored by strict vertical rhythm and fixed bottom navigation margins.

### Mobile Grid Principles
- **Outer Canvas Margins:** 16px (`1rem`) on standard viewport widths, expanding to 24px (`1.5rem`) on large phablets and tablets.
- **Internal Column Grid:** A 4-column fluid layout with 16px (`gutter`) spacing governs card internals and metric blocks.
- **Touch Target Density:** All interactive triggers (actions, vehicle status pickers, quick-call anchors) have a minimum height and width of 48px to eliminate tap errors in fast-paced operational workflows.
- **Safe Area Insets:** A mandatory 84px bottom cushion is reserved on mobile screens to ensure the floating bottom bar never obscures vehicle lists or action buttons.

## Elevation & Depth
Elevation avoids stark skeuomorphic drop shadows, instead using **Tonal Stratification with Subtle Hairline Edge Illumination** to define layers in dark mode.

### Elevation Hierarchy
1. **Level 0 (Canvas Base):** Flat `#0B101B`. Background for global scroll zones.
2. **Level 1 (Structural Insets & Sub-Panels):** `#111827` or `#161F30`. Employed for secondary controls, segmented filters, and deactivated metric zones.
3. **Level 2 (Interactive Modules & Cards):** `#1B2538`. Elevated over the canvas with a 1px border of `rgba(255, 255, 255, 0.08)` or `#2A3854`. Soft drop shadow: `0 4px 20px -2px rgba(0, 0, 0, 0.45)`.
4. **Level 3 (Modal Sheets & Floating Bottom Bars):** `#202D45`. Elevated above active content with a 1px top border of `rgba(6, 182, 212, 0.25)` (cyan perimeter glow) and deep shadow: `0 8px 32px 0 rgba(0, 0, 0, 0.7)`.

## Shapes
The design language adopts a distinct **16px base radius (`rounded-2xl`)** across all primary containment boundaries to convey a tactile, modern mobile interface.

### Shape Matrix
- **Core Cards & Inset Sheets:** Fixed 16px (`1rem`) border radius on all corners. Modals and pull-up sheets utilize 24px (`1.5rem`) on top-left and top-right edges.
- **Action Triggers & Form Fields:** 12px (`0.75rem`) to 16px (`1rem`) radius, matching overall card curvature.
- **Status Indicators & Micro-Badges:** Strict full-radius pill styling (`9999px`) to maintain clear differentiation between operational chips and actionable rectangular cards.

## Components

### 1. Buttons & Interaction Triggers
- **Primary Action (New Booking / Collect Cash):** High-saturation gradient or solid cyan-blue (`#06B6D4` to `#2563EB`). Dark text (`#0B101B`) or high-contrast crisp white (`#FFFFFF`) in `label-lg` (700 weight). Min-height: 48px.
- **Secondary (Inspect Vehicle / Extend):** `#1B2538` background, 1px border `#2A3854`, text `#E2E8F0`. Hover/Active: Background shifts to `#202D45`.
- **Destructive (Cancel / Impound):** Deep dark red tint `rgba(239, 68, 68, 0.12)`, 1px border `rgba(239, 68, 68, 0.3)`, text `#EF4444`.

### 2. Status Chips & Micro-Badges
- **Structure:** 24px to 28px height, 100% rounded pill profile, 8px horizontal padding.
- **Available / Clear:** Background `rgba(16, 185, 129, 0.12)`, border `rgba(16, 185, 129, 0.25)`, text `#10B981`. Includes a pulsing 6px emerald circle indicator.
- **Pending / Warning:** Background `rgba(245, 158, 11, 0.12)`, border `rgba(245, 158, 11, 0.25)`, text `#F59E0B`.
- **Overdue / Alert:** Background `rgba(239, 68, 68, 0.12)`, border `rgba(239, 68, 68, 0.25)`, text `#EF4444`.

### 3. Vehicle Cards & Inventory Modules
- **Geometry:** `#1B2538` base, 16px corner radius, 1px hairline border `#2A3854`.
- **Content Hierarchy:**
  - Header: Vehicle model (e.g., *Hyundai Creta 1.5 MT*) accompanied by bold registration plate chip (e.g., `DL 01 AB 1234`).
  - Body: Rental rate (`₹2,400/day`), current odometer/fuel gauge, customer thumbnail or vacant badge.
  - Footer: Two 44px thumb actions (e.g., "WhatsApp", "Manage").

### 4. Input Fields (Search, Odometer, UPI Ref)
- **Geometry:** Height 52px, 12px border radius, `#111827` dark fill.
- **Borders & Focus:** Idle border `#2A3854`; active focus ring `0 0 0 2px #06B6D4`.
- **Prefixes:** Static Indian Rupee icon or currency glyph rendered in `#64748B`.

### 5. Floating Bottom Navigation Bar
- **Styling:** Floating dock, 16px bottom margin, 16px side margins, 20px radius.
- **Surface:** Blurry frosted slate `#161F30` at 90% opacity (`backdrop-filter: blur(16px)`), hairline outline `rgba(255, 255, 255, 0.1)`.
- **Indicators:** Active items show a cyan glow dot (`#06B6D4`) beneath the icon and transition label weight to `700`.