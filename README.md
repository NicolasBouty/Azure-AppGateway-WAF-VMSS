# Azure AZ-104 Lab: Secure Enterprise Multi-Tier Web Architecture with Application Gateway WAF v2 (Zero-Trust Egress)

## 📌 Context & Objectives
This repository demonstrates a fully private, production-grade multi-tier architecture on Microsoft Azure aligned with **AZ-104 (Azure Administrator)** skills and Zero-Trust principles:
- **Zero Internet Egress:** VM Scale Sets (VMSS) and Management Jumpbox have no public IP addresses and zero outbound access to the Internet.
- **WAF Security:** Application Gateway WAF v2 handles TLS termination, public HTTPS routing, and Web Application Firewall rules (OWASP v3.2).
- **Private Gateway Ingress:** Internal administrative and routing access via a private frontend IP (`10.0.1.10`).
- **Path-Based Routing:** Smart routing separating `/` (Web Service) and `/api/*` (API Service) across dedicated backends.

---

## 📐 Architecture Diagram
```mermaid
graph TD
    Client[Client Internet / Curl / Browser]
    
    subgraph VNet [VNet Azure : 10.0.0.0/16]
        
        subgraph Subnet_AppGW [Subnet AppGW : 10.0.1.0/24]
            AppGW[Application Gateway v2 WAF<br/>IP Publique Standard<br/>IP Privée : 10.0.1.10]
        end

        subgraph Subnet_Backend_A [Subnet Backend-A : 10.0.2.0/24]
            VMSS_A[VMSS A - Web Racine /*<br/>2x Instances HTTP : 10.0.2.x<br/>Auto-Repairs Policy]
        end

        subgraph Subnet_Backend_B [Subnet Backend-B : 10.0.3.0/24]
            VMSS_B[VMSS B - API /api/*<br/>2x Instances HTTP : 10.0.3.x]
        end

        subgraph Subnet_Mgmt [Subnet Management : 10.0.4.0/24]
            Jumpbox[VM Jumpbox Privée<br/>IP : 10.0.4.x<br/>Console Série / Boot Diag]
        end

    end

    LogAnalytics[(Log Analytics Workspace)]

    %% Flux Publics
    Client -->|1. HTTP :80 - Redirection 301| AppGW
    Client -->|2. HTTPS :443 - Request GET /| AppGW
    Client -->|3. HTTPS :443 - Request GET /api/*| AppGW

    %% Routage AppGW
    AppGW -->|Path /* -> Pool A| VMSS_A
    AppGW -->|Path /api/* -> Pool B| VMSS_B

    %% Flux Privés & Administration
    Jumpbox -->|Accès Privé HTTP : 10.0.1.10| AppGW
    Jumpbox -.->|Rebond SSH Interne :80/22| VMSS_A

    %% Logs & WAF
    AppGW -.->|Journaux WAF & Diagnostic| LogAnalytics

```
