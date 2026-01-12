# CI/CD Smoke Test (ECS EC2 + SSM Run Command)

This runbook defines the single source of truth for post-deploy smoke checks
from inside the VPC using SSM Run Command. It is safe for manual use and CI
on macOS (zsh) and Linux.

## Prerequisites checklist

- AWS CLI v2 installed and on PATH.
- jq installed (optional, recommended for JSON extraction; fallback commands are provided).
- IAM permissions for the caller:
  - ecs:Describe*, ecs:List*
  - ssm:SendCommand, ssm:GetCommandInvocation, ssm:ListCommandInvocations
  - ec2:DescribeInstances
  - elbv2:DescribeLoadBalancers (if using ALB)
- Target EC2 instance:
  - SSM agent installed and running.
  - Instance profile with AmazonSSMManagedInstanceCore (or equivalent).
  - Network access to ECS services (same VPC/security groups).
- curl installed on the target EC2 instance.

## Optional local config file (non-secret)

Create a local defaults file and keep it out of git:

```bash
cp scripts/cicd/cicd.env.example scripts/cicd/cicd.env
```

All scripts in `scripts/cicd/` will source `scripts/cicd/cicd.env` if present.

## GitHub CI/CD Variables & Secrets Contract

Repository variables:

- AWS_REGION (optional, default: eu-central-1)
- ECS_CLUSTER (optional, default: LIBRARY-ECS-CLUSTER)
- ECS_SERVICE_COMMAND (required)
- ECS_SERVICE_QUERY (required)
- ECR_REPO_COMMAND (required)
- ECR_REPO_QUERY (required)
- ENABLE_LATEST_TAG (optional, default: false)

Repository secrets:

- AWS_ROLE_TO_ASSUME (required, IAM role ARN trusted by GitHub OIDC)

## Docker build notes (CI/CD)

- Dockerfiles live in:
  - `loan-command-service/Dockerfile`
  - `loan-query-service/Dockerfile`
- CI/CD builds images from each service module directory after `mvn -DskipTests package`,
  using `target/*.jar` as the runtime artifact and exposing port 8080.

## Pre-flight checklist before first deploy.yml run

### Pre-flight: Configure GitHub Variables & Secrets for deploy.yml

1) Open GitHub and go to your repository.
Expected result: you are on the repo homepage.

2) Click **Settings**.
Expected result: repository settings page is open.

3) In the left sidebar, click **Secrets and variables** → **Actions**.
Expected result: you see two tabs: **Secrets** and **Variables**.

4) In **Secrets**, click **New repository secret**.
Expected result: secret creation form is visible.

5) Create secret `AWS_ROLE_TO_ASSUME`.
Expected result: secret appears in the list.
If this fails: ensure the name is exactly `AWS_ROLE_TO_ASSUME` (all caps).
Common mistakes: using access key/secret key instead of an IAM role ARN.
Example format (not real): `arn:aws:iam::123456789012:role/github-oidc-deploy`.
Important: do not store long-lived AWS keys in GitHub Secrets. Use OIDC only.

6) Switch to **Variables** tab and click **New repository variable**.
Expected result: variable creation form is visible.

7) Create required variables:
- `ECS_SERVICE_COMMAND` (ECS service name for the command service).
- `ECS_SERVICE_QUERY` (ECS service name for the query service).
- `ECR_REPO_COMMAND` (ECR repository name for the command image).
- `ECR_REPO_QUERY` (ECR repository name for the query image).
Expected result: all four variables appear in the list.
Common mistakes: typos in service names, mixing service name and task definition family.
Example format (not real): `loan-command-service`, `loan-query-service`,
`library/loan-command-service`, `library/loan-query-service`.

8) Create optional variables if needed:
- `AWS_REGION` (default is `eu-central-1`).
- `ECS_CLUSTER` (default is `LIBRARY-ECS-CLUSTER`).
- `ENABLE_LATEST_TAG` (set to `true` only if you want the `latest` tag).
Expected result: optional variables appear if you added them.
Common mistakes: setting `ENABLE_LATEST_TAG` to `True` or `TRUE` (must be `true`).

