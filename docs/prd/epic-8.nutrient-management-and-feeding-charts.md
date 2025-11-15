# Epic 8: Nutrient Management & Feeding Charts

## Status

Approved

## Summary

Implement comprehensive nutrient management features with feeding schedules from leading brands:

- Nutrient dosage calculator based on plant stage and reservoir size
- Pre-built feeding charts from GHE (General Hydroponics Europe), Advanced Nutrients, Fox Farm, Canna, BioBizz
- Custom nutrient tracking and mixing recipes
- PPM/EC/TDS calculations and tracking
- pH tracking and recommendations
- Nutrient event logging with brand/product tagging
- Nutrient cost tracking (Pro feature)
- Integration with environmental data (nutrient uptake vs. temp/humidity)

This epic positions GroBro as a complete cultivation assistant, not just a diary, appealing to serious hydroponic and organic growers.

## Business Value

- Differentiates from basic diary apps
- Appeals to hydroponic growers (large, underserved market)
- Creates partnership opportunities with nutrient brands
- Enables Pro tier upsell (advanced nutrient analytics)
- Positions GroBro as authoritative cultivation tool
- Reduces user errors in nutrient mixing (safety and plant health)
- Opens merchandising opportunities (affiliate links to products)

## In Scope

- Nutrient calculator: input plant stage, reservoir size, brand/line → output dosages
- Pre-built feeding schedules from major brands:
  - GHE (General Hydroponics Europe): Flora series, Bio series
  - Advanced Nutrients: pH Perfect, Sensi, Connoisseur lines
  - Fox Farm: Trio (Grow Big, Big Bloom, Tiger Bloom)
  - Canna: Classic, Terra, Aqua, Coco lines
  - BioBizz: Try-Pack, Light-Mix schedule
  - Botanicare, Emerald Harvest, Nectar for the Gods
- Custom nutrient recipes (user-defined mixes)
- PPM/EC/TDS calculator and tracker
- pH tracking and target range recommendations
- Nutrient event logging with brand, product, dosage, PPM, pH
- Nutrient timeline visualization (feeding history chart)
- Nutrient cost tracking (Pro): track bottle sizes, costs, calculate per-feed cost
- Feeding schedule templates by growth medium (hydro, soil, coco)
- Integration with watering events (feeding vs. plain water)
- Mixing instructions and safety warnings
- Nutrient deficiency correlation with diagnostics

## Out of Scope (for this Epic)

- Automated nutrient dosing (hardware integration, future)
- Custom nutrient formulation (leave to experts)
- Medical/yield claims (legal risk)
- Nutrient sales/marketplace (future consideration)
- Multi-plant batch feeding (future)

## Epic-Level Acceptance Criteria

1. Users can select nutrient brand and product line from comprehensive list
2. Feeding calculator shows dosages for selected stage and reservoir size
3. Pre-built feeding schedules available for 6+ major brands
4. Users can log nutrient events with brand, product, dosage, PPM, pH
5. PPM/EC/TDS calculator converts between units accurately
6. pH tracking shows current pH, target range, and trend
7. Nutrient timeline shows feeding history with dosage visualization
8. Custom recipes can be created, saved, and reused
9. Pro users can track nutrient costs per bottle and per feeding
10. Feeding schedule adapts to plant stage automatically
11. Mixing instructions show order of operations (e.g., "Add silica first, pH last")
12. Safety warnings for pH adjusters and concentrated nutrients
13. Integration with diagnostics: nutrient deficiency detection suggests feeding adjustments

## Stories in This Epic

**Calculator & Schedules:**
- `docs/stories/16.1.nutrient-dosage-calculator.md` – Core calculator logic
- `docs/stories/16.2.feeding-charts-ghe-and-advanced-nutrients.md` – GHE, AN schedules
- `docs/stories/16.3.feeding-charts-fox-farm-canna-biobizz.md` – FF, Canna, BioBizz schedules
- `docs/stories/16.4.custom-nutrient-recipes.md` – User-defined mixes

**Tracking & Logging:**
- `docs/stories/16.5.ppm-ec-tds-calculator-and-tracker.md` – PPM/EC/TDS tools
- `docs/stories/16.6.ph-tracking-and-recommendations.md` – pH management
- `docs/stories/16.7.nutrient-event-logging-and-timeline.md` – Feeding history

**Pro Features:**
- `docs/stories/16.8.nutrient-cost-tracking.md` – Cost analysis (Pro)
- `docs/stories/16.9.nutrient-analytics-and-deficiency-correlation.md` – Advanced insights (Pro)

**Safety & Education:**
- `docs/stories/16.10.mixing-instructions-and-safety-warnings.md` – Safety content

## Change Log

| Date       | Version | Description                            | Author |
|-----------|---------|----------------------------------------|--------|
| 2025-11-15 | 1.0     | Initial epic creation per user request | Mary (BA) |
