# Skill evals

Test data for the skills in `resources/payload/.agents/skills/`. Repository-only: nothing under `evals/` is installed.

There is no model runner here. This directory holds the corpus and the schema; external tools run the cases, and the repository scores their results.

## Layout

```text
evals/skills/{skill-name}/
├── triggers.json    # should this skill fire for this prompt?
├── behaviour.json   # given it fired, what must the output do?
└── fixtures/        # optional repository stand-ins a prompt refers to
```

Every skill has both JSON files. Add a fixture for a case the prompt cannot state.

## Writing a case

A case describes a situation and asks for something. It does not describe the answer. Naming the classes, files or columns the output should contain removes the reasoning the case tests.

```json
// Prescribes the answer, so the model recalls rather than reasons
{ "prompt": "Add a test for ReportExporter::rowLimit() covering the zero-row case" }
```

```json
// Describes the situation, so the coverage has to be worked out
{ "prompt": "The new row limit landed with only the happy path covered. Finish the job." }
```

Expectations state observable properties of a good answer, not one implementation.

```json
// Asserts a snapshot
"expectations": ["Keeps bool $sendEmail = true as bool rather than ?bool"]
```

```json
// Asserts the property that matters
"expectations": ["Leaves every parameter's declared type exactly as given, including its nullability"]
```

## triggers.json

A flat array of realistic user prompts and whether this skill should fire.

```json
[
  {
    "query": "Plan how we replace the search backend without breaking the existing filters",
    "should_trigger": true
  },
  {
    "query": "Find out why the queued jobs are running out of order",
    "should_trigger": false,
    "note": "Establishing what is true, before anything can be sequenced. Not a planning request."
  }
]
```

| Field            | Required | Meaning                                                      |
|------------------|----------|--------------------------------------------------------------|
| `query`          | yes      | The prompt, as a user would write it                         |
| `should_trigger` | yes      | Boolean: whether this skill is right for the prompt          |
| `note`           | no       | Why a near-miss falls the way it does, and where it routes   |

Make negative cases plausible confusions between neighbouring skills, such as `write-code` and `write-tests`, `write-pr` and `git-commit`, `write-ticket` and `write-plan`.

## behaviour.json

```json
{
  "skill_name": "write-code",
  "evals": [
    {
      "id": "follows-project-architecture-over-reference",
      "category": "project-precedence",
      "prompt": "This project keeps each piece of business logic in its own single-purpose class, called directly from the controller. There is no service layer and no repository layer. Add the ability to reopen a closed record.",
      "expected_output": "The new logic in the same kind of class the project already uses.",
      "expectations": [
        "Places the new logic in the same kind of class as the nearest equivalent capability",
        "Introduces no architectural layer the project does not already have"
      ]
    }
  ]
}
```

| Field             | Required | Meaning                                                            |
|-------------------|----------|--------------------------------------------------------------------|
| `id`              | yes      | Unique within the file, kebab-case                                 |
| `prompt`          | yes      | The situation and the ask                                          |
| `expectations`    | yes      | Non-empty list of observable properties the output must have       |
| `expected_output` | no       | One line describing the shape of a good answer                     |
| `category`        | no       | `normal`, `counterexample`, `project-precedence`, `proportionality`, `composition`, or `regression` |
| `fixture`         | no       | Path relative to the skill's eval directory. Must exist            |

Cover each skill's distinct rules and boundaries without repeating an outcome.

## Running them

- **Fast regression:** `./tests/evals.sh`, or `task test` for every deterministic check. It validates the corpus, skill paths and Claude adapters. No model needed
- **Full evaluation:** an external runner executes every case against a model, repeating each enough to expose variance

The runner treats the corpus like this:

- **Triggers.** Present `query` with the skill descriptions loaded, and compare whether this skill fires with `should_trigger`. Report false positives and false negatives separately
- **Behaviour.** Present `prompt` with the skill loaded, and `fixture` as the working directory when given. An independent judge scores each expectation separately. Every expectation is mandatory: one failure fails the case

Record the model and provider, reasoning setting, runner version, skill content hash, case ID, repetition number, raw response, and expectation-level verdicts for every sample.

### Scoring external results

Export blind generator tasks. They carry the skill content and optional fixture path, and omit labels, expectations and hints:

```console
./scripts/prepare_evals.py --output tasks.json
./scripts/prepare_evals.py --category regression --output regression-tasks.json
```

Give the tasks to isolated generator agents. Only the judge and scorer see the labelled corpus. `--category regression` emits only regression behaviour cases and keeps every trigger case; result files carry the selection unchanged.

`scripts/score_evals.py` scores complete result sets without a model:

```console
./scripts/score_evals.py results.json
./scripts/score_evals.py results.json --format json
```

The input needs `model.name`, `model.provider`, `model.reasoning`, `runner.name`, `runner.version`, the SHA-256 hash of every canonical `SKILL.md`, and at least two uniquely identified runs. Each run covers every trigger and behaviour case. Each trigger result records the query, `triggered` verdict, raw response and rationale. Each behaviour result records the case ID, raw response, rationale, and a verdict per expectation with non-empty evidence.

```json
{
  "schema_version": 1,
  "selection": {"behaviour_category": "regression"},
  "model": {"name": "model-name", "provider": "provider-name", "reasoning": "high"},
  "runner": {"name": "runner-name", "version": "1.0.0"},
  "skill_hashes": {"write-code": "<canonical SKILL.md SHA-256>"},
  "runs": [
    {
      "id": "run-1",
      "metadata": {"seed": 1},
      "triggers": [{"skill": "write-code", "cases": [{"query": "...", "triggered": true, "response": "...", "rationale": "..."}]}],
      "behaviour": [{"skill": "write-code", "cases": [{"id": "case-id", "response": "...", "rationale": "...", "expectations": [{"expectation": "...", "passed": true, "evidence": "..."}]}]}]
    },
    {"id": "run-2", "metadata": {}, "triggers": ["..."], "behaviour": ["..."]}
  ]
}
```

The report gives trigger false-positive and false-negative rates plus behaviour case and expectation pass rates. JSON output adds metadata, per-run metrics, and all responses and verdicts.
