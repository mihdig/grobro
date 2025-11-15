# Epic 4: Knowledge Base & Education

## Status

Approved

## Summary

Provide safe, educational content that helps users understand plant care fundamentals without crossing legal boundaries:

- In-app Guides section with curated educational articles
- Context-aware tips integrated into app workflows
- Safety and legal compliance information
- Community-sourced best practices (moderated)
- Search and bookmark functionality for educational content

This epic positions GroBro as an educational platform, not just a tracking tool, while maintaining strict legal and safety boundaries.

## Business Value

- Increases user engagement and time-in-app through educational content
- Reduces support burden by providing self-service learning resources
- Establishes GroBro as a trusted authority in plant care
- Provides legal protection through clear disclaimers and safety information
- Creates opportunities for content partnerships and sponsored educational content (future monetization)
- Improves user retention by helping users succeed with their grows

## In Scope

- Guides section UI with categorized articles
- Educational content on:
  - How to maintain a plant diary effectively
  - Understanding substrate moisture and checking techniques
  - Light basics (distance, spectrum, photoperiod concepts)
  - Recognizing common stress signs (overwatering, underwatering, light stress)
  - Using the app's features effectively (diagnostics, debug console, analytics)
- Safety and legal compliance section with:
  - User responsibility for local law compliance
  - Data privacy and security information
  - Safe growing practices (fire safety, electrical safety, ventilation)
- Context-aware tips system that surfaces relevant guides based on user actions
- Search functionality across all educational content
- Bookmark/favorite system for user-saved articles
- Content versioning and update mechanism

## Out of Scope (for this Epic)

- User-generated content or forums (moderation challenges)
- Strain-specific growing instructions (legal risk)
- Nutrient recipes or feeding schedules (consumption risk)
- Detailed cultivation techniques for THC maximization
- Sales or marketplace features
- Integration with external forums or communities
- Video content (bandwidth and hosting costs)

## Epic-Level Acceptance Criteria

1. Users can access a "Guides" section from the main navigation showing categorized educational articles
2. All guides display with clear disclaimers about local law compliance and user responsibility
3. Guides include:
   - "Maintaining Your Plant Diary" (how to use GroBro effectively)
   - "Understanding Substrate Moisture" (finger test, weight method, visual cues)
   - "Light Basics for Healthy Plants" (distance, intensity, schedule concepts)
   - "Recognizing Common Stress Signs" (visual guide to overwatering, underwatering, light burn, nutrient issues)
   - "Using Diagnostics and Debug Console" (maximizing GroBro's AI features)
   - "Safety and Legal Compliance" (user responsibilities, safety practices)
4. Context-aware tips appear at relevant moments (e.g., "Learn about watering" tip when creating first watering event)
5. Users can search all guide content by keyword
6. Users can bookmark guides for quick access
7. Guide content can be updated without app updates (delivered via CloudKit or similar)
8. All content is accessible offline after first load
9. Content avoids medical claims, consumption advice, and illegal activity instructions
10. Analytics track which guides are most helpful to inform future content creation

## Stories in This Epic

- Content Infrastructure:
  - `docs/stories/10.1.guides-section-and-content-delivery.md` – UI and content management system
  - `docs/stories/10.2.search-and-bookmarks.md` – Search functionality and user bookmarks
- Educational Content:
  - `docs/stories/10.3.core-educational-content.md` – Writing and integrating core guides
  - `docs/stories/10.4.context-aware-tips-system.md` – Surfacing relevant tips based on user actions
- Compliance:
  - `docs/stories/10.5.safety-and-legal-content.md` – Safety, legal, and privacy information
  - `docs/stories/10.6.content-moderation-guidelines.md` – Internal guidelines for content review

Future epics can add community features (with proper moderation), video content, and interactive learning modules.
