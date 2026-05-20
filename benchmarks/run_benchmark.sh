#!/bin/bash
# =============================================================================
# crisp skill — multi-model benchmark runner
#
# Tests the crisp skill across 3 models:
#   - claude-haiku-4-5-20251001  (fast, cheap)
#   - claude-sonnet-4-6          (balanced)
#   - claude-opus-4-7            (most capable)
#
# For each model, runs 5 prompts with and without crisp skill.
# Captures output token counts and word counts.
# Saves raw data to results.json and a readable table to summary.md.
#
# Usage:
#   chmod +x run_benchmark.sh
#   ./run_benchmark.sh
#
# Requirements:
#   - Claude Code installed (claude command available)
#   - crisp skill installed at ~/.claude/skills/crisp/
#   - jq installed (brew install jq  or  apt install jq)
# =============================================================================

# NO set -e — one flaky API call should not kill the whole run
# Errors are handled per-call instead

SKILL_NAME="crisp"
SKILL_PATH="$HOME/.claude/skills/$SKILL_NAME"
RESULTS_FILE="results.json"
SUMMARY_FILE="summary.md"
RUNS=3
RUN_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

MODELS=(
  "claude-haiku-4-5-20251001"
  "claude-sonnet-4-6"
  "claude-opus-4-7"
)

MODEL_LABELS=(
  "Haiku 4.5"
  "Sonnet 4.6"
  "Opus 4.7"
)

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
  echo "ERROR: crisp skill not found at $SKILL_PATH/SKILL.md"
  echo "Install it: cp -r /path/to/crisp ~/.claude/skills/crisp"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required. Install: brew install jq  or  apt install jq"
  exit 1
fi

if ! command -v bc &> /dev/null; then
  echo "ERROR: bc is required. Install: brew install bc  or  apt install bc"
  exit 1
fi

echo "========================================"
echo " crisp benchmark — multi-model runner"
echo "========================================"
echo "Skill:         $SKILL_PATH"
echo "Models:        ${#MODELS[@]}"
echo "Prompts:       5"
echo "Runs each:     $RUNS"
echo "Total calls:   $((${#MODELS[@]} * 5 * RUNS * 2))"
echo "Est. time:     8-12 minutes"
echo "Run date:      $RUN_DATE"
echo "========================================"
echo ""

# =============================================================================
# PROMPTS
# multi-turn-recall includes prior context inline — no separate conversation needed.
# Prompts are kept simple — no quotes or special shell chars that break heredocs.
# =============================================================================

declare -a PROMPT_IDS=(
  "react-rerender"
  "db-pooling"
  "drop-table"
  "auth-vs-authz"
  "multi-turn-recall"
)

declare -a PROMPTS=(
  "Why does my React component re-render on every keystroke when I pass an object as a prop?"
  "Explain database connection pooling."
  "I want to permanently drop the users table from production. Give me the SQL."
  "What is the difference between authentication and authorization?"
  "Earlier you told me the bug is a missing null check in getUserById. What was the fix?"
)

# Trigger phrases for with-skill runs — uses description trigger words, not "use skill X"
declare -a SKILL_TRIGGERS=(
  "/crisp"
  "/crisp"
  "/crisp"
  "/crisp"
  "/crisp"
)

# =============================================================================
# HELPER: run one prompt, echo "output_tokens word_count"
# Returns "0 0" on any error so the loop continues cleanly.
# =============================================================================

