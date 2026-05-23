# Infrastructure

> **Source:** aid-discover (Phase 1) + aid-interview (Phase 2)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Hosting

| Property | Value |
|----------|-------|
| **Cloud Provider** | {AWS / Azure / GCP / DigitalOcean / on-premise / hybrid} |
| **Deployment Model** | {Containers (Kubernetes) / Containers (ECS) / PaaS (App Service, Heroku) / VMs / serverless / other} |
| **Primary Region** | {e.g., us-east-1 / westeurope} |
| **Additional Regions** | {if any, for DR or latency} |

---

## Environments

| Environment | Purpose | URL / Endpoint | Infrastructure |
|-------------|---------|---------------|----------------|
| Development | {local dev / shared dev} | {localhost or URL} | {local / shared cloud} |
| Staging | {pre-production validation} | {URL} | {mirror of prod / simplified} |
| Production | {live} | {URL} | {full spec} |

**Promotion flow:** `Development → Staging → Production`

**Production access:** {who has access / how access is gated}

---

## Compute

| Component | Technology | Spec | Scaling |
|-----------|-----------|------|---------|
| {Web API} | {e.g., Azure App Service / ECS Fargate / Kubernetes pod} | {CPU/RAM} | {manual / auto-scale} |
| {Background Workers} | {e.g., Azure Functions / SQS consumer} | {CPU/RAM} | {n instances} |
| {Scheduled Jobs} | {e.g., Cron job / Azure Timer Function} | {CPU/RAM} | {single / distributed} |

---

## Data Infrastructure

| Component | Technology | Spec | Backup |
|-----------|-----------|------|--------|
| {Primary Database} | {PostgreSQL 16 / SQL Server / MongoDB} | {CPU/RAM/Storage} | {frequency + retention} |
| {Cache} | {Redis 7 / Memcached} | {RAM} | {persistence: yes/no} |
| {Message Queue} | {RabbitMQ / Kafka / SQS} | {spec} | {replication} |
| {Object Storage} | {S3 / Azure Blob / GCS} | {capacity} | {versioning / replication} |

---

## Networking

| Property | Value |
|----------|-------|
| **VPC / VNet** | {yes — services communicate privately / no — public endpoints} |
| **Load Balancer** | {ALB / Azure Application Gateway / nginx / none} |
| **CDN** | {CloudFront / Azure CDN / none} |
| **DNS** | {Route 53 / Azure DNS / other} |
| **TLS termination** | {load balancer / application / both} |
| **Internal service communication** | {service mesh / direct / API gateway} |

---

## Deployment Pipeline

| Stage | Tool | Trigger | Notes |
|-------|------|---------|-------|
| {Build} | {GitHub Actions / Azure DevOps / other} | {on PR / on push} | |
| {Test} | {same} | {on PR} | |
| {Deploy Staging} | {same} | {on merge to main} | {automatic} |
| {Deploy Production} | {same} | {manual approval / tag} | {requires sign-off} |

**Infrastructure-as-Code:** {Terraform / Bicep / CloudFormation / Pulumi / none — location}

**Container registry:** {Docker Hub / ECR / ACR / GCR — location}

---

## Monitoring & Observability

| Concern | Tool | Configuration |
|---------|------|---------------|
| {Application monitoring / APM} | {Datadog / New Relic / Application Insights / other} | {agent / SDK} |
| {Error tracking} | {Sentry / Rollbar / Bugsnag / other} | {DSN in env var} |
| {Logging} | {ELK / Splunk / CloudWatch / Seq / other} | {log shipper / SDK} |
| {Uptime monitoring} | {Pingdom / UptimeRobot / other} | {endpoints monitored} |
| {Alerting} | {PagerDuty / OpsGenie / Slack webhooks} | {escalation policy} |

---

## Disaster Recovery

| Property | Value |
|----------|-------|
| **RTO** | {target recovery time — e.g., 4 hours / not defined} |
| **RPO** | {target recovery point — e.g., 1 hour / not defined} |
| **Backup frequency** | {database: hourly / daily / other} |
| **Backup retention** | {n days} |
| **DR runbook** | {location or "not documented"} |

---

## Known Infrastructure Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| {e.g., No staging environment — testing directly against production data} | {High} | {risk description} |
| {e.g., Manual deployments — no CI/CD pipeline} | {Medium} | {deploy process description} |
| {e.g., Single AZ deployment — no redundancy} | {Medium} | {acceptable risk / plan to address} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover + aid-interview | Initial infrastructure mapping |
