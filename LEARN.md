# LEARN.md - Study Guide (Tanglish)

Idhu unga personal study guide. Portfolio-kku venaam na delete pannidalam.
Infra destroy aana apparam kooda, indha file-a padichi ellam purinjikkalam.

---

## 1. Entha order-la padikkanum?

1. `app.py` -> `test_app.py` (5 min, simple)
2. `Dockerfile` (10 min)
3. `.github/workflows/ci.yml` (15 min)
4. `terraform/main.tf` (30 min, romba important)
5. `.github/workflows/deploy.yml` (20 min)
6. Mudinjadhum, #6 "Mind map" paarunga

---

## 2. Oru restaurant maari yosinga

| AWS / DevOps | Restaurant analogy |
|---|---|
| **App (Flask)** | Chef - actual velai |
| **Docker image** | Parcel-pannina ready-made meal kit. Eppadi, enga cook pannalum same result |
| **ECR** | Meal kit-a store panra warehouse |
| **EC2** | Kitchen (server) |
| **ALB (Load Balancer)** | Receptionist. Customer-a kitchen-ku anuppum, kitchen close-na anuppadhu |
| **Health check `/health`** | Receptionist "chef irukkaara?" nu kekkradhu |
| **VPC** | Restaurant building |
| **Subnet** | Building-la oru floor |
| **Internet Gateway** | Building-oda main door |
| **Security Group** | Security guard - yaar ulla vara mudiyum nu rule |
| **IAM Role** | Staff ID card - kitchen-ku warehouse-la irundhu eduka mattum permission |
| **SSM** | Remote walkie-talkie. SSH key illama kitchen-ku order anuppalam |
| **Terraform** | Restaurant blueprint. Blueprint-a run panna building thaanaa varum |
| **GitHub Actions** | Auto delivery robot: code vandha test -> pack -> warehouse -> kitchen |

---

## 3. File by file

### `app.py`
- `/` -> JSON kudukum, `commit` field-la entha git commit live-la irukku nu kaattum
- `/health` -> `{"status":"healthy"}`. ALB idha 30 sec-ku oru thadava check pannum
- `GIT_SHA` environment variable Dockerfile-la irundhu varum

### `Dockerfile`
1. `FROM python:3.12-slim` -> Python ulla chinna base image
2. `COPY requirements.txt` + `pip install` **munnaadi**, code-a apparam. Reason: Docker layers cache aagum. Code mattum maariyaa, pip install thirumba run aagaadhu (fast build)
3. `USER appuser` -> root-a illa. App hack aanaalum damage kammi
4. `HEALTHCHECK` -> Docker thaane check pannum
5. `gunicorn` -> production server (Flask-oda dev server production-ku sari illa)

### `requirements.txt` vs `requirements-dev.txt`
Runtime-ku Flask + gunicorn mattum. pytest test-ku mattum, so image-kulla poga venaam (small + secure).

### `ci.yml` (Continuous Integration)
3 jobs:
- `test` -> pytest
- `docker-build` -> image build + container run panni `/health` call panni paakkum
- `terraform-validate` -> Terraform syntax check

`workflow_call` nu irukku. Idhunaala `deploy.yml` idha function maari **call** panna mudiyum.

### `deploy.yml` (Continuous Deployment)
1. `ci` job -> `ci.yml` call pannum. Fail aana deploy nikkum
2. AWS login
3. ECR login
4. Docker build -> **2 tags**: commit SHA (`a1b2c3...`) and `latest`
5. SSM vazhiya EC2-ku 6 commands:
   - ECR login (EC2-la)
   - `docker pull` -> **Munnaadi pull**. Pull fail aana paza container touch aagaadhu
   - `docker stop` + `docker rm` -> paza container neekku
   - `docker run` -> pudhu container start
   - `/health` check -> 30 sec-kulla healthy aagala na FAIL
6. `aws ssm wait` -> command mudiyura varaikum wait. Fail aana GitHub job RED aagum

`concurrency` -> rendu deploy ore time-la run aagaama thadukkum.

### `terraform/`
`main.tf` 6 sections (comment-la numbered). Dependency-a gavanikkunga:

```
VPC -> Subnets -> Route table
VPC -> Security groups (ALB SG, then Instance SG refers ALB SG)
IAM role -> Instance profile -> EC2
ALB -> Listener -> Target group <- EC2 attachment
```

Terraform `aws_vpc.main.id` maari reference paathu, **entha order-la create pannanum nu thaane figure out pannum**.

Mukkiyamaana commands:
| Command | Enna pannum |
|---|---|
| `terraform init` | Provider download |
| `terraform plan` | Enna maarum nu *preview* (onnum create aagaadhu) |
| `terraform apply` | Unmaiyaave create/change |
| `terraform destroy` | Ellathayum delete |
| `terraform output` | Output values kaattum |

---

## 4. Enna fix pannen, yen?

