---
name: security-review
description: Performs security review and threat modeling from assets to attack paths. Use for authentication, authorization, secrets, data protection, external input, webhooks, permissions, or security-focused code review.
---

# Security Review

Use this workflow to reason from assets and trust boundaries to concrete attack paths.

## Process

1. Identify sensitive assets, privileged operations, and user-controlled inputs.
2. Map trust boundaries and authorization checks.
3. Trace data from source to sink.
4. Check validation, output encoding, storage, transport, logging, and deletion behavior.
5. Consider abuse cases, replay, rate limits, escalation, and confused-deputy flows.
6. Calibrate severity based on exploitability and impact.
7. Recommend a concrete mitigation and verification path.

## Default Security Rules

- Never expose or log secrets, credentials, private keys, or tokens.
- Check relevant project docs for project-specific auth, privacy, and deployment assumptions.
- Validate all external input at boundaries.
- Escape or encode output for the destination context.
- Use least privilege for accounts, tokens, jobs, and service access.
- Verify authorization on every state-changing or sensitive read operation.
- Treat webhooks, callbacks, and background payloads as untrusted.
- Prefer idempotent handlers for retryable external events.
- For state-changing actions, verify the non-owner or lower-privilege path, not only the happy owner/admin path.
- For markdown, rich text, uploaded documents, or rendered HTML, review the sanitizer and renderer configuration plus regression coverage.
- For auth refresh, callbacks, and transient API failures, distinguish real unauthenticated responses from temporary startup or network errors before clearing state.

## Finding Format

```markdown
### [Severity] Finding title

Risk: [What can happen]
Attack path: [How it can be triggered]
Evidence: [Relevant behavior or code reference]
Fix: [Concrete mitigation]
Residual risk: [Anything left after the fix]
```
