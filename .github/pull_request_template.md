## What and why

<!-- Describe the user or engineering problem, and why this change is needed. -->

## Change type

- [ ] Feature
- [ ] Fix
- [ ] Documentation
- [ ] Refactor or maintenance

## Product and engineering scope

- [ ] Frontend
- [ ] Backend or data services
- [ ] Foundry / Microsoft Agent Framework (MAF)
- [ ] AI Gateway
- [ ] Terraform infrastructure
- [ ] CI/CD or repository configuration
- [ ] Other: <!-- specify -->

**Terraform roots affected:** <!-- frontend / backend / gateway / foundry / logging / registry / none -->

**Did this change update shared Terraform modules (`infra/modules/**`)?** Yes / No

If yes, list the module(s) and the roots that consume them:

## Implementation

<!-- Summarize the important changes. Note any API, data, or infrastructure contract changes. -->

## Validation and CI

**Checks run locally:** <!-- commands and results, or N/A with a reason -->

**Expected path-triggered CI for this PR** (check each workflow whose paths this PR changes):

- [ ] `frontend-ci.yml` — frontend and bridge image builds/checks, shared-module artifact, and frontend Terraform format/validation/plan.
- [ ] `backend-ci.yml` — backend image/dependency/startup checks, plus backend Terraform format/validation/plan and shared-module artifact.
- [ ] `gateway-ci.yml` — gateway Terraform format/validation/plan and shared-module artifact.
- [ ] `foundry-ci.yml` — Foundry Terraform format/validation/plan and shared-module artifact.
- [ ] `logging-ci.yml` — logging Terraform format/validation/plan and shared-module artifact.
- [ ] `registry-ci.yml` — registry Terraform format/validation/plan and shared-module artifact.
- [ ] None of the above; explain why: <!-- e.g. documentation-only change -->

**Why these workflows run:** CI is filtered by changed paths for pull requests targeting `main`. Changes under `infra/modules/**` match all six workflows above, so each root runs its Terraform checks; frontend and backend image checks run too. Root-specific changes match that root's workflow. Backend CI also matches `.github/workflows/backend-ci.yml`, `.github/workflows/reusable-backend-checks.yml`, `.github/workflows/reusable-terraform-*.yml`, and `.github/actions/**`. Documentation-only changes do not currently match these workflows unless another changed path does.

<!-- These are PR checks only; deployment workflows are not triggered by this template or by a pull request. -->

## Risk and rollout

- **Operational impact or rollout notes:** <!-- N/A if none -->
- **Data freshness, provenance, or unavailable states affected:** <!-- N/A if none -->
- **Security, permissions, secrets, or configuration impact:** <!-- N/A if none -->

## Reviewer checklist

- [ ] Scope and behavior are clear; unrelated product or architecture scope was not added.
- [ ] Relevant validation is complete, or remaining gaps are explained.
- [ ] No secrets, credentials, private endpoints, state, or user data were added.
