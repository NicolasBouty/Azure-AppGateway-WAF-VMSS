# Lab Azure AZ-104 : Architecture Web Multi-Tiers Sécurisée avec Application Gateway WAF v2 (Zero-Trust Egress)

## 📌 Contexte & Objectifs

Ce dépôt présente une architecture multi-tiers privée. Elle est alignée sur les compétences de la certification **AZ-104 (Administrateur Microsoft Azure)** et intègre les principes du *Zero-Trust* :

* **Sortie Internet nulle (*Zero Internet Egress*) :** les ensembles de machines virtuelles identiques (*VM Scale Sets* / VMSS) et la Jumpbox d'administration ne possèdent aucune adresse IP publique et n'ont aucun accès sortant direct vers Internet.
* **Sécurité WAF :** Azure Application Gateway WAF v2 assure la terminaison TLS, le routage HTTPS public et l'application des règles de pare-feu d'application Web (OWASP CRS 3.2).
* **Entrée privée (*Private Gateway Ingress*) :** accès administratif et routage interne via une adresse IP privée (`10.0.1.10`).
* **Routage par chemin (*Path-Based Routing*) :** répartition intelligente du trafic séparant la racine `/` (service Web) et `/api/*` (service API) vers des pools *backend* dédiés.

---

## 📐 Schéma d'Architecture

```mermaid
graph TD
    Client[Client Internet / Curl / Navigateur]
    
    subgraph VNet [VNet Azure : 10.0.0.0/16]
        
        subgraph Subnet_AppGW [Sous-réseau AppGW : 10.0.1.0/24]
            AppGW[Application Gateway v2 WAF<br/>IP Publique Standard<br/>IP Privée : 10.0.1.10]
        end

        subgraph Subnet_Backend_A [Sous-réseau Backend-A : 10.0.2.0/24]
            VMSS_A[VMSS A - Web Racine /*<br/>Instances HTTP : 10.0.2.x<br/>(autoscale 1–2)]
        end

        subgraph Subnet_Backend_B [Sous-réseau Backend-B : 10.0.3.0/24]
            VMSS_B[VMSS B - API /api/*<br/>Instances HTTP : 10.0.3.x<br/>(autoscale 1–2)]
        end

        subgraph Subnet_Mgmt [Sous-réseau Management : 10.0.4.0/24]
            Jumpbox[VM Jumpbox Privée<br/>IP : 10.0.4.x<br/>Console Série / Diag de démarrage]
        end

    end

    LogAnalytics[(Espace de travail Log Analytics)]

    %% Flux Publics
    Client -->|1. HTTP :80 - Redirection 301| AppGW
    Client -->|2. HTTPS :443 - Requête GET /| AppGW
    Client -->|3. HTTPS :443 - Requête GET /api/*| AppGW

    %% Routage AppGW
    AppGW -->|Chemin /* -> Pool A| VMSS_A
    AppGW -->|Chemin /api/* -> Pool B| VMSS_B

    %% Flux Privés & Administration
    Jumpbox -->|Accès Privé HTTP : 10.0.1.10| AppGW
    Jumpbox -.->|Rebond SSH Interne :80/22| VMSS_A

    %% Logs & WAF
    AppGW -.->|Journaux WAF & Diagnostic| LogAnalytics
```

---

## 📦 Ressources Déployées

* **Réseau & Sécurité :**
  * **1 Virtual Network (VNet) :** `10.0.0.0/16`
  * **4 Sous-réseaux dédiés :** `subnet-appgw` (`10.0.1.0/24`), `subnet-backend-a` (`10.0.2.0/24`), `subnet-backend-b` (`10.0.3.0/24`), `subnet-mgmt` (`10.0.4.0/24`)
  * **4 Network Security Groups (NSG) :** isolation stricte inter‑subnets ; les VMSS et la Jumpbox n'ont aucun accès direct à Internet (Zero‑Trust Egress).
* **Ingress & WAF :**
  * **1 Application Gateway v2 (WAF), 2 instances :** IP publique Standard + IP privée (`10.0.1.10`), certificat SSL/TLS PFX, moteur WAF OWASP CRS 3.2.
  * **Règles de routage :** redirection HTTP (port 80) vers HTTPS (port 443) et routage basé sur le chemin (`/` et `/api/*`).
* **Calcul & Backend :**
  * **2 VM Scale Sets (VMSS) :** instances Ubuntu sans IP publique, bootstrap `cloud-init` (serveurs Web & API), autoscale 1–2 instances par VMSS.
  * **1 VM Jumpbox :** instance d'administration privée dans `subnet-mgmt` (accès console série / diagnostic).
* **Supervision & Observabilité :**
  * **1 Espace de travail Log Analytics :** collecte centralisée des journaux d'accès AppGW, des événements WAF (OWASP), des métriques VMSS et (optionnellement) des NSG Flow Logs.
