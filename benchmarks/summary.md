# crisp — benchmark results

Real token counts from the Claude API.
Each prompt run 3 times per model, results averaged.
Baseline = plain Claude with no skill active.
Run date: 2026-05-20T15:42:17Z

## Results by model

### Haiku 4.5 `claude-haiku-4-5-20251001`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **29.07%** |
| Word count | **68.61%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 615 | 317 | 48.46% | 188 | 61 | 67.55% |
| db-pooling | 520 | 392 | 24.62% | 256 | 42 | 83.59% |
| drop-table | 496 | 401 | 19.15% | 150 | 38 | 74.67% |
| auth-vs-authz | 386 | 191 | 50.52% | 124 | 30 | 75.81% |
| multi-turn-recall | 230 | 224 | 2.61% | 70 | 41 | 41.43% |

### Sonnet 4.6 `claude-sonnet-4-6`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **70.26%** |
| Word count | **70.42%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 356 | 107 | 69.94% | 182 | 56 | 69.23% |
| db-pooling | 351 | 80 | 77.21% | 215 | 44 | 79.53% |
| drop-table | 367 | 90 | 75.48% | 117 | 19 | 83.76% |
| auth-vs-authz | 67 | 14 | 79.10% | 36 | 8 | 77.78% |
| multi-turn-recall | 224 | 113 | 49.55% | 55 | 32 | 41.82% |

### Opus 4.7 `claude-opus-4-7`

| Metric | Average reduction |
|--------|------------------|
| Output tokens | **61.37%** |
| Word count | **61.10%** |

| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |
|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|
| react-rerender | 113 | 83 | 26.55% | 45 | 32 | 28.89% |
| db-pooling | 163 | 62 | 61.96% | 70 | 23 | 67.14% |
| drop-table | 213 | 66 | 69.01% | 94 | 22 | 76.60% |
| auth-vs-authz | 79 | 21 | 73.42% | 32 | 8 | 75.00% |
| multi-turn-recall | 137 | 33 | 75.91% | 38 | 16 | 57.89% |

## Notes

- Token counts are **output tokens only** from `.modelUsage[model].outputTokens`.
  Input tokens are not affected by crisp.
- The `drop-table` prompt intentionally shows lower reduction — the Auto-Clarity
  Exception fires a full-prose safety warning before giving the SQL.
  This is correct behavior: crisp prioritises clarity over compression for irreversible ops.
- Negative reduction = skill made the response longer for this prompt.
  Opus 4.7 baseline is already terse; crisp adds less value on very short answers.
- Reproduce: `chmod +x run_benchmark.sh && ./run_benchmark.sh`
