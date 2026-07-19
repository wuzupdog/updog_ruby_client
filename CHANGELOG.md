# Changelog

## 0.2.0

- Make capture calls non-blocking through a bounded single-worker in-memory queue.
- Bulk error notices and add stable event/request IDs, occurrence timestamps, and resource metadata.
- Add retry classification, `Retry-After`, full-jitter backoff, 413 splitting, counters, and bounded flush/shutdown APIs.
