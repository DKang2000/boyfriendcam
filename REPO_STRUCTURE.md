# Proposed Repo Structure

```text
Playground/
  app/
    _layout.tsx
    index.tsx
    camera.tsx
    history.tsx
    review.tsx
    settings.tsx
  src/
    app/
      providers/
      navigation/
      state/
    config/
      shot-templates/
      personas/
      crop-masks/
      feature-flags/
    domain/
      analysis/
        FrameAnalysisEngine/
        LightingAnalyzer/
        HorizonAnalyzer/
        adapters/
        types/
      guidance/
        GuidanceRuleEngine/
        PersonaFormatter/
        prompt-state/
        types/
      capture/
        CaptureOrchestrator/
        storage/
        types/
      crop/
        CropPreviewEngine/
    ui/
      camera/
        CameraPreview/
        OverlayLayer/
        PromptBar/
        HorizonBar/
        ReadyStateBadge/
        ShotSelector/
        BurstSelector/
        CropMaskSelector/
      history/
      review/
      shared/
    hooks/
    lib/
    types/
    test/
      fixtures/
      unit/
      integration/
  assets/
    icons/
    splash/
    overlays/
    placeholders/
  docs/
    privacy/
    release/
    store/
  PROMPTS/
    01-planning-pass.md
    02-milestone-execution.md
  PRD.md
  PLANS.md
  TASKS.md
  VIBECODE_LOG.md
  eas.json
  app.json
  package.json
  tsconfig.json
```

## Notes

- `app/` is reserved for route entry points and screen composition
- `src/domain/` holds swappable business logic and analyzer engines
- `src/config/` holds the data-driven registries required by the architecture
- `src/ui/` contains rendering concerns only
- `docs/` is reserved for privacy, release, and store checklists
- `PROMPTS/` records the main Codex prompts used during vibecoding
- The repo is intentionally a single Expo app, with modular internals rather than a monorepo
- App identity config should isolate public branding from swappable internal package/bundle placeholders
- History storage should keep saved-photo references and lightweight metadata only, not duplicate media blobs or raw analysis traces

## Feature Flag Strategy

Future modes should live behind config-driven feature flags:

- `selfieMode`
- `groupMode`
- `learnedAnalyzer`

The navigation and UI should only expose enabled features, while the underlying domain contracts remain stable.