Validation quick check (GitHub Actions logs):
1) Go to **Actions** → **Deploy** workflow → latest run.
Expected result: the `Validate config` step is green.
If this fails: the logs show which variable/secret is missing.

### Pre-flight: Validate ECS task definitions templates

1) Verify task definition templates exist (run from repo root).
Expected result: you see both files listed.

```bash
ls -l ecs/taskdef-loan-command.json ecs/taskdef-loan-query.json
```

2) Verify container names match deploy.yml (jq version).
Expected result: output is `loan-command` and `loan-query` on separate lines.
If this fails: update the JSON or deploy.yml so names match exactly.

```bash
jq -r '.containerDefinitions[].name' ecs/taskdef-loan-command.json
jq -r '.containerDefinitions[].name' ecs/taskdef-loan-query.json
```

3) Verify container names match deploy.yml (no-jq fallback).
Expected result: you see `loan-command` and `loan-query` in the output.
If this fails: update the JSON or deploy.yml so names match exactly.

```bash
rg -n '"name":' ecs/taskdef-loan-command.json ecs/taskdef-loan-query.json
```

What happens if container-name mismatches:
- `amazon-ecs-render-task-definition` fails with an error like
  "Container name 'loan-command' not found in task definition".

### Pre-flight: Verify ECS roles can pull from ECR and write logs

Why this matters:
- Task execution role pulls images from ECR and writes logs to CloudWatch.
- EC2 instance role (container instance) may need ECR read permissions in EC2 mode.

1) Identify the current task execution role from ECS (if a task definition exists).
Expected result: you see an execution role ARN or `None`.
If `None`: add `executionRoleArn` to the task definition template before first deploy.

```bash
# Show the execution role ARN for an existing task definition (if registered)
aws ecs describe-task-definition --task-definition loan-command-service --region "$REGION" --query "taskDefinition.executionRoleArn" --output text
```

2) Verify the execution role has ECR pull and CloudWatch logs permissions.
Expected result: you see policies like `AmazonECSTaskExecutionRolePolicy`.
If this fails: attach the policy or an equivalent custom policy to the role.

```bash
# List policies attached to the execution role (replace ROLE_NAME)
aws iam list-attached-role-policies --role-name "<ROLE_NAME>" --output table
```

3) Identify the EC2 container instance role (if you are using EC2 launch type).
Expected result: you see an instance profile ARN and role name.
If this fails: ensure the container instance is registered and ECS agent is healthy.

```bash
# List container instances for the cluster
aws ecs list-container-instances --cluster "$CLUSTER" --region "$REGION" --output text
# Resolve EC2 instance ID for the first container instance
aws ecs describe-container-instances --cluster "$CLUSTER" --container-instances $(aws ecs list-container-instances --cluster "$CLUSTER" --region "$REGION" --query "containerInstanceArns[0]" --output text) --region "$REGION" --query "containerInstances[0].ec2InstanceId" --output text
# Show the instance profile ARN on the EC2 instance (replace INSTANCE_ID)
aws ec2 describe-instances --instance-ids "<INSTANCE_ID>" --region "$REGION" --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text
# Show the role name from the instance profile (replace INSTANCE_PROFILE_NAME)
aws iam get-instance-profile --instance-profile-name "<INSTANCE_PROFILE_NAME>" --query "InstanceProfile.Roles[].RoleName" --output text
```

4) Verify the EC2 instance role can read from ECR (if needed).
Expected result: policies include ECR read or ECS instance role policy.
If this fails: attach ECR read permissions to the instance role.

```bash
# List policies attached to the EC2 instance role (replace ROLE_NAME)
aws iam list-attached-role-policies --role-name "<ROLE_NAME>" --output table
```

If tasks start and immediately stop (troubleshooting):
1) Check stopped task reasons.
Expected result: you see `stoppedReason` and container `reason`.

