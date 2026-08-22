# Skill evals

Test data for developing the skills in `resources/payload/.agents/skills/`. It is repository-only: nothing under
`evals/` is part of the payload, and installing `ai-context` into a project never copies it.

There is no model runner here, and these cases have not been executed against a model. This directory is the corpus and
the schema. Provider-specific tools execute the cases, then the repository scores their results consistently.

## Layout

```text
evals/skills/{skill-name}/
├── triggers.json    # should this skill fire for this prompt?
├── behaviour.json   # given it fired, what must the output do?
└── fixtures/        # optional repository stand-ins a prompt refers to
```

Every skill has both JSON files. No skill needs a fixture today; the mechanism exists for a case that genuinely cannot
be stated in the prompt.

## What a case is allowed to say

A case describes a situation and asks for something. It does not describe the answer.

Naming the classes, files, columns, or variables the output should contain defeats the case twice over. It removes the
reasoning the case exists to test, and it bakes in one specific arrangement that may not be the right one. Write the
problem, and let the answer be reached.

```json
// Prescribes the answer, so the model recalls rather than reasons
{ "prompt": "Add a test for ReportExporter::rowLimit() covering the zero-row case" }
```

```json
// Describes the situation, so the coverage has to be worked out
{ "prompt": "The new row limit landed with only the happy path covered. Finish the job." }
```

The same applies to expectations. They state observable properties of a good answer, so they survive rewording and do
not pin the output to one implementation.

```json
// Asserts a snapshot
"expectations": ["Keeps bool $sendEmail = true as bool rather than ?bool"]
```

```json
// Asserts the property that matters
"expectations": ["Leaves every parameter's declared type exactly as given, including its nullability"]
```

## triggers.json

A flat array. Each entry is a realistic user prompt and whether this skill should be the one that fires.

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

| Field            | Required | Meaning                                                                 |
|------------------|----------|-------------------------------------------------------------------------|
| `query`          | yes      | The prompt, as a user would actually write it                           |
| `should_trigger` | yes      | Boolean. Whether this skill is the right one for that prompt            |
| `note`           | no       | Why a near-miss case falls the way it does, and where it routes instead |

Negative cases are the point. A skill's description is only as good as the prompts it correctly declines, so the
negatives are plausible confusion cases drawn from the boundaries that actually overlap: `write-code` against
`write-tests`, `write-pr` against `git-commit`, and `write-ticket` against `write-plan`.

## behaviour.json

An object naming the skill, holding the cases.

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

Case count follows behavioural risk rather than a fixed range. Small, narrow skills may need only a few cases. Broad
skills need enough cases to cover their distinct rules and boundaries without repeating the same outcome. Across a
skill, include the relevant normal cases, counterexamples, project precedence, proportionality, composition with
another skill, and regressions for known failure modes.

## Running them

There are two run tiers:

- **Fast regression:** run `./tests/evals.sh`, or `task test` for every deterministic repository check. This validates
  the corpus: both files present per skill, JSON that parses, required fields, non-empty expectations, fixture paths
  that exist, and skill names that match real skills. It also checks that every supporting path a skill mentions
  resolves and every Claude adapter points at a real canonical skill. It needs no model
- **Full evaluation:** execute every trigger and behaviour case against a model with an external runner. Repeat each
  case enough times to expose variance rather than treating one sampled response as a stable result

Executing the cases against a model is left to an external runner, so the corpus stays free of provider dependencies.
That runner consumes it like this:

- **Triggers.** Present `query` with the skill descriptions loaded, and check whether this skill fires against
  `should_trigger`. Report false-positive and false-negative rates separately, since an over-broad description and a
  missed valid invocation are different regressions
- **Behaviour.** Present `prompt` with the skill loaded, and with `fixture` as the working directory where one is
  given. Have an independent judge score each entry in `expectations` separately, so a case can partially pass and the
  failing expectation is named. Every expectation is mandatory: one failure fails the case rather than being averaged
  away by stronger results elsewhere

Record the model and provider, reasoning setting, runner version, skill content hash, case ID, repetition number, raw
response, and expectation-level verdicts for every sample. Reports should include per-expectation and per-case pass
rates across repeated runs, alongside trigger false-positive and false-negative rates. This makes comparisons
reproducible and shows whether a change improved capability or merely changed sampling luck.

Keep new cases in this shape rather than adding a runner-specific field. Anything a runner needs that the schema does
not carry belongs in the runner.

### Scoring external results

First export blind generator tasks. The export includes each task's canonical skill content and optional absolute
fixture path, but omits trigger labels, expectations, and expected-output hints:

```console
./scripts/prepare_evals.py --output tasks.json
./scripts/prepare_evals.py --category regression --output regression-tasks.json
```

Give these tasks to isolated generator agents. Keep the labelled corpus available only to the independent judge and
scorer so the generated responses cannot copy their answers from the eval definition.

The default selection is the full behaviour corpus. `--category regression` emits only behaviour cases declared as
regressions while retaining every trigger case, since false-positive and false-negative boundaries remain part of the
fast model gate. The export records this selection, and result files must carry it unchanged. The scorer applies the
same filter before enforcing completeness, so omitted full-suite behaviour cases are valid only when the declared
selection excludes them.

`scripts/score_evals.py` validates and scores complete result sets without invoking a model. Each run must cover every
trigger and behaviour case. Each behaviour expectation receives its own boolean verdict, and a case passes only when
all its expectations pass.

```console
./scripts/score_evals.py results.json
./scripts/score_evals.py results.json --format json
```

The input requires `model.name`, `model.provider`, `model.reasoning`, `runner.name`, `runner.version`, and the exact
SHA-256 hash of every canonical `SKILL.md`. It requires at least two uniquely identified runs so a report cannot imply
stability from one sample. Each run may carry arbitrary metadata such as a seed or timestamp.

Every trigger result records the original query, observed `triggered` verdict, raw response, and judge rationale. Every
behaviour result records the case ID, raw response, judge rationale, and an exact expectation-to-verdict mapping. Each
expectation verdict includes non-empty evidence, which may cite the response, tool use, or resulting state. The scorer
rejects stale skill hashes and missing, duplicate, or unknown cases and expectations. JSON output preserves all case
responses, rationales, expectation verdicts, and evidence.

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

The human report gives aggregate false-positive and false-negative trigger rates plus mandatory behaviour case and
expectation pass rates. JSON output preserves model and run metadata and includes per-run and aggregate metrics.
