# Docker Deployment Research for ASP.NET Core 7.0 on Ubuntu

## 1. Official Microsoft Base Images

Microsoft provides two primary images for .NET 7.0:

**SDK Image (Build Stage):**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
```

**Runtime Image (Production):**
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
```

Key features:
- Ubuntu Jammy (22.04) based
- Optimized for containerized environments
- Security patches and updates
- .NET 7.0.x runtime with ASP.NET Core hosting

## 2. Multi-Stage Dockerfile Pattern

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /source
COPY *.sln . COPY *.csproj ./
RUN dotnet restore
COPY . .
WORKDIR /src
RUN dotnet publish -c release -o /app --no-restore

# Final stage
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS final
WORKDIR /app
COPY --from=build /app ./
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

Benefits:
- Small final image size
- Secure (no SDK tools in production)
- Built-in caching optimization
- Cleaner separation of concerns

## 3. Docker Compose for Local Development

```yaml
version: '3.8'
services:
  webapp:
    image: your-app:dev
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "5001:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    volumes:
      - .:/app
      - /app/bin:/app/bin
      - /app/obj:/app/obj
```

Hot Reload Setup:
```csharp
// Startup.cs
if (Env.IsDevelopment)
{
    mvcBuilder.AddRazorRuntimeCompilation();
}
```

**Requirements:**
- Visual Studio 17.10+ for container hot reload
- Refresh browser to see changes
- CSS isolation requires page refresh

## 4. Environment Variable Management

Configuration hierarchy:
1. appsettings.json
2. appsettings.{Environment}.json
3. User Secrets (Development only)
4. Environment Variables
5. Command-line arguments

**Docker Environment Variables:**
```dockerfile
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ConnectionStrings__Default="Server=db;User=sa;Password=yourStrong(!)Password"
```

**docker-compose.yml:**
```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Production
  - ConnectionStrings__Default=Server=db;User=sa;Password=yourStrong(!)Password
```

Security Best Practices:
- Never store secrets in appsettings.json
- Use environment variables for sensitive data
- Consider Azure Key Vault for production

## 5. HTTPS and Port Binding

**HTTPS Configuration:**
```yaml
ports:
  - "80:80"
  - "443:443"
environment:
  - ASPNETCORE_URLS=https://+:443;http://+:80
  - ASPNETCORE_Kestrel__Certificates__Default__Password=password
  - ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx
volumes:
  - ./https:/https
```

Port Binding:
- HTTP: 80 container port mapped to host
- HTTPS: 443 container port mapped to host
- Use `--publish` flag in Docker CLI

## 6. Volume Mounts

For persistent data:
```yaml
volumes:
  - ./data:/app/data
  - ./logs:/app/logs
```

Use cases:
- File uploads
- Log aggregation
- Temporary file storage
- Database data (for development)

## 7. Health Checks

**ASP.NET Core Setup:**
```csharp
services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database")
    .AddCheck<CacheHealthCheck>("cache");

app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");
```

**Docker Compose:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:80/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**Kubernetes Probes:**
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Sources

- [ASP.NET Core Docker Deployment Guide](https://learn.microsoft.com/zh-cn/aspnet/core/security/docker-compose-https?view=aspnetcore-6.0)
- [Microsoft .NET 7.0 Docker Images](https://hub.docker.com/_/microsoft-dotnet)
- [Docker Compose Hot Reload](https://learn.microsoft.com/en-us/visualstudio/docker/tutorials/hot-reload)
- [ASP.NET Core Configuration](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration)
- [Docker Health Checks](https://docs.docker.com/engine/reference/builder/#healthcheck)