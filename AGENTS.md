# Agent guide for FiSi Trainer

Start here: [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md) has the full architecture and maintenance reference (data flow, per-file map, game rules, exam-subsystem details, "how do I …" recipes, persistence, pets/SceneKit/local AI, tests, build/release, gotchas). Read it before planning a change so you don't have to read the whole codebase first.

FiSi Trainer is a native macOS learning app for Fachinformatiker Systemintegration topics. Product copy and explanations are German. Keep the code simple and follow the existing SwiftUI, SceneKit and Foundation patterns.

## Architecture and scope

- Minimum runtime: macOS 14. Build with Xcode 26 or newer; GitHub Actions currently uses Xcode 26.6.
- No third-party Swift packages, backend, user accounts or cloud AI. Do not add dependencies without a concrete need.
- `FiSiTrainerApp.swift` injects `GameStore`, `SubnetStore`, `ExamStore` and `RewardStore` as shared environment objects.
- `Models.swift` and `GameStore.swift` implement the port quiz; `SubnetTrainer.swift` contains the subnet game.
- `ExamModels.swift`, `ExamCatalog.swift` (plus the `ExamCatalog*.swift` content files), `ExamTaskFactory.swift`, `ExamCalculation.swift`, `ExamStore.swift` and `ExamViews.swift` implement the "Prüfungswissen" exam arena (9 game modes over ~730 authored cards and 21 calculation generators). `ExamStore` owns its sessions, XP, adaptive-learning records and exam-simulation history, mirroring `GameStore`/`SubnetStore`.
- `AdaptiveLearning.swift` and `QuestionTiming.swift` hold learning weights and persistent per-question timing.
- `Rewards.swift` owns the shared level roadmap, unlocks, per-pet equipment and persistence.
- `PetScene.swift` owns the SceneKit lifecycle, camera and animations. `PetDetailGeometry.swift` and `PetAccessoryGeometry.swift` build procedural geometry.
- `PetIntelligence.swift` uses Apple's on-device Foundation Models. Keep framework imports and API calls guarded so the rest of the app works on macOS 14. The model is optional and must never grade answers or award XP.
- `project.yml` is the source for the checked-in `FiSiTrainer.xcodeproj`. Regenerate with XcodeGen when changing targets, settings or source/resource files.

## Working style and agent coordination

- For work with independent substantial parts, use agents with GPT-6-Sol or the user-approved GPT-5.6/Terra models when available. Keep small fixes with one agent.
- Give each agent explicit file ownership. Avoid simultaneous edits to the same file; communicate shared APIs before implementation.
- The coordinating agent owns integration, review and the final build/test run. Do not run concurrent Xcode builds against the same DerivedData directory.
- Prefer small concrete implementations over new abstraction layers, duplicated state or speculative systems.
- Preserve unrelated local edits. Do not reset personal training data to produce tests or screenshots.
- Explain outcomes, validation and any remaining limitations clearly in German when working with the project owner.

## Build and validation

Open `FiSiTrainer.xcodeproj`, choose the `FiSiTrainer` scheme and `My Mac`, then use Command-R to run or Command-U to test.

```sh
# After project.yml changes or adding/removing source files/resources:
xcodegen generate

# Run the test suite:
xcodebuild test -project FiSiTrainer.xcodeproj -scheme FiSiTrainer \
  -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO

# Exercise the same universal-app packaging used for releases:
bash Scripts/package-release.sh /tmp/fisi-release v1.0.0
```

- Check the command exit status and final Xcode result. Do not report success from intermediate compiler output.
- Run checks appropriate to the change. Documentation-only changes need link/format checks, not a new full test suite.
- Tests should cover behavior and compatibility, not repeat implementation details. Use temporary save locations and injected time for deterministic tests.
- Inspect changes to SceneKit visually at both habitat and compact companion sizes. Check equipment, camera framing, animation reset and Reduce Motion behavior.
- `build/`, `dist/`, DerivedData, local user settings and the local duplicate `FiSiTrainer 2.xcodeproj` are not source artifacts.

## Behavior that must remain compatible

- Existing JSON saves must remain readable. New optional fields need defaults; stable enum raw values and service IDs are persistence keys.
- Preserve damaged save files and the explicit recovery flow. A read error must not silently overwrite progress.
- Shared reward XP is a high-water mark: resetting one game must not relock earned pets or equipment.
- Equipment selection is per pet. Validate unlock levels on load and mutation, not only in the view.
- Both quizzes support number keys and Return. Keep explanatory feedback and accessible labels.
- Question timing survives navigation and restart. There is no timeout. Wrong answers receive no speed bonus; old answered questions receive no retroactive bonus.
- Adaptive learning keeps new and previously mastered topics in the mix. Do not make repeated errors the only source of questions.
- Pet interactions award bond, not learning XP. Keep actions and scene nodes bounded when interactions are repeated or views are destroyed.
- AI requests are explicit user actions. Use bounded context, hide the stored solution before submission, cancel stale requests and label prepared fallback text accurately. Chat history stays in memory.

## Icons, screenshots and documentation

- `FiSiTrainer/AppIcon.icon` is an editable Icon Composer document with original SVG layers in `Assets/`.
- Keep `ASSETCATALOG_COMPILER_APPICON_NAME` consistent with the document name. Verify the compiled app bundle and macOS icon lookup when changing icon integration; a successful build alone does not prove the Dock cache refreshed.
- Capture documentation images from the real views or procedural scenes with isolated demo data. Do not publish personal saves, chat transcripts, desktop content or mockups presented as screenshots.
- Keep README download links, workflow names, minimum versions and feature claims synchronized with actual behavior. Ideas are not implemented features.

## GitHub and releases

- Repository: https://github.com/MagicalWig34653/fisi-trainer
- `build.yml` runs tests for pushes to `main` and pull requests. Untrusted PR jobs use read-only permissions and no credentials.
- `release.yml` packages a published release's tag and attaches the app DMG and SHA-256 checksum to that release.
- Release tags use `vMAJOR.MINOR.PATCH`. The packaging script sets the app marketing version, verifies both `arm64` and `x86_64`, creates a clean staging copy, signs locally and packages the `.app` as a DMG with `Scripts/create-dmg.sh`. DMG tooling is version-pinned in `Packaging/requirements-dmg.txt` and isolated from app dependencies.
- Release apps currently have an ad-hoc signature. They are not Developer-ID-signed or notarized. Do not imply otherwise or add Gatekeeper-disabling instructions.
- Keep GitHub tokens in the step that requires them. Pass event-derived strings through quoted environment variables rather than interpolating them into shell code. Pin external actions to reviewed commit SHAs.
- For DMG changes, verify the image, mount it and check the app signature, Applications link, background and Finder layout. Keep the background artwork and icon coordinates in sync; no GUI automation should be required on CI.
- Before publishing, review staged files for personal paths, credentials, user-specific Xcode files and build output. Preserve the user's authorization scope; do not publish a release or push changes unless requested or already authorized for the task.

## License

The project, including original artwork and documentation, is AGPL-3.0-only. Preserve `LICENSE`, `NOTICE` and existing SPDX headers. Include the license with distributed app bundles and keep matching release source available. Apple system frameworks and SF Symbols remain subject to Apple's terms and are not relicensed here.
