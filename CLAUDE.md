# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project (command line)
swift build

# Run tests
swift test

# Build with Xcode (recommended for iOS development)
xcodebuild -project CVRtracker.xcodeproj -scheme CVRtracker -destination 'platform=iOS Simulator,name=iPhone 15'
```

The project uses GitHub Actions for CI (`.github/workflows/swift.yml`) which runs `swift build` and `swift test` on pushes to main.

## Architecture

**SwiftUI + SwiftData iOS App** for cardiovascular health tracking.

### Data Models (SwiftData @Model classes)

All models are in `CVRtracker/Models/`:

- **BPReading**: Blood pressure readings with computed properties for pulse pressure, MAP, and fractional pulse pressure (fPP)
- **LipidReading**: Lipid panel readings (cholesterol, HDL, LDL, triglycerides). All values stored internally in mg/dL with display conversion methods
- **UserProfile**: User demographics and health factors for Framingham risk calculation. Unit preferences stored as optional raw strings for migration compatibility

### Unit Conversion Pattern

Lipid values are always stored in mg/dL internally. Unit enums (`CholesterolUnit`, `TriglycerideUnit` in UserProfile.swift) provide `toMgdL()` and `fromMgdL()` conversion methods. Views convert on display/input.

### Risk Calculations

`Calculations.swift` contains:
- `calculateFPP()`: Fractional Pulse Pressure (arterial stiffness indicator)
- `calculateFramingham10Year()`: 10-year CV risk (D'Agostino 2008)
- `calculateFramingham30Year()`: 30-year CV risk (Pencina 2009)

### Schema Management

`SchemaVersioning.swift` handles SwiftData container creation with auto-reset on schema mismatch (development behavior). The schema includes `BPReading`, `UserProfile`, and `LipidReading`.

### View Structure

Tab-based navigation in `ContentView.swift`:
1. Dashboard - fPP display, mini trend chart, risk scores
2. Add BP - Compact keyboard entry (xxx/xxx mmHg format)
3. BP History - List with swipe-to-delete
4. Lipids - History and entry for lipid panels
5. Profile - Demographics, risk factors, unit preferences

### Key Patterns

- Views use `@Query` for SwiftData fetches sorted by timestamp (reverse for most recent first)
- Explicit `modelContext.save()` calls after inserts to ensure immediate persistence
- Entry forms use text fields with parsed values (not steppers) for compact layouts
- Haptic feedback on successful saves
