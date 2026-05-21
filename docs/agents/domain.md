# Domain Docs

Cara skill engineering mengonsumsi domain docs repo ini saat eksplorasi codebase.

## Sebelum eksplorasi, baca ini

- **`CONTEXT-MAP.md`** di root repo — peta seluruh konteks. Mulai dari sini.
- **`CONTEXT.md`** per-feature di bawah `OpenSpace/OpenSpace/Features/<Feature>/` (mis. `Features/Onboarding/CONTEXT.md`) dan untuk lapis cross-cutting di `OpenSpace/OpenSpace/Shared/CONTEXT.md`. Baca yang relevan dengan topik.
- **`docs/adr/`** di root — keputusan arsitektur sistem-wide (mis. pilihan TCA, SwiftData, Swift Testing, minimum deployment iOS 17.6).
- **`OpenSpace/OpenSpace/Features/<Feature>/docs/adr/`** dan **`OpenSpace/OpenSpace/Shared/docs/adr/`** — keputusan scoped per konteks.

Kalau salah satu file ini belum ada, **lanjut diam-diam**. Jangan flag absence-nya; jangan usulkan create upfront. Skill producer (`/real-engineer-grill-with-docs`) bikin lazy saat term atau decision benar-benar ter-resolve.

## Struktur file

Multi-context (repo ini):

```
/
├── CONTEXT-MAP.md
├── docs/adr/                                       ← system-wide decisions
└── OpenSpace/OpenSpace/
    ├── Features/
    │   ├── Onboarding/
    │   │   ├── CONTEXT.md
    │   │   ├── docs/adr/                           ← feature-scoped decisions
    │   │   ├── Presenter/
    │   │   ├── Application/
    │   │   ├── Domain/
    │   │   └── Infrastructure/
    │   └── <OtherFeature>/
    │       └── ...
    └── Shared/
        ├── CONTEXT.md
        ├── docs/adr/                               ← cross-cutting decisions
        └── <Client>/
            ├── Interface/
            ├── Live/
            └── Test/
```

## Pakai vocabulary glossary

Saat output menamai konsep domain (judul issue, proposal refactor, hipotesis, nama test), pakai term sesuai definisi di `CONTEXT.md` feature terkait. Jangan drift ke sinonim yang glossary hindari secara eksplisit.

Kalau konsep belum di glossary, itu sinyal — entah Anda inventing bahasa yang proyek tidak pakai (reconsider), atau ada real gap (catat untuk `/real-engineer-grill-with-docs`).

## Flag konflik ADR

Kalau output bertentangan dengan ADR yang ada, surface eksplisit alih-alih silently override:

> _Contradicts ADR-0007 (TCA Container/Flow split) — tapi worth reopening karena…_
