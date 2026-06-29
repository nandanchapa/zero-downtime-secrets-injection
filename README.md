# Enterprise DevSecOps: Dynamic PAM-Driven Credential Rotation for High-Availability Applications

An enterprise-grade DevSecOps integration blueprint implementing dynamic, zero-downtime database credential injection using a Privileged Access Management (PAM) REST API (BeyondTrust Password Safe) and a custom Linux environment wrapper. 

This repository showcases the implementation of a parallel sandbox infrastructure designed to test automated credential rotation pipelines without impacting production systems.



## 🏗️ Architecture Overview

The pipeline eliminates static, hardcoded credentials stored in flat configuration files by dynamically querying the PAM vault during the application initialization phase.
```mermaid
flowchart TD
    %% Server Subgraph Boundary
    subgraph Host [Enterprise Linux Host]
        
        %% Sandbox Context
        subgraph Sandbox_Pipeline [Validated Sandbox Environment]
            sysd3001[systemd Daemon: app-sandbox.service]
            wrapper3001[Bash Wrapper: scripts/bootstrap-injector.sh]
            app3001[Application Core: Port 3001]
        end

        %% Central Orchestration & Target
        py[Python Vault Client: vault_client.py]
        filter[Stream Text Filter: tr -d quotes]
        db[(Target Database: Port 5432)]

        %% Production Context
        subgraph Prod_Pipeline [Production Deployment Environment]
            sysd3000[systemd Daemon: application-server.service]
            wrapper3000[Bash Wrapper: scripts/production-injector.sh]
            app3000[Application Core: Port 3000]
        end

    end

    subgraph Network [Secure Corporate Core]
        pam[PAM API Endpoint]
    end

    %% Sandbox Connections
    sysd3001 --> wrapper3001
    wrapper3001 --> py
    py ==> pam
    pam -.-> py
    py --> filter
    filter --> app3001
    app3001 ==> db

    %% Production Migration Path
    sysd3000 -.-> wrapper3000
    wrapper3000 -.-> py
    filter -.-> app3000
    app3000 -.-> db
```
## 🛠️ Key Technical Challenges & Resolutions
1. Dual-Port Instance Forking (Zero-Downtime Sandbox)
Challenge: Test a critical authentication modification on a production application cluster without introducing security risks or service interruptions.

Resolution: Engineered a standalone systemd daemon profile (app-sandbox.service). This created an isolated runtime memory context, distinct tracking PIDs, and split TCP socket streams (forwarding the test cluster to a shadow port 3001), entirely abstracting it away from the production pipeline on port 3000.

2. Stream Sanitization in Shell Injection
Challenge: The application failed to parse standard output returned from the Python API engine because the retrieved secret data string arrived encapsulated in literal JSON string quotation wrappers ("").

Resolution: Implemented an inline translation subshell wrapper manipulation technique using Unix piping filters (| tr -d '"'). This dynamically strips boundaries from the text stream, delivering a raw string payload straight to the initialization environment variables.

3. Enterprise OS-Level Trust Store Optimization
Challenge: Python's cryptographic engines initially rejected connections to internal appliances due to enterprise self-signed certificate authority validations.

Resolution: Bypassed connection blocks safely during initial setup using structural request flags while concurrently reinforcing the underlying operating system trust store. Leveraged administrative tooling (update-ca-trust) to register the organizational Root and Intermediate CA bundles natively inside the host environment to enable full end-to-end verification.

## 💾 System Components & Integration Schematics
The automation components are structured to decouple the orchestration logic from vendor binary upgrades. Scripts are centrally stored in the /scripts/ directory.

1. The Environment Injector Bootstrapper (scripts/bootstrap-injector.sh)
This wrapper script is invoked directly by systemd to intercept the application initialization lifecycle, fetching and injecting runtime configurations directly into memory.

2. Production Deployment Configuration (override.conf)
To migrate this configuration seamlessly to the production instance (port 3000) without modifying vendor-installed base service files, systemd Drop-in Overrides are implemented. This prevents package upgrades from wiping out the automation hooks.

## 📊 Core Competencies Demonstrated
Advanced Automation & Systems Scripting: Mastery of mixing complex Bash scripting paradigms with advanced object extraction architectures in Python.

DevSecOps & Secrets Management: Hands-on experience building custom API integrations with enterprise access management utilities to eliminate hardcoded secrets.

Linux Systems Internals: Practical understanding of how systemd coordinates background daemons, environment variable precedence, process namespace allocation (exec), and system trust anchors.
