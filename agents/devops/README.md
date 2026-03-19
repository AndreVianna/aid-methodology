# DevOps

**Specialist Agent — invoked ad-hoc**

The DevOps specialist handles CI/CD pipelines, infrastructure-as-code, containerization, monitoring setup, and deployment strategies. It is called when the pipeline needs infrastructure expertise.

## What It Does

The DevOps agent configures build pipelines, writes Dockerfiles, sets up monitoring and alerting, manages infrastructure-as-code (Terraform, Pulumi, CloudFormation), and designs deployment strategies (blue-green, canary, rolling). It has full write access because it manages infrastructure files that are part of the project.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Operator** | During Deploy — when deployment infrastructure needs configuration |
| **Researcher** | During Discover — when analyzing existing infrastructure |
| **Orchestrator** | When any phase needs infrastructure expertise |

This agent is not part of the standard pipeline flow. It is called on demand when infrastructure work is needed.

## What It Produces

- **CI/CD pipeline configurations** — GitHub Actions, GitLab CI, Jenkins, etc.
- **Dockerfiles and compose files** — containerization setup
- **Infrastructure-as-code** — Terraform, Pulumi, CloudFormation scripts
- **Monitoring configuration** — alerting rules, dashboards, log aggregation setup
- **Deployment strategy documents** — rollout plans, rollback procedures

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Operator** | Operator *uses* infrastructure to ship. DevOps *builds* the infrastructure. |
| **Developer** | Developer writes application code. DevOps writes infrastructure code. |
| **Researcher** | Researcher discovers existing infra. DevOps improves or creates it. |

## Tools

- **Read, Glob, Grep** — analyzing existing infrastructure
- **Write, Edit** — creating and modifying infrastructure files
- **Bash** — full access for infrastructure commands, validation, testing

## Model

**Sonnet** — infrastructure work is pattern-based and procedural, leveraging known configurations rather than novel reasoning.

## Examples

- *"Set up a CI/CD pipeline for this project."* → Creates GitHub Actions workflow with build, test, deploy stages
- *"We need Docker support."* → Creates Dockerfile, docker-compose.yml, .dockerignore
- *"The deployment keeps failing."* → Investigates pipeline, fixes configuration issues
- *"Set up monitoring for the new service."* → Configures alerting rules and dashboard definitions