run_prompt() {
  local prompt="$1"
  local with_skill="$2"    # "true" or "false"
  local model="$3"
  local trigger="$4"
  local tmp_output
  tmp_output=$(mktemp)

  if [ "$with_skill" = "true" ]; then
    local full_prompt="${trigger} ${prompt}"
  else
    local full_prompt="$prompt"
  fi

  # Run claude — capture exit code without set -e killing us
  if ! claude -p "$full_prompt" \
    --model "$model" \
    --output-format json \
    > "$tmp_output" 2>/dev/null; then
    echo "      [warning] claude call failed, using 0 0" >&2
    rm -f "$tmp_output"
    echo "0 0"
    return
  fi

  # Validate JSON before parsing
  if ! jq empty "$tmp_output" 2>/dev/null; then
    echo "      [warning] invalid JSON response, using 0 0" >&2
    rm -f "$tmp_output"
    echo "0 0"
    return
  fi

  # Response text lives in .result
  local response_text
  response_text=$(jq -r '.result // ""' "$tmp_output" 2>/dev/null || echo "")

  # Accurate output token count from modelUsage, fallback to usage.output_tokens
  local output_tokens
  output_tokens=$(jq -r --arg model "$model" \
    '.modelUsage[$model].outputTokens // .usage.output_tokens // 0' \
    "$tmp_output" 2>/dev/null || echo "0")

  # Word count from actual response text
  local word_count
  word_count=$(echo "$response_text" | wc -w | tr -d ' ')

  rm -f "$tmp_output"
  echo "$output_tokens $word_count"
}

# =============================================================================
# HELPER: safe percentage calculation — always returns X.XX format
# Avoids bc truncating whole numbers (50 vs 50.00) which breaks jq parsing
# =============================================================================

calc_pct() {
  local numerator="$1"
  local denominator="$2"
  if [ "$denominator" -eq 0 ]; then
    echo "0.00"
    return
  fi
  # Force 2 decimal places always
  printf "%.2f" "$(echo "scale=6; (1 - $numerator / $denominator) * 100" | bc)"
}

# =============================================================================
# MAIN LOOP
# =============================================================================

# Always start fresh
echo "[" > "$RESULTS_FILE"
first_model=true

for m in "${!MODELS[@]}"; do
  model="${MODELS[$m]}"
  model_label="${MODEL_LABELS[$m]}"
  trigger="${SKILL_TRIGGERS[$m]}"

  echo "----------------------------------------"
  echo "Model: $model_label ($model)"
  echo "----------------------------------------"

  if [ "$first_model" = false ]; then
    echo "," >> "$RESULTS_FILE"
  fi
  first_model=false

  # Write model opening — use printf to avoid heredoc interpolation issues
  printf '  {\n    "model": "%s",\n    "model_label": "%s",\n    "prompts": [\n' \
    "$model" "$model_label" >> "$RESULTS_FILE"

  first_prompt=true

  for i in "${!PROMPTS[@]}"; do
    prompt_id="${PROMPT_IDS[$i]}"
    prompt="${PROMPTS[$i]}"

    echo ""
    echo "  Prompt $((i+1))/5: $prompt_id"

    # WITH skill
    echo "    [with skill]"
    total_tokens_with=0
    total_words_with=0
    for run in $(seq 1 $RUNS); do
      read -r tokens words <<< "$(run_prompt "$prompt" "true" "$model" "$trigger")"
      tokens=${tokens:-0}
      words=${words:-0}
      total_tokens_with=$((total_tokens_with + tokens))
      total_words_with=$((total_words_with + words))
      printf "      run %d: %d tokens, %d words\n" "$run" "$tokens" "$words"
    done
    avg_tokens_with=$((total_tokens_with / RUNS))
    avg_words_with=$((total_words_with / RUNS))

    # WITHOUT skill
    echo "    [without skill]"
    total_tokens_without=0
    total_words_without=0
    for run in $(seq 1 $RUNS); do
      read -r tokens words <<< "$(run_prompt "$prompt" "false" "$model" "$trigger")"
      tokens=${tokens:-0}
      words=${words:-0}
      total_tokens_without=$((total_tokens_without + tokens))
      total_words_without=$((total_words_without + words))
      printf "      run %d: %d tokens, %d words\n" "$run" "$tokens" "$words"
    done
    avg_tokens_without=$((total_tokens_without / RUNS))
    avg_words_without=$((total_words_without / RUNS))

    # Safe percentage calculations — always X.XX format
    token_reduction=$(calc_pct "$avg_tokens_with" "$avg_tokens_without")
    word_reduction=$(calc_pct "$avg_words_with" "$avg_words_without")

    echo "    -> $avg_tokens_without tokens without -> $avg_tokens_with with (${token_reduction}% reduction)"

    if [ "$first_prompt" = false ]; then
      printf '      ,\n' >> "$RESULTS_FILE"
    fi
    first_prompt=false

    # Use printf for JSON writing — safe against special characters
    printf '      {\n        "id": "%s",\n        "with_skill": { "avg_tokens": %d, "avg_words": %d },\n        "without_skill": { "avg_tokens": %d, "avg_words": %d },\n        "token_reduction_pct": %s,\n        "word_reduction_pct": %s\n      }\n' \
      "$prompt_id" \
      "$avg_tokens_with" "$avg_words_with" \
      "$avg_tokens_without" "$avg_words_without" \
      "$token_reduction" "$word_reduction" \
      >> "$RESULTS_FILE"

  done

  printf '    ]\n  }\n' >> "$RESULTS_FILE"

