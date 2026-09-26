# Hackathon Demo Guide

## Demo Flow

1. **Sign up** — create a new account
2. **Dashboard** — shows greeting, field count, recent scans
3. **Add field** — "Green Valley Farm > North Field > Sugarcane > 3.2 ha"
4. **Scan** — select a crop photo from gallery
5. **Analysis loading** — 4-message sequence shows analysis stages
6. **Detection result** — bounding boxes, weed count, confidence, severity
7. **Zone analysis** — 4-zone grid with colour-coded severity
8. **Scan history** — list of all past scans
9. **Comparison** — select two scans, view weed count delta

## Key Differentiators

| Feature | Capability |
|---|---|
| Identify | Weed detection with bounding boxes and confidence |
| Quantify | Weed count and infestation score |
| Locate | 4-zone breakdown with priority zone flag |
| Monitor | Scan history and side-by-side comparison |

## Demo Notes

- All detections are clearly marked "Demo detection" in the UI
- Severity thresholds shown with the disclaimer "prototype defaults"
- Zone boundaries labelled as image-frame divisions, not GPS sectors
- Mock weather returns realistic sample data when API key is absent

## Presenting the Architecture

Point to `WeedDetectionService` abstraction — one line swap replaces mock with production YOLO model. The UI requires zero changes.
