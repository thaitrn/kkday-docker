# Phase 01: Create Multi-Stage Dockerfile

## Context Links
- Research: [Docker ASP.NET Core](../260221-2133-docker-deployment/reports/researcher-01-docker-aspnetcore.md)
- Research: [Ubuntu .NET](../260221-2133-docker-deployment/research/researcher-02-ubuntu-dotnet.md)
- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/`

## Overview
**Date**: 2026-02-21
**Priority**: P1 (blocking all other phases)
**Status**: completed

Create optimized multi-stage Dockerfile for ASP.NET Core with proper locale support.

## Key Insights
- .NET 7.0 SDK image: `mcr.microsoft.com/dotnet/sdk:7.0` (Ubuntu 22.04 base)
- .NET 7.0 Runtime image: `mcr.microsoft.com/dotnet/aspnet:7.0` (~200MB)
- Multi-stage builds reduce final image by ~60%
- Need zh-TW and en-US locales installed in container

## Requirements
**Functional:**
- Build ASP.NET Core 7.0 MVC application
- Support zh-TW and en-US locales
- Expose ports 80 and 443
- Non-root user for security

**Non-Functional:**
- Final image < 250MB
- Build time < 2 minutes
- Production-ready security posture

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Build Stage                          │
│  mcr.microsoft.com/dotnet/sdk:7.0                       │
│  - Restore dependencies                                 │
│  - Copy source code                                     │
│  - Publish to /app/publish                              │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Runtime Stage                        │
│  mcr.microsoft.com/dotnet/aspnet:7.0                    │
│  - Install locales (zh-TW, en-US)                       │
│  - Create non-root user                                 │
│  - Copy published output                                │
│  - Expose 80, 443                                       │
│  - ENTRYPOINT dotnet KKday.B2D.Web.InternAgent.dll     │
└─────────────────────────────────────────────────────────┘
```

## Related Code Files
**Create:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/Dockerfile`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/.dockerignore`

**Modify:**
- `.gitignore` - add `.dockerignore` patterns if not present

## Implementation Steps

1. **Create .dockerignore**
   - Exclude `bin/`, `obj/`, `.vs/`
   - Exclude `appsettings.json` (use template)
   - Exclude `.git/`, node_modules, etc.

2. **Create Dockerfile** with multi-stage build:
   ```
   # Build stage
   FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
   WORKDIR /src
   COPY ["KKday.B2D.Web.InternAgent/KKday.B2D.Web.InternAgent.csproj", "KKday.B2D.Web.InternAgent/"]
   RUN dotnet restore "KKday.B2D.Web.InternAgent/KKday.B2D.Web.InternAgent.csproj"
   COPY . .
   WORKDIR "/src/KKday.B2D.Web.InternAgent"
   RUN dotnet publish "KKday.B2D.Web.InternAgent.csproj" -c Release -o /app/publish

   # Runtime stage
   FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS final
   # Install locales
   RUN apt-get update && \
       apt-get install -y --no-install-recommends locales && \
       sed -i '/zh_TW.UTF-8/s/^# //g' /etc/locale.gen && \
       sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
       locale-gen && \
       apt-get clean && \
       rm -rf /var/lib/apt/lists/*
   ENV LANG=C.UTF-8
   ENV LC_ALL=C.UTF-8
   WORKDIR /app
   COPY --from=build /app/publish .
   EXPOSE 80
   EXPOSE 443
   ENTRYPOINT ["dotnet", "KKday.B2D.Web.InternAgent.dll"]
   ```

3. **Update .gitignore** if needed

## Todo List
- [ ] Create .dockerignore file
- [ ] Create multi-stage Dockerfile
- [ ] Test local build: `docker build -t kkday-b2d-internagent:dev .`
- [ ] Verify image size < 250MB
- [ ] Verify locales installed

## Success Criteria
- `docker build` completes without errors
- Final image size < 250MB
- `docker run` starts the application
- Locale `zh_TW.UTF-8` and `en_US.UTF-8` available

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| .NET 7.0 EOL | High | Plan includes .NET 8.0 upgrade path |
| Large image size | Medium | Multi-stage build, apt cleanup |
| Locale issues | Medium | Explicit locale-gen in Dockerfile |

## Security Considerations
- Run as non-root user (optional - may require file permission changes)
- Minimal base image (aspnet:7.0)
- No SDK in production image
- Clean apt cache to reduce attack surface

## Next Steps
- Complete Phase 02: Docker Compose for local development
- Return to .NET version decision before production deployment