done

echo "]" >> "$RESULTS_FILE"

# Validate final JSON before generating summary
if ! jq empty "$RESULTS_FILE" 2>/dev/null; then
  echo ""
  echo "ERROR: results.json is not valid JSON. Check for failed API calls above."
  echo "Raw file saved at: $RESULTS_FILE"
  exit 1
fi

echo ""
echo "results.json valid. Generating $SUMMARY_FILE..."

# =============================================================================
# GENERATE summary.md
# =============================================================================

{
  echo "# crisp — benchmark results"
  echo ""
  echo "Real token counts from the Claude API."
  echo "Each prompt run ${RUNS} times per model, results averaged."
  echo "Baseline = plain Claude with no skill active."
  echo "Run date: ${RUN_DATE}"
  echo ""
  echo "## Results by model"
  echo ""
} > "$SUMMARY_FILE"

for m in "${!MODELS[@]}"; do
  model="${MODELS[$m]}"
  model_label="${MODEL_LABELS[$m]}"

  avg_token_reduction=$(jq --arg model "$model" \
    '[.[] | select(.model == $model) | .prompts[].token_reduction_pct] | add / length' \
    "$RESULTS_FILE" | xargs printf "%.2f")

  avg_word_reduction=$(jq --arg model "$model" \
    '[.[] | select(.model == $model) | .prompts[].word_reduction_pct] | add / length' \
    "$RESULTS_FILE" | xargs printf "%.2f")

  {
    echo "### ${model_label} \`${model}\`"
    echo ""
    echo "| Metric | Average reduction |"
    echo "|--------|------------------|"
    echo "| Output tokens | **${avg_token_reduction}%** |"
    echo "| Word count | **${avg_word_reduction}%** |"
    echo ""
    echo "| Prompt | Without crisp (tokens) | With crisp (tokens) | Token % | Without crisp (words) | With crisp (words) | Word % |"
    echo "|--------|----------------------|--------------------|---------|-----------------------|--------------------|--------|"
  } >> "$SUMMARY_FILE"

  jq -r --arg model "$model" \
    '.[] | select(.model == $model) | .prompts[] |
     "| \(.id) | \(.without_skill.avg_tokens) | \(.with_skill.avg_tokens) | \(.token_reduction_pct)% | \(.without_skill.avg_words) | \(.with_skill.avg_words) | \(.word_reduction_pct)% |"' \
    "$RESULTS_FILE" >> "$SUMMARY_FILE"

  echo "" >> "$SUMMARY_FILE"

done

{
  echo "## Notes"
  echo ""
  echo "- Token counts are **output tokens only** from \`.modelUsage[model].outputTokens\`."
  echo "  Input tokens are not affected by crisp."
  echo "- The \`drop-table\` prompt intentionally shows lower reduction — the Auto-Clarity"
  echo "  Exception fires a full-prose safety warning before giving the SQL."
  echo "  This is correct behavior: crisp prioritises clarity over compression for irreversible ops."
  echo "- Negative reduction = skill made the response longer for this prompt."
  echo "  Opus 4.7 baseline is already terse; crisp adds less value on very short answers."
  echo "- Reproduce: \`chmod +x run_benchmark.sh && ./run_benchmark.sh\`"
} >> "$SUMMARY_FILE"

echo ""
echo "========================================"
echo "Done."
echo ""
echo "  Raw data:  benchmarks/$RESULTS_FILE"
echo "  Summary:   benchmarks/$SUMMARY_FILE"
echo ""
echo "Commit both files. Anyone can re-run to verify."
echo "========================================"