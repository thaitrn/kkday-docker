# Docker Deployment Guide - KKday B2D InternAgent

Complete guide for deploying KKday B2D InternAgent with Docker on Ubuntu.

## Prerequisites

### On Ubuntu 22.04/24.04:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group change to take effect

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

## Environment Configuration

Create a production environment file:

```bash
cp .env.example .env.production
nano .env.production
```

Configure your production values:

```bash
# KKday API Configuration
KKdayApi__Url=https://api-b2d.kkday.com/v4
KKdayApi__AuthorToken=your_production_token_here

# Application Settings
Currency=TWD
Marketing=TW

# Security - NEVER set to "true" in Production!
DisableSSLValidation=false

# Encryption
AesCryptoKey=your_production_encryption_key_here
```

## Build Image

```bash
# Clone repository
git clone <repo-url>
cd kkday-b2d-internagent

# Build image using provided script
chmod +x deploy/build.sh
./deploy/build.sh latest

# Or build manually
docker build -t kkday-b2d-internagent:latest .
```

## Development Run

```bash
# Copy and configure environment
cp .env.example .env
nano .env  # Edit your values

# Start with hot reload
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# View logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
```

## Production Run

### Option A: Using docker-compose (Recommended)

```bash
# Create production environment file
cp .env.example .env.production
nano .env.production  # Set production values

# Start production container
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop container
docker-compose -f docker-compose.prod.yml down
```

### Option B: Using run script

```bash
# Make script executable
chmod +x deploy/run.sh

# Run container
./deploy/run.sh latest
```

### Option C: Manual docker run

```bash
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

## Health Checks

```bash
# Check liveness endpoint
curl http://localhost:5000/health/live

# Check readiness endpoint (includes KKday API connectivity)
curl http://localhost:5000/health/ready

# Check Docker health status
docker inspect --format='{{.State.Health.Status}}' kkday-b2d

# View container stats
docker stats kkday-b2d
```

## Update Strategy (Blue-Green Deployment)

```bash
# 1. Pull new code
git pull

# 2. Build new image version
./deploy/build.sh v1.0.1

# 3. Run new container on different port
docker run -d \
  --name kkday-b2d-new \
  --env-file .env.production \
  -p 5001:80 \
  kkday-b2d-internagent:v1.0.1

# 4. Test new version
curl http://localhost:5001/health/live

# 5. Switch traffic (stop old, rename new)
docker stop kkday-b2d
docker rename kkday-b2d kkday-b2d-old
docker rename kkday-b2d-new kkday-b2d
docker start kkday-b2d

# 6. If successful, cleanup old container
docker rm kkday-b2d-old
docker rmi kkday-b2d-internagent:old-version
```

## SSL/TLS Setup

### Option A: Reverse Proxy (Recommended)

Use Caddy or Nginx as a reverse proxy with automatic HTTPS.

**Caddyfile example:**
```
kkay.example.com {
    reverse_proxy localhost:5000
}
```

**Nginx config example:**
```nginx
server {
    listen 443 ssl http2;
    server_name kkday.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Option B: Self-signed certificates (Development only)

```bash
# Generate certificate
dotnet dev-certs https -ep /app/https/aspnetapp.pfx -p <password>
```

## Monitoring

```bash
# View logs
docker logs -f kkday-b2d

# Follow logs with timestamps
docker logs -f --timestamps kkday-b2d

# View last 100 lines
docker logs --tail 100 kkday-b2d

# Check container resource usage
docker stats kkday-b2d --no-stream

# Inspect container
docker inspect kkday-b2d
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs kkday-b2d

# Verify configuration
docker run --rm -it --env-file .env.production kkday-b2d-internagent:latest cat /app/appsettings.Production.json
```

### Health check failing

```bash
# Test health endpoint manually
docker exec kkday-b2d curl -f http://localhost/health/live

# Check if curl is installed
docker exec kkday-b2d which curl

# View health check history
docker inspect --format='{{json .State.Health}}' kkday-b2d | jq
```

### API connectivity issues

```bash
# Test API from within container
docker exec kkday-b2d curl -v https://api-b2d.kkday.com/v4

# Check environment variables
docker exec kkday-b2d env | grep KKday
```

## Security Checklist

Before deploying to production:

- [ ] Use .NET 8.0 LTS (not .NET 7.0 EOL) - see upgrade path below
- [ ] Enable SSL validation (DisableSSLValidation=false)
- [ ] Use secrets manager or vault for API tokens
- [ ] Set resource limits in docker-compose
- [ ] Enable audit logging
- [ ] Configure firewall rules
- [ ] Use HTTPS with valid certificates
- [ ] Regular security scans
- [ ] Keep base images updated

## .NET 8.0 Upgrade Path

.NET 7.0 reached End-of-Life in May 2024. Upgrade to .NET 8.0 LTS before production deployment.

### Steps:

1. **Update .csproj:**
   ```xml
   <TargetFramework>net8.0</TargetFramework>
   ```

2. **Update package versions to 8.0.x**

3. **Update Dockerfile base images:**
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
   FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
   ```

4. **Update Dockerfile.dev:**
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
   ```

5. **Test all functionality**

6. **Deploy to staging first**

## Backup and Restore

### Backup Application Data

```bash
# Backup any persisted data
docker run --rm \
  --volumes-from kkday-b2d \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/kkday-b2d-data-$(date +%Y%m%d).tar.gz /app/data
```

### Restore Application Data

```bash
docker run --rm \
  --volumes-from kkday-b2d \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/kkday-b2d-data-20240101.tar.gz -C /
```

## Port Reference

| Port | Usage | Internal |
|------|-------|----------|
| 5000 | HTTP | 80 |
| 5001 | HTTPS | 443 |

## Unresolved Questions

1. What container registry will be used? (ACR, GHCR, Harbor?)
2. What monitoring stack? (Prometheus, Grafana, Azure Monitor?)
3. Backup strategy for application data?
4. Disaster recovery procedures?

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [ASP.NET Core in Docker](https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/)
- [.NET 8.0 Upgrade Guide](https://docs.microsoft.com/en-us/dotnet/core/compatibility/8.0)
