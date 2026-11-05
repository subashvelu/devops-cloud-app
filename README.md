# Cloud CI/CD Pipeline on AWS

A small Flask API deployed to AWS with Infrastructure as Code, containers and a fully automated GitHub Actions pipeline.

## Architecture

```text
 git push (main)
      │
      ▼
 GitHub Actions ── CI: pytest, Docker build + smoke test, terraform validate
      │
      ├─► build image ─► push to Amazon ECR  (tags: <commit-sha>, latest)
      │
      └─► AWS SSM Run Command ─► EC2 pulls image, replaces container, checks /health
                                         ▲
 User ─► Application Load Balancer :80 ──┘  (target port 5000, health check on /health)
```

## Tech stack

* **AWS:** VPC, ALB, EC2, ECR, IAM, Systems Manager (SSM)
* **IaC:** Terraform >= 1.10
* **Container:** Docker, Gunicorn (runs as a non-root user)
* **App:** Python 3.12, Flask, pytest
* **CI/CD:** GitHub Actions

## Design decisions

* **No SSH.** Port 22 is closed. Deployments go through SSM, authenticated by IAM.
* **Instance only reachable via the ALB.** The instance security group allows port 5000 only from the ALB security group.
* **Immutable image tags.** Every deploy is tagged with the git commit SHA (so you can roll back); `latest` is also updated. `GET /` returns the running commit.
* **Deploy result is verified.** The pipeline waits for the SSM command, prints the server output, and fails if the container does not pass its `/health` check.
* **Tests are not duplicated.** `deploy.yml` calls `ci.yml` as a reusable workflow.
* **Hardened instance.** IMDSv2 required, encrypted root volume, ECR lifecycle policy (keeps the last 10 images), ECR image scanning.

## Repository layout

```text
.github/workflows/ci.yml       tests, docker build + smoke test, terraform validate
.github/workflows/deploy.yml   build, push to ECR, deploy over SSM
terraform/                     all AWS infrastructure
app.py / test_app.py           the application and its tests
Dockerfile                     container image
requirements.txt               runtime dependencies
requirements-dev.txt           + test dependencies
LEARN.md                       personal study guide (Tanglish)
```

## Run locally

```bash
pip install -r requirements-dev.txt
pytest -v
python app.py            # http://localhost:5000
```

## Deploy

```bash
cd terraform
terraform init
terraform apply
```

Add these GitHub repository secrets (values come from `terraform output`):

| Secret | Value |
|---|---|
| `AWS_REGION` | `ap-south-1` (`aws_region` output) |
| `ECR_REPOSITORY` | `ecr_repository_name` output |
| `EC2_INSTANCE_ID` | `instance_id` output |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | an IAM user allowed to push to ECR and use SSM |

Wait 2-3 minutes after `terraform apply` (the instance must register with SSM), then push to `main`. Open the `alb_dns_name` output in a browser.

## Tear down

```bash
cd terraform
terraform destroy
```

## Known limitations (and what I would do next)

* **Brief downtime during deploys.** One instance, and the container is replaced in place (a few seconds). Real zero-downtime needs an Auto Scaling Group with rolling instance refresh, or ECS/Fargate.
* **HTTP only.** HTTPS needs a domain + ACM certificate + a 443 listener.
* **Static AWS keys in GitHub secrets.** Better: GitHub OIDC with an IAM role (no long-lived keys).
* **Local Terraform state.** Better: S3 backend (a commented example is in `terraform/versions.tf`).
* **Single instance in a public subnet.** Better: private subnets + NAT/VPC endpoints, and an Auto Scaling Group.
