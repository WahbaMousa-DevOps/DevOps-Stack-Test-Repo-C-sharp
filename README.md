# DevOps-Stack-Test-Repo-C-sharp

# Add pranch protections + enforce + API CALL

## 📘 Enterprise-Grade CI/CD Pipeline for .NET (C#) Apps with Jenkins

This repository showcases a **complete DevSecOps pipeline** for building, testing, scanning, and deploying a Dockerized C# (.NET) application using **Jenkins Declarative Pipelines**.

The solution follows industry standards for **multistage CI/CD**, **secure image delivery**, **pipeline auditability**, and **infrastructure hygiene**. Ideal for both **production** and **educational** use.

---

## 🚀 Core Highlights

- 🧬 Git-based multibranch pipeline with dynamic environments (`main`, `staging`, `develop`, `release/*`)
- 🕵️‍♂️ Secrets scanning with `git-secrets` and `gitleaks`
- ✅ Secure credential injection and artifact verification
- 🧪 Test coverage & reporting with Coverlet + ReportGenerator
- 🛡️ Vulnerability scanning for NuGet packages and Docker images
- 📦 SBOM generation (source + container) with CycloneDX
- 🔍 Static code analysis + quality gate via SonarQube
- 🏷️ OCI-compliant image metadata and optional Cosign signing
- 🚦 Manual approval gates for production deploy
- 📈 Audit logging and build traceability

---

## 🧱 Folder Structure

```bash
repo-root/
├── Jenkinsfile              # Main pipeline logic
├── Dockerfile               # App Docker build definition
├── Program.cs               # Sample C# app
├── csharp-hello.csproj      # Project file
├── publish/                 # Build output directory
├── pipeline-audit.json      # JSON audit log
├── sbom-container.json      # Container SBOM (Trivy)
├── checksums.txt            # Hashes of built DLLs
└── README.md
```

---

## 🔧 Jenkins Environment Assumptions

| Component     | Configuration Summary                                          |
| ------------- | -------------------------------------------------------------- |
| Jenkins Agent | Runs on label `dotnet`, preinstalled with Docker + .NET SDK    |
| Credentials   | Injected via `dockerhub-credentials`, `cosign.key` (optional)  |
| SCM           | GitHub via SSH/HTTPS                                           |
| SonarQube     | Named `SonarQube` instance available in Jenkins                |
| Tools         | dotnet CLI, Trivy, Hadolint, ReportGenerator, Gitleaks, Cosign |

---

## 🔁 Pipeline Stages Overview

### 1. **Checkout**
- Git clone with shallow depth
- Git metadata captured
- Secrets scanning using `git-secrets` and `gitleaks`

### 2. **Set Variables**
- Computes metadata: commit hash, project version, environment
- Tags Docker image with commit + build number

### 3. **Audit Setup**
- Generates pipeline-audit.json with execution metadata

### 4. **Dependency Audit**
- Scans for vulnerable, outdated, or unlicensed packages
- Fails production builds with unapproved vulnerabilities

### 5. **Restore & Build**
- Clean restore and optimized build of the .NET project

### 6. **Test & Coverage**
- Executes unit tests with coverage output
- Archives HTML reports and test results

### 7. **SonarQube Analysis**
- Runs static code analysis and publishes results to SonarQube

### 8. **Quality Gate**
- Waits for SonarQube gate approval before continuing

### 9. **Publish**
- Builds final artifacts to `./publish`
- Generates SBOM and file checksums

### 10. **Build Docker Image**
- Scans Dockerfile with Hadolint
- Adds build metadata and OCI labels

### 11. **Scan Docker Image**
- Trivy vulnerability scan (fail on HIGH/CRITICAL)
- Generates CycloneDX SBOM for the container

### 12. **Health Check**
- Runs and checks `/health` endpoint of the image

### 13. **Push Docker Image**
- Pushes versioned and `latest` tags to Docker Hub
- Signs image using Cosign (optional)

### 14. **Deploy (Manual Gate)**
- Prompts for approval before pushing to production

### 15. **Post-Cleanup**
- Prunes Docker images and archives audit + build artifacts

---

## 🔐 Security Layers

| Layer                | Tool or Practice Used                         |
| -------------------- | --------------------------------------------- |
| Secret scanning      | `git-secrets`, `gitleaks`                     |
| Dependency audit     | `dotnet list package`, `outdated`, `licenses` |
| Dockerfile hardening | `hadolint`, grep rules                        |
| Container CVE scan   | `trivy` with severity filtering               |
| Credential handling  | Jenkins credentials store                     |
| SBOM generation      | CycloneDX plugin/tool                         |
| Image authenticity   | Cosign signing                                |
| Health validation    | Docker `--health` with retries                |

---

## 📦 Shared Library Structure (Optional)