```bash
# Show STOPPED task ARNs for the service
aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status STOPPED --region "$REGION" --max-items 5 --output text
# Describe STOPPED tasks to see stop reasons
aws ecs describe-tasks --cluster "$CLUSTER" --tasks $(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status STOPPED --region "$REGION" --max-items 5 --query "taskArns[]" --output text) --region "$REGION" --output table
```

Common errors and how to interpret them:
- `CannotPullContainerError`: ECR permissions missing or repository name typo.
- `AccessDenied` for logs: missing CloudWatch Logs permissions in execution role.
- `ResourceInitializationError`: missing VPC endpoints, DNS, or security group rules.

### First deploy: manual run (workflow_dispatch) + what to watch

1) Open GitHub → **Actions** → **Deploy** workflow.
Expected result: you see the Deploy workflow page.

2) Click **Run workflow** and choose the branch.
Expected result: a new workflow run appears at the top of the list.

3) Open the run and expand steps in order:
Expected result: each step shows green checkmarks.
If this fails: use the step logs to locate the failing stage.

4) Confirm these steps succeeded:
- `Validate config`
- `Build artifacts (skip tests)`
- `Build and push loan-command-service image`
- `Build and push loan-query-service image`
- `Render task definition (loan-command-service)`
- `Render task definition (loan-query-service)`
- `Deploy loan-command-service`
- `Deploy loan-query-service`
Expected result: the job ends with a green checkmark.

5) Confirm ECS stability from the deploy job logs.
Expected result: deploy steps report service stability.
If this fails: re-check IAM permissions and task definition container names.

Note: no public endpoints are required; all smoke checks must remain VPC-internal.

## Environment variables

```bash
export CLUSTER="LIBRARY-ECS-CLUSTER"
export SERVICES="loan-command-service loan-query-service"
export SERVICE="loan-command-service" # used by scripts for single-service ops
export REGION="eu-central-1"
export INSTANCE_ID="i-0123456789abcdef0"
export ALB_DNS="" # optional, internal ALB DNS if it exists
```

## Verify AWS auth and region

```bash
# Confirm AWS identity for the current credentials
aws sts get-caller-identity
# Show AWS CLI config sources and active values
aws configure list
# Show the active AWS region
aws configure get region
```

## Verify ECS cluster/service/task state

```bash
# Show ECS cluster status and registered instances
aws ecs describe-clusters --clusters "$CLUSTER" --region "$REGION" --output table
# Show ECS service deployment and desired/running counts
aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" --output table
# List RUNNING task ARNs for the service
aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status RUNNING --region "$REGION" --output text
# Describe the first RUNNING task (details + networking)
aws ecs describe-tasks --cluster "$CLUSTER" --tasks $(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status RUNNING --region "$REGION" --query "taskArns[0]" --output text) --region "$REGION" --output table
```

## Wait for ECS service stability

```bash
scripts/cicd/ecs_wait_stable.sh
```

For multiple services:

```bash
for svc in $SERVICES; do
  SERVICE="$svc" scripts/cicd/ecs_wait_stable.sh
done
```

## Discover target URL(s) for smoke

### A) Internal ALB exists (preferred)

```bash
export ALB_NAME="internal-library-alb"
# Resolve internal ALB DNS name
export ALB_DNS=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query "LoadBalancers[0].DNSName" --output text --region "$REGION")
export SMOKE_URLS="http://$ALB_DNS/actuator/health"
```

If you use path-based routing, define one URL per service:

```bash
export SMOKE_URLS="http://$ALB_DNS/loan-command/actuator/health http://$ALB_DNS/loan-query/actuator/health"
```

### B) No ALB yet (private IP + port discovery)

You need the task private IP (awsvpc) or the EC2 private IP + host port (bridge/host).

1) Identify a running task:

```bash
# Get a RUNNING task ARN for the service
export TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status RUNNING --region "$REGION" --query "taskArns[0]" --output text)
```

2) Get task definition and network mode:

```bash
# Resolve task definition ARN from the task
export TASK_DEF_ARN=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --region "$REGION" --query "tasks[0].taskDefinitionArn" --output text)
# Show ECS task network mode (awsvpc/bridge/host)
aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --region "$REGION" --query "taskDefinition.networkMode" --output text
```

