# Who made this, and how carefully

*A [Rigor, Vouch, Stages](https://rigor.diaconou.com/) disclosure stamp. The format and vocabulary are specified at [rigor.diaconou.com/spec](https://rigor.diaconou.com/spec/), version 1.0.*

<!-- rigor:summary -->
**The idea was mine. Before LLMs, the plan was mine, and worked in depth over
iterations; the implementation was written by me; it was reviewed for quality
and for security, and tested, all by me. Since LLMs, the plan and the
implementation have been reworked by me with an AI, and it has been reviewed for
quality and for security, and tested, all by me with an AI. The project is
complete; it will not gain new features. I stand behind this code as soundly
engineered and hold architectural responsibility for it. This assessment is as
of 2026-09-03. I recommend this for use; I put my name behind it. Statement made
by: Stephen Ierodiaconou.**
<!-- /rigor:summary -->

## Notes

This code began in 2018 inside a client project and was extracted into a gem in
2019. The design, the first years of implementation, and the test suite up to
2024 are mine, written by hand.

From 2025 the work changed shape. Significant new features, refactoring, and
architectural changes were done with an AI, under my direction, and reviewed by
me with an AI. The codebase today is a human-written core that has been
substantially reworked with an AI.

Since LLMs, quality and security have been reviewed by me with an AI, and the
suite of several hundred tests, run against several Rails versions under CI,
was extended the same way. I have read the AI-era changes and can account for
them.

The project is complete from a feature point of view. What it will still
receive is fixes, performance work, and updates for new Rails releases:
`activity: active`, `scope: complete`.

## Stamp

```yaml
spec: "1.0"
signed: "Stephen Ierodiaconou"
rigor: owned
vouch: yes
checks:
  comprehended: [human, human-with-ai]
  quality_reviewed: [human, human-with-ai]
  security_reviewed: [human, human-with-ai]
  tested: [human, human-with-ai]
  owned: human
stages:
  idea: {by: human}
  plan: {by: [human, human-with-ai], depth: deep}
  implementation: {by: [human, human-with-ai]}
  maintenance: {by: human-with-ai, activity: active, scope: complete}
assessed: 2026-09-03
```

<!--
checks: surface any subset; a done value names who did it.
  comprehended / quality_reviewed / security_reviewed / tested / owned:
    yes | human | ai | human-with-ai | no | not-applicable,
    or a pair [before LLMs, since LLMs] of actors.
  engineered and owned must surface the checks they imply; comprehended
  cannot be satisfied by an AI alone.
Run `rigor-md fmt RIGOR.md` after editing the stamp to refresh the summary.
-->