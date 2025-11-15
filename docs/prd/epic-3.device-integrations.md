# Epic 3: Device Integrations & Sensor Data

## Status

Approved

## Summary

Integrate GroBro with popular grow controller hardware to automatically log environmental data and enable advanced automation:

- Read-only integrations with Vivosun and AC Infinity controllers
- Automatic logging of temperature, humidity, VPD, light schedule
- Camera-based light distance assistant using device camera and AR
- Environmental trend visualization integrated with plant health metrics
- Alert system for environmental parameter thresholds

This epic bridges the gap between manual diary-keeping and automated grow room monitoring.

## Business Value

- Differentiates GroBro from simple diary apps by leveraging IoT hardware
- Appeals to serious growers using professional equipment
- Provides data foundation for future AI recommendations based on environmental patterns
- Creates potential partnership opportunities with hardware manufacturers
- Positions GroBro as a comprehensive grow room management platform

## In Scope

- Vivosun API integration (read-only access to device data)
- AC Infinity API integration (read-only access to device data)
- Automatic environmental data logging to plant timeline
- Camera-based light meter measuring PPFD, Lux, and DLI (like Photone)
- Camera-based light distance measurement tool using ARKit
- Environmental analytics dashboard showing:
  - Temperature/humidity/VPD trends over time
  - Correlation with plant health events
  - Light schedule adherence visualization
- Threshold-based alert system (high temp, low humidity, etc.)
- Device pairing UI and credential management

## Out of Scope (for this Epic)

- Write/control capabilities for grow controllers (safety and liability concerns)
- Integration with non-mainstream controllers without public APIs
- Advanced automation rules and triggers (future epic)
- PPM/EC sensor data analysis (future epic, requires Pro+)
- Energy consumption tracking and cost analysis
- Integration with non-grow-specific smart home devices

## Epic-Level Acceptance Criteria

1. Users can pair their Vivosun account in Settings and see connected devices
2. Users can pair their AC Infinity account in Settings and see connected devices
3. Environmental data (temp, humidity, VPD) is automatically logged as events to associated plants
4. Users can associate grow rooms/devices with specific plants or groups of plants
5. A new "Environment" tab in Plant Detail shows environmental trends for that plant's location
6. Users can measure light intensity using device camera showing PPFD, Lux, and DLI values
7. The light meter logs measurements to plant diary for tracking over time
8. The camera-based Light Assistant can measure approximate distance from camera to plant canopy using AR
9. The Light Assistant provides guidance on optimal light distance and intensity based on plant stage and light type
10. Users can set environmental thresholds and receive push notifications when exceeded
11. The Analytics dashboard (Pro feature) integrates environmental data with plant health metrics
12. Device integration respects user privacy: no data sent to third parties, all processing on-device or in user's iCloud

## Stories in This Epic

- Controller Integrations:
  - `docs/stories/7.1.vivosun-integration-and-data-sync.md` – Vivosun API integration
  - `docs/stories/7.2.ac-infinity-integration-and-data-sync.md` – AC Infinity API integration
  - `docs/stories/7.3.device-pairing-and-room-management.md` – UI for pairing devices and associating with plants
- Environmental Features:
  - `docs/stories/8.1.environmental-data-timeline.md` – Display environmental events in plant timeline
  - `docs/stories/8.2.environmental-analytics-dashboard.md` – Visualizations for environmental trends
  - `docs/stories/8.3.threshold-alerts-and-notifications.md` – Alert system for parameter thresholds
- Light Meter & Assistant:
  - `docs/stories/9.1.camera-based-light-meter.md` – Camera-based light intensity measurement (PPFD, Lux, DLI)
  - `docs/stories/9.2.light-distance-measurement-ar.md` – ARKit-based light distance tool
  - `docs/stories/9.3.light-recommendations-engine.md` – Guidance based on stage, light type, and measurements

Future epics can add control capabilities (with proper safety measures), advanced automation rules, and PPM/EC sensor support.
