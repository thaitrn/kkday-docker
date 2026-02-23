# Phase 04: Health Check Endpoints

## Context Links
- Research: [Docker ASP.NET Core](../260221-2133-docker-deployment/reports/researcher-01-docker-aspnetcore.md#7-health-checks)
- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/`

## Overview
**Date**: 2026-02-21
**Priority**: P2
**Status**: completed

Implement health check endpoints for container orchestration and monitoring.

## Key Insights
- ASP.NET Core has built-in health check middleware
- Docker HEALTHCHECK directive depends on these endpoints
- Distinguish between liveness (app running) and readiness (can serve requests)
- KKday API connectivity check useful for readiness

## Requirements
**Functional:**
- `/health/live` - Basic liveness check (always 200 if app is running)
- `/health/ready` - Readiness check (validates external dependencies)
- Docker HEALTHCHECK integration
- Optionally check KKday API connectivity

**Non-Functional:**
- Response time < 100ms for liveness
- Response time < 2s for readiness
- No authentication required for health endpoints

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Health Check Flow                      │
│                                                          │
│  Docker/Orchestrator                                     │
│       │                                                  │
│       ▼                                                  │
│  /health/live  ──→  App running? ──→  200 OK            │
│       │                                                  │
│       ▼                                                  │
│  /health/ready ──→  KKday API reachable? ──→  200/503   │
└─────────────────────────────────────────────────────────┘
```

## Related Code Files
**Modify:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/Program.cs`
  - Add health check services
  - Map health endpoints

**Create:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/AppCode/KKdayApiHealthCheck.cs`
  - Custom health check for KKday API

**Modify:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/Dockerfile`
  - Add HEALTHCHECK directive

## Implementation Steps

1. **Add NuGet package** (if not already present)
   ```xml
   <PackageReference Include="Microsoft.AspNetCore.Diagnostics.HealthChecks" Version="7.0.*" />
   ```

2. **Create KKdayApiHealthCheck.cs**
   ```csharp
   using Microsoft.Extensions.Diagnostics.HealthChecks;

   public class KKdayApiHealthCheck : IHealthCheck
   {
       private readonly IConfiguration _config;
       private readonly ILogger<KKdayApiHealthCheck> _logger;

       public KKdayApiHealthCheck(IConfiguration config, ILogger<KKdayApiHealthCheck> logger)
       {
           _config = config;
           _logger = logger;
       }

       public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
       {
           try
           {
               var apiUrl = _config["KKdayApi:Url"];
               if (string.IsNullOrEmpty(apiUrl))
                   return HealthCheckResult.Unhealthy("KKday API URL not configured");

               // Simple HEAD request or timeout-limited GET
               using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
               var response = await client.GetAsync($"{apiUrl}/health", cancellationToken);

               return response.IsSuccessStatusCode
                   ? HealthCheckResult.Healthy("KKday API is reachable")
                   : HealthCheckResult.Degraded($"KKday API returned {response.StatusCode}");
           }
           catch (Exception ex)
           {
               return HealthCheckResult.Unhealthy($"KKday API check failed: {ex.Message}");
           }
       }
   }
   ```

3. **Update Program.cs**
   ```csharp
   // Add after other services
   builder.Services.AddHealthChecks()
       .AddCheck<KKdayApiHealthCheck>("kkday-api");

   // Add before app.Run()
   app.MapHealthChecks("/health/live", new HealthCheckOptions
   {
       Predicate = _ => false  // No checks, just liveness
   });

   app.MapHealthChecks("/health/ready");
   ```

4. **Update Dockerfile**
   ```dockerfile
   HEALTHCHECK CMD curl -f http://localhost:80/health/live || exit 1
   ```

5. **Update docker-compose.yml**
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:80/health/live"]
     interval: 30s
     timeout: 10s
     retries: 3
     start_period: 40s
   ```

## Todo List
- [ ] Add health checks NuGet package to .csproj
- [ ] Create KKdayApiHealthCheck.cs
- [ ] Update Program.cs with health check services and endpoints
- [ ] Update Dockerfile with HEALTHCHECK directive
- [ ] Update docker-compose.yml with healthcheck section
- [ ] Test endpoints manually with curl
- [ ] Verify docker health status

## Success Criteria
- `curl localhost:5000/health/live` returns 200
- `curl localhost:5000/health/ready` returns 200 when API is reachable
- Docker shows `healthy` status after startup
- Health checks complete within timeouts

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| KKday API slow response | Low | Short timeout (5s) |
| Health check loops | Low | Simple liveness check |
| Missing curl in image | Low | Use wget or install curl |

## Security Considerations
- Health endpoints should NOT require authentication (standard practice)
- Do not expose sensitive information in health responses
- Consider restricting access in production via network policies
- Rate limit health endpoints to prevent abuse

## Next Steps
- Complete Phase 05: Deployment guide
- Add health check visualization to monitoring setup
