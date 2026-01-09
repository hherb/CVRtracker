# CVRtracker

A SwiftUI iOS app for tracking cardiovascular risk through blood pressure monitoring and lipid tracking.

## Features

- **Blood Pressure Tracking**: Log systolic and diastolic readings with timestamps
- **Fractional Pulse Pressure (fPP)**: Automatically calculates fPP as an indicator of arterial stiffness
- **Lipid Tracking**: Monitor Total Cholesterol, HDL, LDL, and Triglycerides over time
- **Cardiovascular Risk Scores**: Calculates 10-year and 30-year CV risk using the Framingham Risk Score
- **Trend Visualization**: Charts showing BP and lipid trends over time
- **Unit Preferences**: Support for mg/dL and mmol/L units for cholesterol and glucose measurements

## Key Metrics

### Fractional Pulse Pressure (fPP)
fPP = Pulse Pressure / Mean Arterial Pressure

- **< 0.40**: Normal - Good vascular health
- **0.40 - 0.50**: Elevated - Moderate arterial stiffness
- **> 0.50**: High - Increased arterial stiffness

### Framingham Risk Score
Based on D'Agostino et al. (2008), the app calculates:
- **10-Year Risk**: Risk of cardiovascular event in the next 10 years
- **30-Year Risk**: Extended risk based on Pencina et al. (2009)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

Built with:
- **SwiftUI** for the user interface
- **SwiftData** for persistent storage
- **Swift Charts** for data visualization

## Project Structure

```
CVRtracker/
├── CVRtrackerApp.swift          # App entry point
├── Models/
│   ├── BPReading.swift          # Blood pressure reading model
│   ├── LipidReading.swift       # Lipid panel reading model
│   ├── UserProfile.swift        # User profile and preferences
│   └── Calculations.swift       # CV risk calculations
├── Views/
│   ├── ContentView.swift        # Main tab view
│   ├── DashboardView.swift      # Overview dashboard
│   ├── BPEntryView.swift        # Blood pressure entry
│   ├── HistoryView.swift        # Reading history
│   ├── TrendChartView.swift     # Trend charts
│   ├── ProfileView.swift        # User profile
│   └── RiskResultView.swift     # Risk calculation results
└── Assets.xcassets/             # App icons and colors
```

## Usage

1. **Set up your profile**: Enter your age, sex, and health information in the Profile tab
2. **Log blood pressure**: Add readings in the "Add BP" tab
3. **Track lipids**: Record your cholesterol and lipid values over time
4. **View dashboard**: See your current fPP, trends, and CV risk scores
5. **Review history**: Track all readings and identify patterns

## Disclaimer

This app is for informational purposes only and is not intended to replace professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider regarding any medical conditions or health concerns.

## License

Copyright 2025 Horst Herb. All rights reserved.