```bash
jenkins-shared-lib/
├── vars/
│   └── buildDotnet.groovy     # Main reusable entry point
├── src/org/devops/utils/
│   ├── MetadataUtil.groovy    # Versioning & fingerprinting helpers
│   └── SecurityUtil.groovy    # Scan triggers & validation
└── resources/templates/       # Hadolint rules, Docker hints
```

In `Jenkinsfile`:

```groovy
@Library('jenkins-shared-lib') _

buildDotnet(
  repoName: 'wahbamousa/csharp-sample-app',
  sonarKey: 'csharp-sample-app',
  dockerCredentialsId: 'dockerhub-credentials'
)
```

---

## 📊 Visual CI/CD Flow Diagram

![CI/CD Flow Diagram](sandbox:/mnt/data/A_diagram_in_the_image_illustrates_a_CI/CD_pipelin.png)

---

## 📌 Best Practices Checklist

* [x] Run secrets scan before build
* [x] Validate build via audit and SBOM
* [x] Fail early on high-severity vulnerabilities
* [x] Sign and label Docker images
* [x] Retain all artifacts, logs, and health indicators

---

## 📎 License

MIT License — Free to reuse, fork, or adapt.



Fix APP_VERSION Setting:

Move APP_VERSION setting after all the variables it depends on are set
Ensure VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH are defined before use



Security Enhancements

Use Docker Registry Credential Helper:
groovywithCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
   // Use --password-stdin instead of -p for more secure credential handling
   sh """
      echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin ${DOCKER_REGISTRY}
      docker push ${DOCKER_IMAGE_VERSION}
      docker push ${DOCKER_IMAGE_LATEST}
      docker logout ${DOCKER_REGISTRY}
   """
}

Add Container Security Scan Actions:

Consider adding Anchore or Trivy scans with configurable severity thresholds
Add container image signature verification


Enhanced Secret Management:

Consider using HashiCorp Vault or AWS Secrets Manager for secret injection
Add detection for new secrets introduced during PRs



Performance Improvements

Optimize Docker Layer Caching:
dockerfile# Dockerfile optimization recommendation
COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app

Parallel Test Execution Strategy:
groovystage('Test & Coverage') {
   when { expression { return !params.SKIP_TESTS } }
   steps {
      sh '''
      dotnet test --no-build --no-restore -c Release \
         --logger "trx;LogFileName=test-results.trx" \
         /p:CollectCoverage=true \
         /p:CoverletOutputFormat=opencover \
         /p:CoverletOutput=./coverage/ \
         /p:ParallelizeTestCollections=true \
         /p:MaxParallelThreads=$(nproc || echo 4) \
         --blame-hang-timeout 60s \
         --blame-crash
      '''
   }
}

Multi-stage Cache Strategy:

Add BuildKit caching for intermediate steps
Consider adding NuGet package caching



CI/CD Enhancements

Add Branch-Specific Logic:
groovyenvironment {
   // Environment-specific configurations with more advanced mapping
   DEPLOY_TARGET = [
      'main': 'production',
      'staging': 'staging',
      'develop': 'development',
      'PR-.*': 'preview'
   ].find { pattern, _ -> env.BRANCH_NAME =~ pattern }?.value ?: 'development'
}

Add Preview Environments for PRs:
groovystage('Deploy Preview') {
   when { 
      expression { return env.BRANCH_NAME.startsWith('PR-') } 
   }
   steps {
      echo "Deploying preview environment for PR-${env.CHANGE_ID}"
      // Deploy to ephemeral environment
   }
}

Add Semantic Versioning Logic:

Add proper SemVer incrementing based on commit messages
Tag Git repo when deploying to production



Resilience Improvements

Add Circuit Breaking for External Dependencies:

Add retry logic for external service calls
Add timeouts to prevent pipeline hanging


Add Rollback Capability:
groovystage('Deployment') {
   steps {
      script {
         try {
            sh "kubectl apply -f k8s/deployment.yaml"
            sh "kubectl rollout status deployment/myapp -n ${NAMESPACE} --timeout=180s"
         } catch (Exception e) {
            echo "Deployment failed, rolling back: ${e.message}"
            sh "kubectl rollout undo deployment/myapp -n ${NAMESPACE}"
            error "Deployment failed and was rolled back"
         }
      }
   }
}

Add Canary Deployment Strategy:

Deploy to a small subset of users first
Monitor for errors before full deployment



Monitoring & Observability

Add Performance Testing Stage:
groovystage('Performance Testing') {
   when { expression { return env.BRANCH_NAME == 'main' || params.RUN_PERF_TESTS } }
   steps {
      sh "k6 run performance-tests/load-test.js"
   }
}

Add Metadata for Observability:

Add more tracing IDs and correlation IDs
Connect CI/CD metrics to application monitoring


Pipeline Analytics:

Add timing metrics for each stage
Track build success rates and test flakiness