---
brief: Where each versable-git repo deploys (staging/release branch, GCP project, triggers, previews), and how to set up previews
triggers:
  - topic:versable-envs
  - topic:deploy
  - topic:staging
  - phrase:"which branch deploys"
  - phrase:"staging env"
  - phrase:"preview env"
  - phrase:"pre-prod"
  - tool:versable-envs
related: [rules/git.md, memory/global/reference_repo_census.md]
tier: 1
category: features
updated: 2026-10-27
stale_after_days: 90
---

# Versable environments

Every versable-git repo already says where it deploys. Read it with one command
instead of asking the owner. This applies to versable-git repos only.

```
python3 ~/.claude/scripts/versable/envs.py             the repo you are in
python3 ~/.claude/scripts/versable/envs.py speedway    one repo by name
python3 ~/.claude/scripts/versable/envs.py --all       every repo it knows
add --live                                             Cloud Build triggers and preview IAM, from GCP
add --json                                             for scripts
```

At session start inside a versable-git clone, a one-line summary is injected
(`scripts/versable/envs-inject.sh`, mute with `touch ~/.claude/.no-versable-envs`).

## Where the answers come from

| Fact | Source | Notes |
|---|---|---|
| Staging and prod, previews, what is live | Clanky's infra catalog, `pr-board/playbooks/deploys.md` in slack-automation | The one maintained catalog (markdown tables, owner-reviewed). Rows marked *(inferred)* or *(unconfirmed)* are leads |
| Staging branch | `branches.dev` in `.github/pr-context.config.json` | Per-repo config read by slack-automation's `ci-kit/repo-config.cjs`. "dev" means the staging alias |
| Release branch | `branches.release` in the same file | Production |
| GCP project | `~/Code/Versable/vg/estate.toml`, then `~/.config/vg/local.toml` | The team estate is shared; add a missing repo to it by PR in `versable-git/vg` |
| Env docs | `docs/` and `deploy/` files named for environments or deploying | Read the repo's own ENVIRONMENTS.md first when there is one |
| Deploys | Cloud Build triggers (`--live`, or `vg triggers <project>`), then `.github/workflows` | Triggers are the truth for speedway and walmart-mvp; GitHub workflows deploy only some repos |
| Preview setup | `.github/workflows/preview.yml` env (`WIF_PROVIDER`, `DEPLOYER`) | `--live` checks that GitHub may act as the deployer |

## Known maps (read 2026-10-27; rerun the command, it is the source)

| Repo | Staging | Release | GCP project |
|---|---|---|---|
| speedway | `development`, speedway-dev, speedway.dev.versable.ai | `main`, speedway, speedway.versable.ai | speedway-versable |
| walmart-mvp | `main`, sandbox, walmart-sandbox.versableplatforms.com | `release`, prod, walmart.versableplatforms.com | walmart-496912 |
| enhancement-product | `development` | `release` | not in estate |

Feature PRs target the staging branch, never the release branch. Before
working on any PR, compare its base with this map and say so at once when they
differ. Speedway #119 was opened against `main`, which is production, on
2026-10-26.

## Why this is not a vg verb

vg's rule is that every verb is one gcloud command you could type yourself, and
it is a shared team tool. The env map mostly reads GitHub config, git and
Clanky's catalog, so it lives here and leans on vg where they overlap: vg's
`estate.toml` for the project, `vg triggers` for live deploy triggers. The one
gap that did belong in vg, triggers linked through a repository connection
showing no branch, is fixed in versable-git/vg#1 (2026-10-27).

To change the map itself, edit the source, not this script: Clanky's catalog
for environments, a repo's `pr-context.config.json` for branches, vg's
`estate.toml` (by PR) for projects.

## Preview grants

A repo's "Preview env" workflow signs into GCP as `preview-deployer@<project>`
through workload identity: the `github` pool in versable-forge-v6 holds one
provider per repo. The one-time setup is
`~/.claude/scripts/versable/preview-wif-setup.sh` (dry run by default, `--execute`
applies, safe to re-run). The per-repo copies in speedway and walmart-mvp
(`scripts/preview-github-setup.sh`) are the same script with fixed values.

The symptom of a missing grant is a 403 in the workflow's auth step:
`Permission 'iam.serviceAccounts.getAccessToken' denied`. That means the repo's
principal lacks `roles/iam.workloadIdentityUser` on the deployer.

Who can run it: the project-level grants need Project IAM Admin. The grants on
the service accounts need Service Account Admin or Owner. Editor alone fails
with `iam.serviceAccounts.setIamPolicy` denied. The owner's account can set
project IAM, so the fix is one self-grant, approved by the owner, then the
script:

```
gcloud projects add-iam-policy-binding <project> --member=user:<owner>@versable.ai \
  --role=roles/iam.serviceAccountAdmin --condition=None
```

After a grant, the first workflow run can still hit the 403 for a few minutes
while IAM propagates. Rerun the failed job before suspecting the binding, and
compare with a working repo (`gcloud iam service-accounts get-iam-policy`).

In zsh, quote any gcloud flag that holds brackets (`"--flatten=bindings[].members"`);
unquoted it fails with `no matches found`.

| Repo | Provider | Deployer bound |
|---|---|---|
| speedway | speedway | yes, 2026-10-27 (owner self-granted Service Account Admin on speedway-versable) |
| walmart-mvp | walmart | yes (preview job passes) |
| versable-builder | versable-builder | not checked |
