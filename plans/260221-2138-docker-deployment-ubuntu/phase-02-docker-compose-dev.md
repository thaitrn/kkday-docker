# Phase 02: Docker Compose for Local Development

## Context Links
- Research: [Docker ASP.NET Core](../260221-2133-docker-deployment/reports/researcher-01-docker-aspnetcore.md#3-docker-compose-for-local-development)
- Depends on: [Phase 01](./phase-01-create-dockerfile.md)
- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/`

## Overview
**Date**: 2026-02-21
**Priority**: P2
**Status**: completed

Enable rapid local development with hot reload using Docker Compose.

## Key Insights
- ASP.NET Core 7.0 includes `AddRazorRuntimeCompilation()` for hot reload
- Volume mounts sync code changes into container
- Already using `Microsoft.AspNetCore.Mvc.Razor.RuntimeCompilation` package
- Browser refresh required to see changes (not automatic)

## Requirements
**Functional:**
- Start dev environment with single command
- Hot reload for Razor views and C# code
- Environment variables from .env file
- HTTPS support with dev certificates

**Non-Functional:**
- Startup time < 10 seconds
- Simple onboarding for new developers

## Architecture

```
┌─────────────────────────────────────────────────────┐
│               docker-compose.yml                     │
│  Service: webapp                                     │
│  - Build context: .                                  │
│  - Ports: 5000:80, 5001:443                         │
│  - Volumes: .:/app (code sync)                       │
│  - Environment: Development                          │
└─────────────────────────────────────────────────────┘
```

## Related Code Files
**Create:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/docker-compose.yml`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/docker-compose.dev.yml`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/.env.example`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/Dockerfile.dev`

**Read Reference:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/Program.cs`
  - Already has runtime compilation configured

## Implementation Steps

1. **Create Dockerfile.dev** (development variant)
   - Use SDK image (not runtime) for hot reload
   - Include dotnet watch tools
   - Mount-friendly structure

2. **Create docker-compose.yml** (base configuration)
   ```yaml
   version: '3.8'
   services:
     webapp:
       build:
         context: .
         dockerfile: Dockerfile
       ports:
         - "5000:80"
         - "5001:443"
       environment:
         - ASPNETCORE_ENVIRONMENT=Production
         - ASPNETCORE_URLS=http://+:80;https://+:443
   ```

3. **Create docker-compose.dev.yml** (development override)
   ```yaml
   version: '3.8'
   services:
     webapp:
       build:
         context: .
         dockerfile: Dockerfile.dev
       environment:
         - ASPNETCORE_ENVIRONMENT=Development
       volumes:
         - ./KKday.B2D.Web.InternAgent:/app
         - /app/bin
         - /app/obj
   ```

4. **Create .env.example** with template variables
   ```
   KKDAY_API_URL=https://api-b2d-10.sit.kkday.com/v4
   KKDAY_API_TOKEN=your_token_here
   CURRENCY=TWD
   MARKETING=TW
   AES_CRYPTO_KEY=7638792F423F4528482B4D6251655468
   ```

5. **Update .dockerignore** to exclude build artifacts

## Todo List
- [ ] Create Dockerfile.dev
- [ ] Create docker-compose.yml
- [ ] Create docker-compose.dev.yml
- [ ] Create .env.example
- [ ] Test: `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`
- [ ] Verify hot reload by editing Razor view
- [ ] Document usage in README

## Success Criteria
- `docker-compose up` starts in < 10s
- Editing .cshtml file + browser refresh shows changes
- Environment variables load from .env file
- HTTPS works on port 5001

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Hot reload not working | Medium | Verify runtime compilation package installed |
| Volume permission issues | Low | Use compatible UID/GID |
| Port conflicts | Low | Document port usage (5000/5001) |

## Security Considerations
- Development configuration only
- Never commit .env file with real tokens
- Use SIT environment API tokens only
- Document that dev certificates are self-signed

## Next Steps
- Complete Phase 03: Environment configuration management
- Ensure .env format matches production expectations
