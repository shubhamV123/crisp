# crisp — benchmark results

Real token counts from the Claude API.
Each prompt run 3 times per model, results averaged.
Baseline = plain Claude with no skill active.
Run date: 2026-05-20T10:33:28Z

## Results by model

### Haiku 4.5 `claude-haiku-4-5-20251001`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **33.85%** |
| Word count | **59.14%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 601 | 317 | 47.25% | 180 | 79 | 56.11% |
| db-pooling | 627 | 355 | 43.38% | 281 | 55 | 80.43% |
| drop-table | 551 | 386 | 29.95% | 143 | 90 | 37.06% |
| auth-vs-authz | 308 | 195 | 36.69% | 121 | 33 | 72.73% |
| multi-turn-recall | 267 | 235 | 11.99% | 77 | 39 | 49.35% |

### Sonnet 4.6 `claude-sonnet-4-6`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **64.49%** |
| Word count | **68.03%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 294 | 109 | 62.93% | 158 | 59 | 62.66% |
| db-pooling | 360 | 101 | 71.94% | 216 | 55 | 74.54% |
| drop-table | 194 | 84 | 56.70% | 86 | 19 | 77.91% |
| auth-vs-authz | 75 | 14 | 81.33% | 43 | 8 | 81.40% |
| multi-turn-recall | 222 | 112 | 49.55% | 55 | 31 | 43.64% |

### Opus 4.7 `claude-opus-4-7`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **68.23%** |
| Word count | **65.54%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 133 | 79 | 40.60% | 51 | 31 | 39.22% |
| db-pooling | 326 | 49 | 84.97% | 136 | 18 | 86.76% |
| drop-table | 228 | 57 | 75.00% | 110 | 20 | 81.82% |
| auth-vs-authz | 88 | 21 | 76.14% | 36 | 8 | 77.78% |
| multi-turn-recall | 135 | 48 | 64.44% | 38 | 22 | 42.11% |

## Notes

- Token counts are **output tokens only** from `.modelUsage[model].outputTokens`.
  Input tokens are not affected by crisp.
- The `drop-table` prompt intentionally shows lower reduction — the Auto-Clarity
  Exception fires a full-prose safety warning before giving the SQL.
  This is correct behavior: crisp prioritises clarity over compression for irreversible ops.
- Negative reduction = skill made the response longer for this prompt.
  Opus 4.7 baseline is already terse; crisp adds less value on very short answers.
- Reproduce: `chmod +x run_benchmark.sh && ./run_benchmark.sh`