| # | Paza issue | Fix | Yen mukkiyam |
|---|---|---|---|
| 1 | README-la "zero-downtime" nu poi | Honest-a "brief downtime" nu maathi | Interview-la poi sonna maattikalaam |
| 2 | Branch `master` vs `main` | `main` | Confusion |
| 3 | Image tag `latest` mattum | Commit SHA + latest | Rollback panna mudiyum, entha code live nu theriyum |
| 4 | Test rendu thadava run | `ci.yml` reusable aakki `deploy.yml` call | Time + cost save |
| 5 | SSM result wait pannala (fail aanaalum green) | `ssm wait` + output print + `/health` verify | Silent failure thaduppu |
| 6 | pytest/requests prod image-la | `requirements-dev.txt` split, `requests` remove (use aagala) | Chinna image, kammi attack surface |
| 7 | Gunicorn 22.0.0 (known security issue) | 23.0.0 | Security |
| 8 | Container root-a run | `appuser` | Security |
| 9 | ECR-la image irundha `terraform destroy` fail | `force_delete = true` | **Ungalukku destroy easy-a aagum** |
| 10 | AMI update-na EC2 replace aagum (instance ID maarum, secret break) | `ignore_changes = [ami]` | Surprise outage thaduppu |
| 11 | IMDSv1 allow, disk encrypt illa | IMDSv2 required, encrypted disk | Security best practice |
| 12 | ECR-la images kuvindhukitte pogum (cost) | Lifecycle policy: last 10 mattum | Cost |
| 13 | Terraform state local | S3 backend example (commented) | Real teams-la remote state |
| 14 | Secrets-ku value enna nu theriyaadhu | Extra outputs: `ecr_repository_name`, etc. | Setup easy |
| 15 | Terraform error CI-la theriyaadhu | `terraform validate` job | Early error catch |

**Fix pannaadhadhu (purposely)**, ellam README "Known limitations"-la irukku:
- HTTPS (domain venum)
- True zero-downtime (Auto Scaling Group / ECS venum, romba complex)
- GitHub OIDC (extra setup)

---

## 5. DESTROY checklist (order mukkiyam)

```bash
cd terraform
terraform destroy      # "yes" type pannunga. ALB delete aaga 3-5 min aagum
```

Appuram:
1. **AWS Console (Mumbai / ap-south-1)** check: EC2, Load Balancers, Target Groups, ECR, VPC, IAM roles - ellam illa nu confirm pannunga
2. **GitHub**: Actions tab -> Deploy -> `...` -> *Disable workflow*, (illa na secrets delete). Illa na adutha `main` push-la deploy fail aagum (AWS illa)
3. **IAM user** (GitHub-ku create pannadhu): access keys delete / user delete
4. **AWS Budgets**-la $1-2 alert vechikonga, safety-ku
5. `terraform.tfstate` file-a destroy mudiyura varaikum delete pannaadheenga. Adhu illa na Terraform ethu create pannichu nu marandhudum

---

## 6. Mind map (full flow)

```
Nee code ezhudhura
   |
   | git push main
   v
GitHub Actions (deploy.yml)
   |-- ci.yml: pytest -> docker build+smoke -> terraform validate
   |-- AWS login (secrets)
   |-- docker build (tag = commit SHA) -> push ECR
   |-- SSM send-command ------------------+
   |                                      v
   |                               EC2: pull -> stop old -> run new -> /health check
   v                                      ^
 wait for result (green/red)              |
                                          |
User browser -> ALB:80 -> (SG allows only ALB) -> EC2:5000 -> container
```

---

## 7. Practice (destroy-ku apparam)

1. `terraform plan` run pannunga (AWS credentials irundha). "Plan: N to add" paarunga. Ethuvum create aagaadhu
2. `app.py`-la oru `/about` route add pannunga, test ezhudhunga, `pytest` run
3. `docker build` & `docker run` locally (Docker install irundha)
4. `main.tf`-la `ingress` port-a maathi yosinga: "idha 5001 aakkina enna break aagum?"
5. Yedhavadhu oru resource (ex: `aws_subnet.public_2`) remove pannina Terraform-la enna error varum nu predict pannunga

---

## 8. Interview-la solla vendiya 30 second pitch

> "Oru Flask API-a Docker-la package panni, AWS-la Terraform vazhiya VPC, ALB, EC2, ECR create pannen. GitHub Actions pipeline: code push aana test run aagum, Docker image commit SHA tag-oda ECR-ku push aagum, SSM vazhiya EC2-la deploy aagum. SSH port close pannirukken. Deploy aana apparam `/health` check pannitu fail aana pipeline red aagum. Limitations: single instance-nala konja seconds downtime irukku, adha Auto Scaling Group / ECS vachu improve pannalam."

## 9. Common doubts

**Q: Yen EC2 public subnet-la irukku?**
Private subnet-la vachaa ECR/SSM-ku NAT Gateway (~$30+/month) venum. Learning-ku public subnet + strict security group nalla compromise.

**Q: SSH illama epdi server-a control panrom?**
EC2-la SSM Agent irukku. AWS-kitta "outbound" connect pannum. GitHub Actions AWS API-ku command anuppum, agent adha eduthu run pannum. Inbound port onnum thirakka venaam.

**Q: `terraform apply` ku apparam deploy fail aachu?**
SSM agent register aaga 2-3 min aagum. Konja wait panni "Re-run jobs" pannunga.

**Q: ALB 503 / unhealthy?**
First deploy aagura varaikum EC2-la container illa, so health check fail. Pipeline success aana apparam 1-2 min-la healthy aagum.
