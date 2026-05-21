# crisp

A terse-output skill for AI agents. Shorter replies without stripping technical details.

---

## Before / After

**Without crisp:**

> "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by a problem in your authentication middleware where the token expiry check is using the wrong comparison operator..."

**With crisp:**

> Bug in auth middleware. Token expiry check uses `<` not `<=`. Fix:
>
> ```js
> if (now <= expiry) { ... }
> ```

Same technical details. Fewer words.

---

## Attribution

crisp was inspired by existing terse-output and agent-behavior work, including:

- [Caveman by Julius Brussee](https://github.com/JuliusBrussee/caveman)
- [Caveman skill by Matt Pocock](https://github.com/mattpocock/skills/blob/main/skills/productivity/caveman/SKILL.md)
- Common “no fluff” prompting patterns used in coding-agent workflows

crisp is my professional-tone variation of this idea: normal concise replies, no meme-style output, and careful preservation of code, errors, commands, numbers, and risky-operation context.

---

## Why crisp

crisp focuses on concise replies that still sound normal and professional.

The goal is not maximum compression at all costs. The goal is to remove filler while preserving clarity, especially in coding and technical workflows.

**crisp is designed to stay terse by default, but use clearer wording when compression could make the answer unsafe or ambiguous.**

For destructive operations, security warnings, and irreversible actions, crisp instructs the agent to use clear full-sentence warnings before returning to concise output. The goal is faster reading without compressing the parts where clarity matters.

```
// Destructive op — crisp uses clear prose first:

Warning: This permanently destroys all data in `users`. Cannot be undone.

DROP TABLE users;

Verify backup first.   ← concise mode resumes here
```

---

## Install

crisp follows the [Agent Skills](https://agentskills.io) specification. It works with any agent that supports skills.

```bash
npx skills add shubhamv123/crisp
```

**Any other agent / browser:**
Paste the contents of `SKILL.md` at the start of your conversation:

> "Follow these instructions for this entire conversation: [paste SKILL.md]"

---

## Usage

| What you type       | What happens    |
| ------------------- | --------------- |
| `crisp mode`        | Activates crisp |
| `go crisp`          | Activates crisp |
| `/crisp`            | Activates crisp |
| `be brief`          | Activates crisp |
| `cut the fluff`     | Activates crisp |
| `stop crisp`        | Back to normal  |
| `normal mode`       | Back to normal  |
| `explain in detail` | Back to normal  |

Once active, crisp stays on for the entire conversation — no need to re-trigger every message.

---

## What crisp reduces

- Unnecessary openings: "sure", "happy to help", "great question"
- Soft filler: "basically", "actually", "simply", "just"
- Repeated context already present in the user’s message
- Long hedging phrases when the answer is already clear
- Over-explaining before the actual fix

crisp removes filler, but not at the cost of clarity or safety.

---

## What always stays

- Technical terms, exact and unchanged
- Code blocks, untouched
- Error messages, quoted exactly
- Commands and flags
- Numbers and specifics
- Security warnings and destructive-action context

---

## What crisp does not guarantee

crisp does not make the underlying model more correct.

It only changes response style: fewer filler words, less repetition, and careful preservation of technical details such as code, commands, error messages, numbers, and warnings.

Correctness still depends on the model, prompt, and context.

---

## Auto-Clarity Exception

crisp is designed to use clearer prose for:

- Destructive / irreversible operations
- Security warnings
- Multi-step sequences where fragment order could cause mistakes

It resumes concise output after the warning or clarification is done. You don't need to manage this manually.

---

## crisp — benchmark results

Benchmarked using real Claude API output tokens across 3 runs per prompt, averaged.  
Baseline = plain Claude without crisp enabled.

### Average Reduction

| Model      | Output Tokens | Word Count |
| ---------- | ------------: | ---------: |
| Haiku 4.5  |    **29.07%** | **68.61%** |
| Sonnet 4.6 |    **70.26%** | **70.42%** |
| Opus 4.7   |    **61.37%** | **61.10%** |

### Highlights

- Up to **70% fewer output tokens**
- Up to **70% shorter responses**
- Works best on verbose reasoning-heavy answers
- Risky-operation prompts, such as `drop-table`, are intentionally less compressed

### Notes

- Output tokens measured from Claude API `.modelUsage[model].outputTokens`
- Input token usage is unchanged
- Benchmarks run on: `2026-05-20`
- Benchmark results depend on the model, prompt type, and baseline verbosity
- Benchmarks measure output length reduction only, not answer correctness
- Reproduce locally:

```bash
chmod +x run_benchmark.sh && ./run_benchmark.sh
```

---

> Built and tested following the [Agent Skills](https://agentskills.io/skill-creation/best-practices) specification.