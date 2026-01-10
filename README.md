# CVRtracker

A SwiftUI iOS app for tracking cardiovascular health through blood pressure monitoring, arterial stiffness assessment, and lipid tracking.

## Features

### Blood Pressure Tracking
- Log systolic and diastolic readings with timestamps
- **BP Category Classification**: Readings categorized according to AHA/ACC guidelines (Normal, Elevated, Stage 1/2 Hypertension, Hypertensive Crisis)
- Visual indicators for urgent readings requiring attention

### Arterial Stiffness Assessment
- **Fractional Pulse Pressure (fPP)**: Automatically calculates fPP as a marker of arterial stiffness
- **Trend Interpretation**: Analyzes changes in pulse pressure and mean arterial pressure over time
- **Clinical Guidance**: 9 interpretation scenarios based on combined PP and MAP trends (e.g., "Excellent Progress", "Arterial Stiffening", "Worsening Trend")

### Lipid Tracking
- Monitor Total Cholesterol, HDL, LDL, and Triglycerides
- **Clinical Categories**: Each value categorized with color-coded interpretation hints
  - Total Cholesterol: Desirable/Borderline/High
  - HDL: Low (CV risk factor)/Acceptable/Optimal (protective)
  - LDL: Optimal through Very High
  - Triglycerides: Normal through Very High
- TC/HDL ratio with cardiovascular risk interpretation
- Support for mg/dL and mmol/L units

### Cardiovascular Risk Scores
- **10-Year Risk**: Framingham Risk Score (D'Agostino et al., 2008)
- **30-Year Risk**: Extended risk calculation (Pencina et al., 2009)

### Apple Health Integration
- Sync blood pressure readings bidirectionally with Apple Health
- Import heart rate data from Apple Watch and other devices
- Manual and automatic sync options

### Patient Education
- In-app tutorial system with comprehensive health topics
- Detailed explanations of blood pressure, arterial stiffness, and lipids
- Research references with clickable DOI links
- Context-sensitive help buttons throughout the app

### Data Visualization
- Interactive trend charts for fPP over time
- Lipid trend charts with target reference lines
- Mini dashboard charts for quick overview

## Key Metrics

### Fractional Pulse Pressure (fPP)
fPP = Pulse Pressure / Mean Arterial Pressure

- **< 0.40**: Normal - Good vascular health
- **0.40 - 0.50**: Elevated - Moderate arterial stiffness
- **> 0.50**: High - Increased arterial stiffness

### Blood Pressure Categories (AHA/ACC Guidelines)
- **Normal**: Systolic < 120 AND Diastolic < 80 mmHg
- **Elevated**: Systolic 120-129 AND Diastolic < 80 mmHg
- **Stage 1 Hypertension**: Systolic 130-139 OR Diastolic 80-89 mmHg
- **Stage 2 Hypertension**: Systolic 140-179 OR Diastolic 90-119 mmHg
- **Hypertensive Crisis**: Systolic ≥ 180 OR Diastolic ≥ 120 mmHg

### Trend Interpretation
The app analyzes trends in both pulse pressure (arterial stiffness) and mean arterial pressure:
- **Best Scenario**: Both PP and MAP decreasing - excellent cardiovascular improvement
- **Good Progress**: PP decreasing with stable MAP, or stable PP with decreasing MAP
- **Needs Attention**: Mixed trends requiring discussion with healthcare provider
- **Concerning**: Increasing PP indicating progressive arterial stiffening
- **Most Concerning**: Both PP and MAP increasing - requires medical attention

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

Built with:
- **SwiftUI** for the user interface
- **SwiftData** for persistent storage
- **Swift Charts** for data visualization
- **HealthKit** for Apple Health integration

## Project Structure

```
CVRtracker/
├── CVRtrackerApp.swift              # App entry point
├── Models/
│   ├── BPReading.swift              # Blood pressure model with BP/fPP categories
│   ├── LipidReading.swift           # Lipid panel with clinical categories
│   ├── UserProfile.swift            # User profile, preferences, unit settings
│   ├── HelpContent.swift            # Educational content and references
│   ├── Calculations.swift           # CV risk score calculations
│   └── SchemaVersioning.swift       # SwiftData schema management
├── Views/
│   ├── ContentView.swift            # Main tab navigation
│   ├── DashboardView.swift          # Overview with fPP, trends, risk scores
│   ├── BPEntryView.swift            # Blood pressure entry
│   ├── HistoryView.swift            # BP reading history with categories
│   ├── TrendChartView.swift         # fPP trends with interpretation
│   ├── LipidHistoryView.swift       # Lipid history with hints
│   ├── LipidEntryView.swift         # Lipid panel entry
│   ├── ProfileView.swift            # User profile and settings
│   ├── TutorialView.swift           # Educational content browser
│   └── RiskResultView.swift         # Risk calculation results
├── Services/
│   └── HealthKitManager.swift       # Apple Health integration
└── Assets.xcassets/                 # App icons and colors
```

## Usage

1. **Set up your profile**: Enter your age, sex, and health information in the Profile tab
2. **Log blood pressure**: Add readings in the "Add BP" tab using the compact keyboard entry
3. **Track lipids**: Record your cholesterol and lipid panel values
4. **View dashboard**: See your current fPP, trend interpretation, and CV risk scores
5. **Review history**: Track all readings with category indicators and patterns
6. **Learn**: Explore the Tutorial section for educational content about cardiovascular health
7. **Sync with Health**: Enable Apple Health integration to share data with other health apps

## Disclaimer

This app is for informational purposes only and is not intended to replace professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider regarding any medical conditions or health concerns.

## License

Copyright 2025 Horst Herb. All rights reserved.
