# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project (command line) - NOTE: This is an Xcode project, not SPM
# swift build will fail as there's no Package.swift

# Build with Xcode (recommended for iOS development)
xcodebuild -project CVRtracker.xcodeproj -scheme CVRtracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Alternative: use device ID for specific simulator
xcodebuild -project CVRtracker.xcodeproj -scheme CVRtracker -destination 'platform=iOS Simulator,id=<device-id>' build
```

The project uses GitHub Actions for CI (`.github/workflows/swift.yml`).

## Architecture

**SwiftUI + SwiftData iOS App** for cardiovascular health tracking.

### Data Models (SwiftData @Model classes)

All models are in `CVRtracker/Models/`:

- **BPReading**: Blood pressure readings with computed properties for:
  - Pulse pressure, MAP, and fractional pulse pressure (fPP)
  - `bpCategory`: AHA/ACC blood pressure classification (Normal, Elevated, Stage 1/2 HTN, Crisis)
  - `fppCategory`: Arterial stiffness category (Normal, Elevated, High)
  - `fppInterpretation`: Context-aware interpretation considering BP category

- **LipidReading**: Lipid panel readings with:
  - Total cholesterol, HDL, LDL (optional/calculated), triglycerides
  - All values stored internally in mg/dL with display conversion methods
  - Category enums for each lipid type with clinical thresholds and hints
  - `totalCholesterolCategory`, `hdlCategory`, `ldlCategory`, `triglyceridesCategory`

- **UserProfile**: User demographics and health factors for Framingham risk calculation
  - Unit preferences stored as optional raw strings for migration compatibility

- **HelpContent**: Educational content with references
  - `HelpTopic` struct with title, descriptions, clinical relevance, and research references
  - `TutorialSection` for organizing topics
  - Static content for blood pressure, arterial stiffness, lipids, and risk factors

### Clinical Categories and Enums

Located in model files:

- **BPCategory** (BPReading.swift): AHA/ACC blood pressure classification
- **FPPCategory** (BPReading.swift): Arterial stiffness levels
- **TotalCholesterolCategory**, **HDLCholesterolCategory**, **LDLCholesterolCategory**, **TriglyceridesCategory** (LipidReading.swift): Lipid clinical categories with hints
- **TrendDirection**, **TrendInterpretation** (TrendChartView.swift): Trend analysis for PP and MAP

### Unit Conversion Pattern

Lipid values are always stored in mg/dL internally. Unit enums (`CholesterolUnit`, `TriglycerideUnit` in UserProfile.swift) provide `toMgdL()` and `fromMgdL()` conversion methods. Views convert on display/input.

### Risk Calculations

`Calculations.swift` contains:
- `calculateFPP()`: Fractional Pulse Pressure (arterial stiffness indicator)
- `calculateFramingham10Year()`: 10-year CV risk (D'Agostino 2008)
- `calculateFramingham30Year()`: 30-year CV risk (Pencina 2009)

### Services

- **HealthKitManager** (Services/HealthKitManager.swift): Apple Health integration
  - Bidirectional BP sync
  - Heart rate import from Apple Watch
  - Authorization handling

### Schema Management

`SchemaVersioning.swift` handles SwiftData container creation with auto-reset on schema mismatch (development behavior). The schema includes `BPReading`, `UserProfile`, and `LipidReading`.

### View Structure

Tab-based navigation in `ContentView.swift`:
1. **Dashboard** - fPP display, mini trend chart, trend interpretation card, risk scores, heart rate
2. **Add BP** - Compact keyboard entry (xxx/xxx mmHg format)
3. **BP History** - List with swipe-to-delete, BP category indicators, fPP values
4. **Lipids** - History with interpretation hints, entry for lipid panels, trend charts
5. **Profile** - Demographics, risk factors, unit preferences, Apple Health settings
6. **Learn** (TutorialView) - Educational content with research references

### Key Views

- **DashboardView**: Main dashboard with fPP card, trend chart, trend interpretation, risk scores
- **TrendChartView**: fPP trends over time with PP/MAP trend analysis and clinical interpretation
- **HistoryView/ReadingRow**: BP reading list with category indicators
- **LipidHistoryView**: Lipid readings with color-coded interpretation hints
- **TutorialView/TopicDetailView**: Educational content browser with clickable research links
- **InfoButton**: Reusable help button that shows topic details in a sheet

### Key Patterns

- Views use `@Query` for SwiftData fetches sorted by timestamp (reverse for most recent first)
- Explicit `modelContext.save()` calls after inserts to ensure immediate persistence
- Entry forms use text fields with parsed values (not steppers) for compact layouts
- Haptic feedback on successful saves
- `InfoButton` components link to relevant `HelpContent` topics throughout the app
- Trend analysis compares first half vs second half of readings to determine direction
- Clinical category enums provide `hint` and `color` properties for UI display
