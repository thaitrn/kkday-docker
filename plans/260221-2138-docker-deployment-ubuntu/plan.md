---
title: "Docker Deployment on Ubuntu for KKday B2D InternAgent"
description: "Containerize ASP.NET Core 7.0 MVC app with Docker for Ubuntu deployment, addressing .NET 7.0 EOL and security issues"
status: completed
priority: P2
effort: 8h
branch: master
tags: [docker, ubuntu, deployment, aspnetcore]
created: 2026-02-21
---

## Overview
Containerize KKday B2D InternAgent (ASP.NET Core 7.0 MVC) for production deployment on Ubuntu with Docker.

## Critical Considerations
- **.NET 7.0 is EOL** (May 2024) - plan includes migration path to .NET 8.0 LTS
- **Certificate validation bypass** - will be fixed during implementation
- **Locale support** - zh-TW and en-US require proper container configuration

## Phases

| Phase | Status | Description |
|-------|--------|-------------|
| [01 - Dockerfile](./phase-01-create-dockerfile.md) | completed | Multi-stage build for .NET 7.0/8.0 |
| [02 - Docker Compose Dev](./phase-02-docker-compose-dev.md) | completed | Local development with hot reload |
| [03 - Environment Config](./phase-03-environment-config.md) | completed | Secrets management and appsettings |
| [04 - Health Checks](./phase-04-health-checks.md) | completed | Liveness and readiness endpoints |
| [05 - Deployment Guide](./phase-05-deployment-guide.md) | completed | Build, run, and production deployment |

## Key Dependencies
- Phase 01 must be completed before other phases (base Docker image required)
- Phase 03 must align with Phase 01 (environment variable naming)

## Success Criteria
- Container builds and runs on Ubuntu 22.04/24.04
- Hot reload works in development
- Environment variables override appsettings correctly
- Health endpoints respond properly
- Production deployment documented
