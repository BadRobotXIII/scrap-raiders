# SCRAP Raiders development conventions

Read README.md before changing the project. The working title is internal only.

- Use Godot 4.7.2 Standard and GDScript; prefer built-in engine features.
- Work on one director-approved milestone at a time. Discuss major gameplay or architecture changes before implementation.
- Keep changes small and preserve existing user work. Do not add speculative networking or progression.
- Give state one authoritative owner. Keep physical input, intent, simulation, and presentation separate where practical.
- Use explicit, centrally managed state transitions for AI and mission phases.
- Prefer composition, signals for events, and data resources when definitions become necessary. Avoid unnecessary global state and abstractions.
- Use snake_case for files, functions, variables, and signals; PascalCase for named script classes; SCREAMING_SNAKE_CASE for constants and enum values.
- Use typed GDScript where practical. Run physical movement in _physics_process().
- Use original assets or document third-party sources and licenses. The current arena uses only engine primitives.
- Validate with `godot --headless --path . --editor --quit`, then a bounded runtime launch. Check output for errors as well as exit status.
- Add meaningful logic tests when gameplay systems are introduced. Distinguish parsing, launching, automated tests, and manual play-testing in reports.
- Keep generated .godot files and exports out of Git. Track Godot-generated script .uid files.
- Do not commit or publish changes unless requested.
