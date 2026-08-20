---
title: "Event Ingest: Split the Pools"
subtitle: "Design note for the Q3 platform review"
author: "Platform team"
date: "2026-08-19"
toc: true
---

# Summary

The ingest pipeline drops 3.2% of events under burst load because the parser and the
writer share one thread pool. This note proposes splitting them behind a bounded queue.
The change costs two weeks; the alternative (a bigger shared pool) buys one month and
returns the same failure.

> [!NOTE]
> Numbers below come from the 2026-08-12 load test, run three times; the spread was
> under 0.4%.

# Current behaviour

The receiver hands events to the parser, and the parser hands rows to the writer. Both
stages draw threads from the same pool of eight.

```{.diagram caption="Figure 1. Today: one pool feeds both stages"}
┌──────────┐   events   ┌──────────┐   rows    ┌──────────┐
│ receiver ├───────────►│  parser  ├──────────►│  writer  │
└──────────┘            └────┬─────┘           └────┬─────┘
                             │  shared pool (8)      │
                             └───────────────────────┘
```

Under burst the writer blocks on `fsync` and starves the parser, so the receiver's
buffer overflows and events drop on the floor before anything logs them.

The load test, 2026-08-12, three runs each:

Table: Drop rate by burst size.

| Burst (events/s) | Pool 8 | Pool 16 | Split 4+4 |
|---|---|---|---|
| 5,000 | 0.0% | 0.0% | 0.0% |
| 20,000 | 1.1% | 0.2% | 0.0% |
| 50,000 | 3.2% | 1.1% | 0.0% |

# Options

| Option | Effort | Drop rate after | Risk |
|---|---|---|---|
| Bigger shared pool | 2 days | 1.1% | returns in a month as load grows |
| Split pools + bounded queue | 2 weeks | 0.0% | queue sizing |
| Rewrite on Kafka | 2 months | 0.0% | operational surface |

> [!TIP]
> The split is the smallest change that removes the coupling rather than delaying it.

# Proposed change

Two pools and a bounded queue between them. The bound is the point: when the writer
falls behind, the parser blocks on `put()` instead of the receiver dropping events.

```{.python caption="Listing 1. The pipeline with split pools"}
class Pipeline:
    def __init__(self, parse_workers: int = 4, write_workers: int = 4) -> None:
        self.queue: asyncio.Queue[Row] = asyncio.Queue(maxsize=10_000)
        self.parsers = [Parser(self.queue) for _ in range(parse_workers)]
        self.writers = [Writer(self.queue) for _ in range(write_workers)]

    async def run(self) -> None:
        await asyncio.gather(*(p.run() for p in self.parsers),
                             *(w.run() for w in self.writers))
```

> [!WARNING]
> The queue bound is load-bearing. An unbounded queue moves the drop into an OOM.

## Rollout

1. Ship behind `PIPELINE_SPLIT=1`.
2. Shadow for one week and compare drop rate against the table above.
3. Flip the default, then remove the flag after two releases.

## What stays the same

- The receiver's wire format.
- The writer's on-disk layout.
- Metrics names, so dashboards keep working.

\newpage

# Appendix A. Shell session from the test

```bash
$ ./loadgen --rate 50000 --seconds 60 | tee run-3.log
sent=3000000 acked=2904000 dropped=96000 (3.2%)
```

> [!IMPORTANT]
> Re-run the load test after the flag flips; the table is the baseline for the comparison.
