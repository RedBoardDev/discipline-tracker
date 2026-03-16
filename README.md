# Discipline Tracker

A minimal iOS app to build discipline and consistency through simple daily goals, streak tracking, and clear visual feedback.

The app is designed to stay extremely simple: check what you did today, maintain your streak, and visualize your consistency over time.

Inspired by **Apple Reminders** for simplicity and **Duolingo streak mechanics** for motivation.

---

## Features

* Daily goal tracking with simple **binary check (done / not done)**
* **Perfect day streak** tracking
* **Per-goal streaks**
* **Monthly calendar view** to review past days
* **Heatmap visualization** of consistency
* **Interactive widget** to check goals directly from the home screen
* **Smart daily notification** to remind unfinished goals
* **GitHub contribution detection** as an automatic goal
* Fully **local-first** (no backend, no account)
* **Configurable goals via JSON**

---

## Philosophy

Discipline Tracker is intentionally minimal.

Instead of adding complex gamification systems, the app focuses on a few powerful concepts:

* consistency
* streak protection
* visual feedback
* low friction

The goal is to make it **easy to show up every day**.

---

## Configuration

Goals are defined in a single JSON configuration file.

Example:

```json
{
  "objectives": [
    {
      "id": "english",
      "title": "1h English",
      "type": "manualBinary",
      "expectedMinutes": 60,
      "icon": "globe",
      "accent": "blue",
      "activeDays": ["mon","tue","wed","thu","fri","sat","sun"]
    }
  ]
}
```

This makes it easy to modify goals without changing the UI.

---

## Roadmap

Possible future improvements:

* iCloud sync
* additional widgets
* yearly progress review
* advanced visualizations
* goal templates
* more configurations

MIT License.
