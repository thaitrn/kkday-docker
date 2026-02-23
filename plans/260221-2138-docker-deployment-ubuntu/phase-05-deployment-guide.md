# Phase 05: Deployment Guide

## Context Links
- All previous phases required
- Research: [Ubuntu .NET](../260221-2133-docker-deployment/research/researcher-02-ubuntu-dotnet.md)
- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/`

## Overview
**Date**: 2026-02-21
**Priority**: P1
**Status**: completed

Complete guide for building, running, and deploying KKday B2D InternAgent with Docker on Ubuntu.

## Key Insights
- Ubuntu 22.04 LTS (Jammy) or 24.04 LTS (Noble) recommended
- .NET 7.0 EOL - recommend .NET 8.0 LTS upgrade before production
- Bridge mode for security, host mode for performance
- Resource baseline: 100m CPU, 175MiB memory

## Requirements
**Functional:**
- Build images locally
- Run containers in development and production
- Deploy to Ubuntu server
- Handle SSL/TLS certificates
- Container update/rollback strategy

**Non-Functional:**
- Zero-downtime deployments (optional - using blue/green)
- Monitoring and logging
- Backup and restore procedures

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Deployment Options                     │
│                                                          │
│  Development:                                           │
│    docker-compose up                                    │
│                                                          │
│  Production (Ubuntu):                                   │
│    Docker + Reverse Proxy (Nginx/Caddy)                 │
│    or Docker Swarm                                      │
│    or Kubernetes (future)                               │
└─────────────────────────────────────────────────────────┘
```

## Related Code Files
**Create:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/deploy/build.sh`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/deploy/run.sh`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/deploy/docker-compose.prod.yml`

**Document:**
- This guide in `/docs/deployment-guide.md`

## Implementation Steps

### 1. Prerequisites

**On Ubuntu 22.04/24.04:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Build Image

```bash
# Clone repository
git clone <repo-url>
cd kkday-b2d-internagent

# Build image
docker build -t kkday-b2d-internagent:latest .

# Tag for versioning
docker tag kkday-b2d-internagent:latest kkday-b2d-internagent:v1.0.0
```

### 3. Development Run

```bash
# Copy and configure environment
cp .env.example .env
nano .env  # Edit your values

# Start with hot reload
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### 4. Production Run

```bash
# Create production environment file
cp .env.example .env.production
nano .env.production  # Set production values

# Start production container
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 5. SSL/TLS Setup

**Option A: Reverse Proxy (Recommended)**
```bash
# Use Caddy for automatic HTTPS
# deploy/Caddyfile:
kkday.example.com {
    reverse_proxy localhost:5000
}
```

**Option B: Self-signed certificates**
```bash
# Generate certificate
dotnet dev-certs https -ep /app/https/aspnetapp.pfx -p <password>
```

### 6. Deployment Scripts

**deploy/build.sh:**
```bash
#!/bin/bash
set -e
VERSION=${1:-latest}
docker build -t kkday-b2d-internagent:$VERSION .
docker tag kkday-b2d-internagent:$VERSION kkday-b2d-internagent:latest
```

**deploy/run.sh:**
```bash
#!/bin/bash
set -e
docker run -d \
  --name kkday-b2d \
  --restart unless-stopped \
  -p 5000:80 \
  --env-file .env.production \
  --health-cmd="curl -f http://localhost/health/live || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  kkday-b2d-internagent:latest
```

### 7. Update Strategy

```bash
# Pull new code
git pull

# Build new image
./deploy/build.sh v1.0.1

# Blue-green deployment
docker run -d --name kkday-b2d-new --env-file .env.production -p 5001:80 kkday-b2d-internagent:v1.0.1

# Test new version
curl http://localhost:5001/health/live

# Switch traffic
docker stop kkday-b2d
docker rename kkday-b2d kkday-b2d-old
docker rename kkday-b2d-new kkday-b2d
docker start kkday-b2d

# Cleanup if successful
docker rm kkday-b2d-old
```

## Todo List
- [ ] Create deploy/build.sh script
- [ ] Create deploy/run.sh script
- [ ] Create docker-compose.prod.yml
- [ ] Document reverse proxy setup
- [ ] Add monitoring/logging configuration
- [ ] Create backup/restore procedures
- [ ] Document .NET 8.0 upgrade path

## Success Criteria
- Single command deploys application
- Zero-downtime updates possible
- Health checks verify deployment
- Logs accessible for troubleshooting
- SSL/TLS properly configured

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| .NET 7.0 EOL | High | Plan .NET 8.0 upgrade |
| SSL misconfiguration | High | Use reverse proxy |
| Resource exhaustion | Medium | Set memory limits |
| Deployment failures | Medium | Blue-green strategy |

## Security Considerations

### Production Checklist
- [ ] Use .NET 8.0 LTS (not .NET 7.0 EOL)
- [ ] Enable SSL validation (no bypass)
- [ ] Use secrets manager for tokens
- [ ] Set resource limits
- [ ] Enable audit logging
- [ ] Regular security scans
- [ ] Keep base images updated

### Resource Limits
```yaml
deployments:
  resources:
    requests:
      memory: "175Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

## Monitoring

```bash
# View container stats
docker stats kkday-b2d

# View logs
docker logs -f kkday-b2d

# Health status
docker inspect --format='{{.State.Health.Status}}' kkday-b2d
```

## .NET 8.0 Upgrade Path

1. Update `.csproj`: `<TargetFramework>net8.0</TargetFramework>`
2. Update package versions to 8.0.x
3. Update Dockerfile base images:
   - `mcr.microsoft.com/dotnet/sdk:8.0`
   - `mcr.microsoft.com/dotnet/aspnet:8.0`
4. Test all functionality
5. Deploy to staging first

## Unresolved Questions
1. What container registry will be used? (ACR, GHCR, Harbor?)
2. What monitoring stack? (Prometheus, Grafana, Azure Monitor?)
3. Backup strategy for application data?
4. Disaster recovery procedures?

## Next Steps
- Execute Phase 01 to create Dockerfile
- Test local build before production deployment
- Schedule .NET 8.0 upgrade planning
