# Moderation Philosophy (kkiriDating)

This document explains the moderation design principles used in kkiriDating.
It is a system design reference intended for internal alignment and external
review by stakeholders.

## Goals

- Protect users from harmful behavior while minimizing false positives.
- Preserve fairness by using consistent, explainable criteria.
- Enable human oversight without making moderation purely manual.
- Avoid punitive, irreversible actions unless clearly warranted.

## Why gradual moderation (levels 0 / 1 / 2)

Reports are imperfect signals. A single report can be honest or malicious, and
automated systems are not perfect. kkiriDating therefore uses a graduated
model:

- **Level 0**: Normal access.
- **Level 1**: Soft restrictions or delays to reduce potential harm while
  gathering more evidence.
- **Level 2**: Hard restrictions when the evidence suggests repeated or severe
  violations.

This approach reduces the risk of over‑moderation and creates space for
verification and appeal.

## Why reports accumulate instead of instant bans

Instant bans increase the risk of abuse (false or coordinated reports) and
reduce trust in the system. Accumulating reports allows:

- Better signal quality over time.
- More reliable escalation thresholds.
- Clearer justification when stronger restrictions are applied.

## Why protection exists but does not grant immunity

Protection can soften restrictions in limited cases, but it never overrides
critical safety constraints. It is intentionally constrained by:

- Eligibility checks.
- Hard‑flag exclusions for severe categories.
- Time limits and verification.

This preserves safety while allowing remediation pathways for borderline cases.

## Why admin intervention is limited and logged

Human admins are necessary for edge cases, but unrestricted manual control
creates inconsistency. kkiriDating:

- Restricts admin actions to narrow, auditable scopes.
- Logs admin actions for review and accountability.
- Keeps server‑authoritative enforcement as the default.

## How automated systems and human admins cooperate

- Automated rules enforce baseline safety and consistency.
- Admins handle exceptional or ambiguous cases.
- Both systems feed into the same moderation state to avoid conflicts.

This cooperation allows the product to scale responsibly without sacrificing
human judgement.

