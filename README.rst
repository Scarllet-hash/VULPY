# VULPY — Web Application Security Lab

VULPY is an educational web application (Python / Flask / SQLite) provided in two variants:
- **GOOD**: Designed to demonstrate secure development best practices (work in progress).
- **BAD**: Intentionally contains common vulnerabilities for learning and practice.

This repository includes an automated security toolchain (SAST, SCA, DAST) orchestrated with Jenkins and Docker: Bandit for static Python analysis, Trivy for dependency/image scanning, and OWASP ZAP for dynamic application scanning.

Warning: This project is for educational purposes (MIT License). Do not run the BAD version in production or in any environment accessible to untrusted users.

Contents
- Description
- Architecture & tools
- Quick install (local and Docker)
- Database initialization
- Default credentials
- Running security scans (Bandit, Trivy, ZAP)
- Jenkins integration (example Jenkinsfile)
- Viewing reports
- Recommendations & best practices
- Contributing
- License & legal notice

Description
-----------
VULPY is a hands-on lab to:
- Explore common web vulnerabilities (XSS, SQLi, CSRF, etc.) in the BAD variant.
- Learn and implement mitigations in the GOOD variant.
- See how automated security checks (SAST, SCA, DAST) can be integrated into CI pipelines using Jenkins and Docker.

Architecture & tools
---------------------
- Application: Python + Flask, SQLite DB (separate DB files for GOOD and BAD).
- Security toolchain:
  - Bandit — SAST for Python code.
  - Trivy — SCA / image and dependency scanning.
  - OWASP ZAP — DAST for active HTTP scanning.
  - Jenkins — Pipeline orchestration for automated scans and reports.
- Containers: Docker images for the app, Jenkins, and scanners (recommended setup).
- Reports: HTML / XML artifacts that can be archived in Jenkins for review.

Quick installation
------------------

Prerequisites
- git, Python 3.8+, pip
- Docker & Docker Compose (if using Docker)
- Jenkins (if not using containerized Jenkins)

Option A — Local development
1. Clone the repository:
```bash
git clone https://github.com/Scarllet-hash/VULPY.git
cd VULPY
```
2. Create a virtual environment and install dependencies:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```
3. Initialize the database (see Database initialization).
4. Run the application (adjust the entrypoint filename if different):
```bash
export FLASK_APP=app.py   # or run.py depending on repo
export FLASK_ENV=development
flask run --host=0.0.0.0 --port=5000
# or
python3 app.py
```

Option B — Docker / Docker Compose (recommended for Jenkins)
1. Clone the repository:
```bash
git clone https://github.com/Scarllet-hash/VULPY.git
cd VULPY
```
2. Build and start containers (if a docker-compose.yml is provided):
```bash
docker-compose up -d --build
```
3. If Jenkins is containerized here, open Jenkins at http://localhost:8080 and import/enable the pipeline.

Database initialization
-----------------------
Each variant (`bad/` and `good/`) includes a `db_init.py` script to create its SQLite databases.

Example:
```bash
# Initialize the BAD version DB
cd bad
./db_init.py

# Initialize the GOOD version DB
cd ../good
./db_init.py
```

Default credentials
-------------------
After DB initialization, three default users are created:

Username | Password
-------- | --------
admin    | SuperSecret
elliot   | 123123123
tim      | 12345678

Note: Historically the app didn’t implement a role/permission system, so these users have equivalent access.

Running security scans
----------------------

Bandit (SAST — static analysis of Python)
```bash
# Install locally if needed
pip install bandit

# Run Bandit against a folder (bad/ or good/)
bandit -r bad/ -f html -o reports/bandit-report.html
```

Trivy (SCA / vulnerabilities in files or Docker images)
```bash
# Scan file system (project code)
trivy fs --severity HIGH,CRITICAL -o reports/trivy-fs-report.txt .

# Scan a Docker image
trivy image --severity HIGH,CRITICAL -o reports/trivy-image-report.txt your-image:tag
```

OWASP ZAP (DAST — dynamic scanning)
- Use `zap-baseline.py` or `zap-full-scan.py` to scan your running app.

Example (local script):
```bash
zap-baseline.py -t http://localhost:5000 -r reports/zap-baseline-report.html
```

Example (Dockerized ZAP):
```bash
docker run --rm -v $(pwd)/reports:/zap/reports -t owasp/zap2docker-stable zap-baseline.py -t http://host.docker.internal:5000 -r /zap/reports/zap-report.html
```

Adjust the target URL and host name for Docker networking (e.g., `host.docker.internal` or a Docker Compose service name).

Jenkins integration (example Jenkinsfile)
----------------------------------------
A typical declarative pipeline for running and archiving scanners:

```groovy
pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('SAST - Bandit') {
      steps {
        sh 'pip install bandit'
        sh 'mkdir -p reports'
        sh 'bandit -r bad/ -f xml -o reports/bandit.xml || true'
        archiveArtifacts artifacts: 'reports/bandit.*', allowEmptyArchive: true
      }
    }
    stage('SCA - Trivy') {
      steps {
        sh 'mkdir -p reports'
        sh 'trivy fs --format template --template "@contrib/html.tpl" -o reports/trivy.html . || true'
        archiveArtifacts artifacts: 'reports/trivy.*', allowEmptyArchive: true
      }
    }
    stage('DAST - ZAP') {
      steps {
        sh 'docker run --rm -v $WORKSPACE/reports:/zap/reports owasp/zap2docker-stable zap-baseline.py -t http://web:5000 -r /zap/reports/zap.html || true'
        archiveArtifacts artifacts: 'reports/zap.*', allowEmptyArchive: true
      }
    }
  }
  post {
    always {
      junit 'reports/**/*.xml' // if any scanner produces JUnit-compatible XML
      publishHTML(target: [
        reportName: 'Security Reports',
        reportDir: 'reports',
        reportFiles: 'bandit.html,trivy.html,zap.html',
        allowMissing: true
      ])
    }
  }
}
```

Notes:
- Adjust network/service names, container permissions, and credentials to your Jenkins environment.
- Use non-blocking stages (handle exit codes) if you prefer to collect results without failing the pipeline immediately.

Viewing and using reports
-------------------------
- HTML reports (Bandit, Trivy, ZAP) are easy to read in a browser or via Jenkins artifacts.
- XML/JUnit outputs can be used for trend metrics in Jenkins.
- Manually review results: false positives are common and need triage.

Recommendations & best practices
--------------------------------
- Keep BAD and GOOD environments isolated.
- Never expose the BAD variant to the public internet.
- Shift-left: run SAST/SCA early and often in CI.
- Store no secrets in the repository. Use secret management for credentials and Jenkins secrets.
- Triage findings by severity and remediate HIGH/CRITICAL issues first.
- Combine automated scans with manual code review and security testing.

Contributing
------------
Contributions are welcome:
- Improve the GOOD variant (fixes, tests, docs).
- Add exercises, lab guides, or Jenkins job templates.
- Report issues or request features via GitHub Issues.

To contribute:
```bash
git checkout -b feat/my-change
# make changes and test
git commit -am "Add: ..."
git push origin feat/my-change
# Open a Pull Request on GitHub
```

License & legal / ethical notice
-------------------------------
This repository is provided for educational purposes under the MIT License. Do not use techniques demonstrated here to attack systems without explicit permission. Always follow applicable laws and responsible disclosure practices.

Further help
------------
If you’d like, I can:
- Generate a ready-to-use Jenkinsfile tailored to your Docker Compose setup.
- Provide step-by-step instructions to deploy Jenkins + Docker agents for this project.
- Create example scan-report templates or a sample Jenkins job configuration.
