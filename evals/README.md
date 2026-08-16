# Skill evals

Test data for developing the skills in `resources/payload/.agents/skills/`. It is repository-only: nothing under
`evals/` is part of the payload, and installing `ai-context` into a project never copies it.

There is no model runner here, and these cases have not been executed against a model. This directory is the corpus and
the schema; running it is a separate concern, described under [Running them](#running-them).

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
    "note": "Establishing what is true, before anything can be sequenced. Routes to orchestrate-investigation."
  }
]
```

| Field            | Required | Meaning                                                      |
|------------------|----------|--------------------------------------------------------------|
| `query`          | yes      | The prompt, as a user would actually write it                |
| `should_trigger` | yes      | Boolean. Whether this skill is the right one for that prompt |
| `note`           | no       | Why a near-miss case falls the way it does, and where it routes instead |

Negative cases are the point. A skill's description is only as good as the prompts it correctly declines, so the
negatives are plausible confusion cases drawn from the boundaries that actually overlap: `write-code` against
`write-tests`, `write-plan` against `orchestrate-investigation`, `write-pr` against `git-commit`, and `write-ticket`
against `write-plan`.

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

Each skill covers roughly six to ten cases, spanning the normal case, a counterexample, project precedence,
proportionality, composition with another skill, and a regression for a known failure mode.

## Running them

`./tests/evals.sh` validates the corpus: both files present per skill, JSON that parses, required fields, non-empty
expectations, fixture paths that exist, and skill names that match real skills. It also checks the skills the corpus is
written against, that every supporting path a skill mentions resolves and every Claude adapter points at a real
canonical skill. It is deterministic and needs no model. `task test` runs it alongside the installer and CLI suites.

Executing the cases against a model is left to a runner that does not live here, so the corpus stays free of any
provider dependency. A runner consumes it like this:

- **Triggers.** Present `query` with the skill descriptions loaded, and check whether this skill fires against
  `should_trigger`. The useful metric is the false-positive rate on the negatives, since that is what an over-broad
  description costs.
- **Behaviour.** Present `prompt` with the skill loaded, and with `fixture` as the working directory where one is
  given. Judge the response against each entry in `expectations` independently, so a case can partially pass and the
  failing expectation is named.

Keep new cases in this shape rather than adding a runner-specific field. Anything a runner needs that the schema does
not carry belongs in the runner.
