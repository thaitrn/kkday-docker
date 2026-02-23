# Planner Report: Docker Deployment on Ubuntu

**Date**: 2026-02-21
**Plan**: `260221-2138-docker-deployment-ubuntu`
**Status**: Complete

## Summary

Created comprehensive implementation plan for containerizing KKday B2D InternAgent (ASP.NET Core 7.0 MVC) with Docker for Ubuntu deployment.

## Critical Decisions

### .NET Version
- **Current**: .NET 7.0 (EOL since May 2024)
- **Recommendation**: Upgrade to .NET 8.0 LTS before production deployment
- **Plan approach**: Implement with .NET 7.0 for compatibility, document upgrade path

### Certificate Validation
- **Current issue**: All Proxy classes bypass SSL validation (`ServerCertificateCustomValidationCallback = true`)
- **Fix**: Environment-gated SSL validation (disabled only in Development)
- **Scope**: Modify 6 Proxy classes + add configuration option

### Locale Support
- **Required**: zh-TW, en-US
- **Solution**: Install locales in Docker via `locale-gen`
- **Environment vars**: `LANG=C.UTF-8`, `LC_ALL=C.UTF-8`

## Files Created

```
plans/260221-2138-docker-deployment-ubuntu/
├── plan.md                              # Overview
├── phase-01-create-dockerfile.md        # Multi-stage Dockerfile
├── phase-02-docker-compose-dev.md       # Local dev with hot reload
├── phase-03-environment-config.md       # Config & secrets management
├── phase-04-health-checks.md            # Health endpoints
└── phase-05-deployment-guide.md         # Full deployment guide
```

## Effort Estimate

| Phase | Estimated Time |
|-------|----------------|
| 01 - Dockerfile | 1.5h |
| 02 - Docker Compose Dev | 1h |
| 03 - Environment Config | 2h (includes SSL fix) |
| 04 - Health Checks | 1h |
| 05 - Deployment Guide | 0.5h (documentation) |
| **Testing** | 2h |
| **Total** | **8h** |

## Architecture Overview

```
┌───────────────────────────────────────────────────────┐
│                    Docker Image                       │
│  Base: mcr.microsoft.com/dotnet/aspnet:7.0            │
│  - Locales: zh-TW, en-US                              │
│  - Ports: 80, 443                                     │
│  - Health: /health/live, /health/ready                │
└───────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────┐
│                 Development Stack                     │
│  - Dockerfile.dev (SDK image)                         │
│  - Volume mounts for hot reload                       │
│  - docker-compose.dev.yml override                    │
└───────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────┐
│                Production Stack                       │
│  - Multi-stage build (minimal image)                  │
│  - Environment variable configuration                 │
│  - Reverse proxy (Caddy/Nginx) for HTTPS              │
│  - Blue-green deployment strategy                     │
└───────────────────────────────────────────────────────┘
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `ASPNETCORE_ENVIRONMENT` | Environment | Production |
| `KKdayApi__Url` | API base URL | - |
| `KKdayApi__AuthorToken` | Bearer token | - |
| `Currency` | Default currency | TWD |
| `Marketing` | Marketing code | TW |
| `AesCryptoKey` | Encryption key | - |
| `DisableSSLValidation` | SSL bypass | false (dev only) |

## Security Improvements

1. **Certificate Validation**: Fix SSL bypass, make it environment-gated
2. **Secrets Management**: Use environment variables, never commit to git
3. **Minimal Images**: Multi-stage build, no SDK in production
4. **Non-root User**: Optional, may require permission changes
5. **Health Endpoints**: Public but no sensitive data exposed

## Unresolved Questions

1. **Container Registry**: Which registry for production? (ACR, GHCR, Harbor)
2. **Monitoring Stack**: Prometheus/Grafana or cloud-native?
3. **Backup Strategy**: What data needs backing up?
4. **.NET 8.0 Timeline**: When to schedule the upgrade?

## Next Steps

1. Execute Phase 01 - Create Dockerfile
2. Test local build and run
3. Implement Phase 03 SSL validation fixes
4. Schedule .NET 8.0 upgrade planning
5. Set up CI/CD pipeline for automated builds

## References

- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/`
- Plan: `plans/260221-2138-docker-deployment-ubuntu/`
- Research 1: `reports/researcher-01-docker-aspnetcore.md`
- Research 2: `research/researcher-02-ubuntu-dotnet.md`
