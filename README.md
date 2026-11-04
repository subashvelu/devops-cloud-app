# Production-Grade Automated Cloud CI/CD Pipeline on AWS

An end-to-end DevOps pipeline demonstrating Infrastructure as Code (IaC), containerization, automated testing, and zero-downtime continuous deployment on AWS.

---

## Tech Stack & Tooling

* **Cloud Provider:** Amazon Web Services (AWS) — VPC, ALB, EC2, ECR, IAM, Systems Manager (SSM)
* **Infrastructure as Code (IaC):** Terraform (v1.10+)
* **Containerization:** Docker & Gunicorn WSGI
* **Application Framework:** Python 3.12, Flask, Pytest
* **CI/CD Automation:** GitHub Actions

---

## Key Engineering Highlights

1. **Defense-in-Depth Security:**
   * EC2 instance has no open SSH port (22); configuration and container deployment occur via AWS Systems Manager (SSM).
   * Host security group permits inbound traffic on port 5000 strictly from the Application Load Balancer security group.
2. **Infrastructure as Code (IaC):**
   * Multi-AZ public subnet provisioning with route tables and internet gateway.
   * Decoupled modules with variables, outputs, and provider pin configs.
3. **Automated Continuous Integration & Deployment:**
   * Every commit executes automated unit testing (`pytest`) and local image validation.
   * Master branch pushes automatically build Docker images, authenticate to Amazon ECR, push tagged releases, and deploy the updated container to EC2 with automated container replacement.
4. **Resilience & Health Probing:**
   * ALB target group actively runs continuous health checks against `/health` before routing live user traffic.

---

## Repository Structure

```text
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Automated testing & Docker verification
│       └── deploy.yml             # ECR build & SSM deployment pipeline
├── terraform/
│   ├── main.tf                   # VPC, ALB, EC2, ECR, IAM resources
│   ├── variables.tf              # Region and sizing declarations
│   ├── versions.tf               # Terraform & AWS provider requirements
│   └── outputs.tf                # ALB DNS and ECR endpoints
├── app.py                         # Flask REST API implementation
├── test_app.py                    # Pytest unit tests
├── Dockerfile                     # Container build spec
├── requirements.txt               # Dependencies
└── README.md                      # Project documentation