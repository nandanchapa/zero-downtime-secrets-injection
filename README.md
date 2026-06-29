# Enterprise DevSecOps: Dynamic PAM-Driven Credential Rotation for High-Availability Applications

An enterprise-grade DevSecOps integration blueprint implementing dynamic, zero-downtime database credential injection using a Privileged Access Management (PAM) REST API (BeyondTrust Password Safe) and a custom Linux environment wrapper. 

This repository showcases the implementation of a parallel sandbox infrastructure designed to test automated credential rotation pipelines without impacting production systems.



## 🏗️ Architecture Overview

The pipeline eliminates static, hardcoded credentials stored in flat configuration files by dynamically querying the PAM vault during the application initialization phase.
```mermaid
graph TD
---
config:
  theme: neo
---
flowchart TB
 subgraph Sandbox_Pipeline["Validated Sandbox Environment"]
        sysd3001["systemd Daemon: app-sandbox.service"]
        wrapper3001["Bash Wrapper: scripts/bootstrap-injector.sh"]
        app3001["Application Core: Port 3001"]
  end
 subgraph Prod_Pipeline["Production Deployment Environment"]
        sysd3000["systemd Daemon: application-server.service"]
        wrapper3000["Bash Wrapper: scripts/production-injector.sh"]
        app3000["Application Core: Port 3000"]
  end
 subgraph Host["Enterprise Linux Host"]
        Sandbox_Pipeline
        py["Python Vault Client: vault_client.py"]
        filter["Stream Text Filter: tr -d quotes"]
        db[("Target Database: Port 5432")]
        Prod_Pipeline
  end
 subgraph Network["Secure Corporate Core"]
        pam["PAM API Endpoint"]
  end
    sysd3001 --> wrapper3001
    wrapper3001 --> py
    py ==> pam
    pam -.-> py
    py --> filter
    filter --> app3001
    app3001 ==> db
    sysd3000 -. systemctl edit override .-> wrapper3000
    wrapper3000 -. Invokes .-> py
    filter -.-> app3000
    app3000 -.-> db
