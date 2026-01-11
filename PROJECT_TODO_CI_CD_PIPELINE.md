# TODO: CI/CD Pipeline (GitHub Actions → AWS ECS on EC2)

This checklist implements the agreed CI/CD concept:

- **SCM**: GitHub  
- **CI**: GitHub Actions on PR/push (`mvn -U test`)  
- **CD**: GitHub Actions builds Docker images, pushes to **ECR**, updates **ECS Task Definitions** and **ECS Services**  
- **Smoke**: Runs **inside VPC** (preferred: **SSM Run Command** on an EC2 instance; alternative: CodeBuild in VPC)  
- **Secrets**: No real secrets in VCS; runtime config via **SSM Parameter Store / Secrets Manager**

---

## Implementation steps (10–20)

1. **Repo build readiness**
   - Ensure both services build independently in the multi-module Maven repo.
   - Pin Java/Maven via Maven Wrapper and/or toolchains (consistent CI).

2. **Docker packaging**
   - Create/verify `Dockerfile` for:
     - `loan-command-service`
     - `loan-query-service`
   - Add `.dockerignore` to reduce build context and speed up builds.

3. **Health endpoints**
   - Standardize `/actuator/health` (and optionally `/actuator/health/readiness`) for both services.
   - Decide minimal “ready” behavior (e.g., fail fast if required config missing).

4. **ECR repositories**
   - Create ECR repositories (either one per service or a single repo with two images).
   - Define tagging strategy:
     - `sha` (immutable)
     - optional `branch`
     - optional `latest` for main

5. **ECS baseline services**
   - Create/confirm 2 ECS services in the target cluster:
     - `loan-command-service`
     - `loan-query-service`
   - Confirm EC2 capacity is available (container instance is ACTIVE).

6. **Networking mode decision**
   - Choose **`awsvpc`** (recommended for ALB + clearer security) or `bridge` (simpler).
   - Align security groups and subnets accordingly.

7. **Internal ALB**
   - Create **internal** ALB.
   - Create target groups for each service.
   - Configure listener rules (paths/hosts) to route to the correct target group.

8. **Logging**
   - Configure CloudWatch Logs in each ECS task definition (log group per service).
   - Ensure log retention is set appropriately.

9. **Runtime secrets/config**
   - Store sensitive parameters in:
     - **SSM Parameter Store** and/or **AWS Secrets Manager**
   - Inject into ECS tasks via task definition `secrets` (no real credentials in git).
   - Keep only `application-xplore.yml.example` (or similar) in repo.

10. **GitHub Actions → AWS authentication (OIDC)**
   - Configure AWS IAM OIDC provider for GitHub.
   - Create an IAM role for deployment with trust policy restricted to:
     - your org/repo
     - specific branch (e.g., `main`) and/or environments

11. **Least-privilege deploy permissions**
   - Attach minimal policies to the deploy role:
     - ECR push (GetAuthorizationToken, PutImage, UploadLayerPart, etc.)
     - ECS register task definition + update service
     - `iam:PassRole` for ECS task execution role (and task role if needed)

12. **CI workflow (build + tests)**
   - GitHub Actions workflow for PR/push:
     - checkout
     - cache Maven
     - `mvn -U test`

13. **CD workflow (deploy)**
   - GitHub Actions workflow on push to `main` (or tags):
     - build images
     - login to ECR
     - push images
     - render/update task definitions with new image tags/digests
     - update ECS services and wait for stability

14. **Task definitions as code**
   - Store ECS task definitions in repo, e.g.:
     - `ecs/taskdef-loan-command.json`
     - `ecs/taskdef-loan-query.json`
   - Template the image reference to insert the freshly built digest/tag during deploy.

15. **Smoke step inside VPC**
   - Preferred: **SSM Run Command** to execute `curl` from an EC2 instance inside the VPC to:
     - internal ALB endpoints
     - and/or service private endpoints
   - Alternative: CodeBuild project attached to VPC running the same smoke commands.

16. **Smoke checks**
   - At minimum:
     - `/actuator/health` for both services returns UP
   - Optional:
     - a lightweight functional endpoint that does not require real host access (feature-flagged / stubbed)

17. **Rollback**
   - Keep previous task definition ARN(s).
   - If smoke fails:
     - redeploy previous task definition (fast rollback)
     - surface logs and failure reason

18. **Observability**
   - Add alarms:
     - Unhealthy targets in ALB target groups
     - ECS service deployment failures / task restart spikes
   - Ensure logs are easily discoverable (links in runbook).

19. **Environment strategy**
   - Define `dev` vs `prod` approach:
     - separate ECS services/clusters, or
     - same cluster with isolated namespaces/configs
   - Split SSM parameters/secrets by environment.

20. **Runbook**
   - Add `RUNBOOK_DEPLOY.md`:
     - manual deploy steps
     - rollback steps
     - smoke command(s)
     - where to check logs/alarms

---