3a) awsvpc mode: use task private IP + container port

```bash
# Get task private IP from task attachments
export TASK_IP=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --region "$REGION" --query "tasks[0].attachments[0].details[?name=='privateIPv4Address'].value|[0]" --output text)
# Get container port from task definition
export CONTAINER_PORT=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --region "$REGION" --query "taskDefinition.containerDefinitions[0].portMappings[0].containerPort" --output text)
export SMOKE_URLS="http://$TASK_IP:$CONTAINER_PORT/actuator/health"
```

3b) bridge/host mode: use EC2 private IP + host port mapping

```bash
# Get host port mapping from the task
export HOST_PORT=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --region "$REGION" --query "tasks[0].containers[0].networkBindings[0].hostPort" --output text)
# Get container instance ARN hosting the task
export CONTAINER_INSTANCE_ARN=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --region "$REGION" --query "tasks[0].containerInstanceArn" --output text)
# Resolve EC2 instance ID for the container instance
export EC2_INSTANCE_ID=$(aws ecs describe-container-instances --cluster "$CLUSTER" --container-instances "$CONTAINER_INSTANCE_ARN" --region "$REGION" --query "containerInstances[0].ec2InstanceId" --output text)
# Resolve EC2 private IP of the container instance
export TASK_HOST_IP=$(aws ec2 describe-instances --instance-ids "$EC2_INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
export SMOKE_URLS="http://$TASK_HOST_IP:$HOST_PORT/actuator/health"
```

## Happy path smoke sequence

```bash
# Confirm AWS identity for the current credentials
aws sts get-caller-identity
# Show the active AWS region
aws configure get region

for svc in $SERVICES; do
  SERVICE="$svc" scripts/cicd/ecs_wait_stable.sh
done

scripts/cicd/ssm_smoke_curl.sh "$INSTANCE_ID" "$REGION" $SMOKE_URLS
```

## Debug path (when smoke fails)

```bash
scripts/cicd/ecs_debug_dump.sh

# Show recent ECS service events
aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" --query "services[0].events[0:10].[createdAt,message]" --output table

# Show STOPPED tasks and their stop reasons
aws ecs describe-tasks --cluster "$CLUSTER" --tasks $(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status STOPPED --region "$REGION" --max-items 5 --query "taskArns[]" --output text) --region "$REGION" --output table
```

CloudWatch Logs hints (if configured in task definitions):

```bash
# List ECS log groups (if CloudWatch Logs is configured)
aws logs describe-log-groups --log-group-name-prefix "/ecs/" --region "$REGION" --output table
```

## How to manually trigger deploy (workflow_dispatch)

1) In GitHub, open Actions and select the Deploy workflow.
2) Click "Run workflow" and choose the branch.
3) Observe the Deploy job logs for image builds and ECS updates.

## Expected outputs / pass-fail criteria

- Pass:
  - All `ecs_wait_stable.sh` calls report stable.
  - `ssm_smoke_curl.sh` returns Status=Success.
  - curl output includes HTTP 200 and health body showing `"status":"UP"` (or equivalent).
- Fail:
  - SSM command Status is not Success.
  - curl returns non-2xx or times out.
  - ECS service never reaches stability within timeout.

---



# GitHub Actions CI — PAT configuration, bootstrap test, troubleshooting

> This document is intended to be pasted into `docs/runbooks/CI_CD_SMOKE_TEST.md` as the “GitHub Actions CI bootstrap” section.

---

## 1) GitHub configuration: Personal Access Token (PAT) for creating/updating workflows

**Goal:** be able to create and update workflow files under `.github/workflows/*.yml` and push them to the repository.

### Option A — Classic PAT (simple)
1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token**
2. Recommended scopes:
   - `repo` (required for push/PR in private repositories)
   - `workflow` (required to create/update workflow files)
3. Store the token securely (password manager).

