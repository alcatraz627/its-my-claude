#!/usr/bin/env bash
#
# One-time GCP setup that lets a versable-git repo's "Preview env" GitHub
# workflow deploy previews with no key and no person's gcloud login. Any repo,
# same steps: the per-repo copies (speedway, walmart-mvp) differ only in values.
#
# GitHub proves which repo a run belongs to with an OIDC token. The "github"
# workload identity pool in versable-forge-v6 trusts those tokens, one provider
# per repo. This makes sure the repo has a provider, creates a preview-deployer
# account in the app's project, and lets runs from that repo alone act as it.
#
#   preview-wif-setup.sh --repo speedway --project speedway-versable \
#     --runtime-sa speedway-run@speedway-versable.iam.gserviceaccount.com \
#     --build-sa 234224641858-compute@developer.gserviceaccount.com \
#     --prefix speedway-pv- [--provider speedway] [--execute]
#
# Dry run by default (prints every command); --execute applies them, and is safe
# to re-run. The build account is what Cloud Build runs as in that project:
#   gcloud builds list --project <project> --limit 1 --format="value(serviceAccount)"
#
# Who can run it: project-level grants need Project IAM Admin, and the grants on
# the service accounts themselves need Service Account Admin (or Owner) on the
# project. Editor is not enough for the second half; see
# ~/.claude/features/versable-envs.md, "Preview grants".
set -euo pipefail

REPO="" PROJECT="" RUNTIME_SA="" BUILD_SA="" SERVICE_PREFIX="" PROVIDER="" EXECUTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2#versable-git/}"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --runtime-sa) RUNTIME_SA="$2"; shift 2 ;;
    --build-sa) BUILD_SA="$2"; shift 2 ;;
    --prefix) SERVICE_PREFIX="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --execute) EXECUTE=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1 (see --help)" >&2; exit 2 ;;
  esac
done
for v in REPO PROJECT RUNTIME_SA BUILD_SA SERVICE_PREFIX; do
  [ -n "${!v}" ] || { echo "missing --$(echo "$v" | tr 'A-Z_' 'a-z-') (see --help)" >&2; exit 2; }
done
PROVIDER="${PROVIDER:-$REPO}"

POOL_PROJECT="versable-forge-v6"
POOL_PROJECT_NUMBER="575485603284"
POOL="github"
FULL_REPO="versable-git/${REPO}"
DEPLOYER="preview-deployer@${PROJECT}.iam.gserviceaccount.com"
PRINCIPAL="principalSet://iam.googleapis.com/projects/${POOL_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${FULL_REPO}"

run() { printf '+ %s\n' "$*"; if [ -n "$EXECUTE" ]; then "$@"; fi; }

# A provider per repo, accepting tokens from that repo alone.
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER" \
     --workload-identity-pool "$POOL" --location global --project "$POOL_PROJECT" >/dev/null 2>&1; then
  run gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --workload-identity-pool "$POOL" --location global --project "$POOL_PROJECT" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition "assertion.repository=='${FULL_REPO}'"
fi

if ! gcloud iam service-accounts describe "$DEPLOYER" --project "$PROJECT" >/dev/null 2>&1; then
  run gcloud iam service-accounts create "${DEPLOYER%%@*}" --project "$PROJECT" \
    --display-name "Preview deployer: GitHub workflow for ${FULL_REPO}"
fi

# Build the image, create and delete preview services, run them as the app's
# runtime account, and read the project.
for role in roles/cloudbuild.builds.editor roles/viewer roles/serviceusage.serviceUsageConsumer; do
  run gcloud projects add-iam-policy-binding "$PROJECT" --condition None --quiet --format none \
    --member "serviceAccount:${DEPLOYER}" --role "$role"
done
# Cloud Run admin on preview services only. The second clause covers checks made
# on the region rather than a service, such as creating one; creating cannot
# overwrite a service that already exists.
run gcloud projects add-iam-policy-binding "$PROJECT" --quiet --format none \
  --member "serviceAccount:${DEPLOYER}" --role roles/run.admin \
  --condition "expression=resource.name.extract('/services/{name}').startsWith('${SERVICE_PREFIX}') || resource.name.extract('/services/{name}') == '',title=preview-services-only"
run gcloud storage buckets add-iam-policy-binding "gs://${PROJECT}_cloudbuild" \
  --member "serviceAccount:${DEPLOYER}" --role roles/storage.admin --format none

# From here on the grants sit on service accounts, which needs Service Account Admin.
for sa in $(printf '%s\n' "$RUNTIME_SA" "$BUILD_SA" | sort -u); do
  run gcloud iam service-accounts add-iam-policy-binding "$sa" --project "$PROJECT" \
    --member "serviceAccount:${DEPLOYER}" --role roles/iam.serviceAccountUser --format none
done
# Runs from this repo may act as the deployer. Nothing else may.
run gcloud iam service-accounts add-iam-policy-binding "$DEPLOYER" --project "$PROJECT" \
  --member "$PRINCIPAL" --role roles/iam.workloadIdentityUser --format none

echo ""
echo "workflow env for .github/workflows/preview.yml:"
echo "  WIF_PROVIDER: projects/${POOL_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}"
echo "  DEPLOYER: ${DEPLOYER}"
echo "check: python3 ~/.claude/scripts/versable/envs.py ${REPO} --live"