### Option B — Fine-grained PAT (preferred for least privilege)
1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens**
2. Restrict:
   - **Repository access**: only this repository
3. Minimum permissions:
   - **Contents**: Read and write
   - **Workflows**: Read and write
   - **Metadata**: Read (usually enabled by default)
   - (Optional) **Pull requests**: Read and write (if you manage PRs via CLI)

### Using PAT locally on macOS
- Via **GitHub CLI** (recommended):
  - `gh auth login` → choose “Paste an authentication token”
- Or via HTTPS `git push`:
  - GitHub will prompt for username + token as the password.
  - Если нужно  сбросить сохранённые креды и сделать push заново:
	
```sh
# 1.	Убедись, что remote на HTTPS:
git remote -v

# 2.	Сбрось сохранённые креды (универсально):
git credential reject <<EOF
protocol=https
host=github.com
EOF

# 3.	Сделай push — Git снова спросит логин/пароль:
git push

``` 

### Common reasons it fails
- **Branch protection** blocks direct pushes to `main` → use PR instead.
- PAT lacks **Workflows: write** (fine-grained) or missing `workflow` scope (classic).
- Token is not granted access to the target repository (fine-grained repo selection).

---

## 2) Bootstrap test: verify GitHub access + CI pipeline

**Goal:** confirm (a) repo access works, (b) CI workflow triggers and runs successfully.

### Option A — PR-based (most realistic)
1. Create a test branch:
   - `git checkout -b test/ci-bootstrap`
2. Make a harmless change:
   - `echo "ci bootstrap $(date)" > .ci_bootstrap`
   - `git add .ci_bootstrap && git commit -m "ci: bootstrap test"`
3. Push the branch:
   - `git push -u origin test/ci-bootstrap`
4. Open a PR on GitHub and verify the **CI** workflow starts automatically.
5. **PASS criteria:**
   - PR → **Checks** shows the CI job green (success, `mvn -U test`).

### Option B — GitHub CLI checks (token + runs)
> Requires GitHub CLI (`gh`) installed.

1. Authenticate using the token:
   - `gh auth login`
2. Verify repository access:
   - `gh repo view --web` (opens the repo in browser)
3. List workflows:
   - `gh workflow list`
4. If your CI workflow supports manual runs (`workflow_dispatch`), trigger it:
   - `gh workflow run ci.yml`
   - `gh run list --limit 5`
5. **PASS criteria:**
   - A run appears, logs are available, and status is `success`.

---

## 3) Troubleshooting: CI workflow does not trigger or fails

### CI doesn’t trigger at all
1. **Wrong trigger conditions**
   - Check `.github/workflows/ci.yml` has:
     - `on: pull_request:` and/or `on: push:`
   - Ensure there are no unexpected `paths:` filters blocking runs.

2. **Workflow file not on default branch**
   - GitHub runs workflows from the branch that contains the workflow file.
   - For PR checks, ensure the PR branch includes `.github/workflows/ci.yml`.

3. **Branch protection / permissions**
   - If direct push to `main` is blocked, pushes to feature branches should still trigger.
   - If you’re pushing to a fork, verify Actions are enabled for that fork.

4. **Repository settings**
   - GitHub → Repo → **Settings** → **Actions**
     - Ensure Actions are enabled.
     - Ensure the selected permissions allow workflow runs.

### CI starts but fails
1. **Java version mismatch**
   - Confirm `actions/setup-java` uses the project’s supported Java version.
   - Check logs for `UnsupportedClassVersionError` or toolchain errors.

2. **Maven cache issues**
   - If dependency resolution behaves strangely, re-run without cache or adjust caching strategy.

3. **Tests flaky or environment-dependent**
   - Identify tests requiring external services.
   - Convert them to integration tests behind a profile, or mock where appropriate.

### Quick “sanity” checks (local)
- Verify you can run the same command locally from repo root:
  - `mvn -U test`

### Where to look in GitHub
- PR → **Checks** (best for PR-triggered runs)
- GitHub → Repo → **Actions** → open the latest run → inspect job logs

---
