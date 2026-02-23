# Phase 03: Environment Configuration Management

## Context Links
- Research: [Docker ASP.NET Core](../260221-2133-docker-deployment/reports/researcher-01-docker-aspnetcore.md#4-environment-variable-management)
- Project: `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/`

## Overview
**Date**: 2026-02-21
**Priority**: P1
**Status**: completed

Securely manage configuration across environments using Docker environment variables and secrets.

## Key Insights
- ASP.NET Core configuration hierarchy: appsettings.json -> appsettings.{Environment}.json -> Environment Variables
- Nested JSON values map via `__` double underscore (e.g., `KKdayApi__Url`)
- Current code has certificate validation bypass - should be fixed with proper cert handling
- Sensitive data must never be committed to git

## Requirements
**Functional:**
- Support Development, Staging, Production environments
- Override appsettings via environment variables
- Secure handling of API tokens
- AES encryption key configuration

**Non-Functional:**
- No secrets in git repository
- Clear documentation of all config variables
- Validation of required settings at startup

## Architecture

```
Configuration Priority (highest first):
┌───────────────────────────────────────────────────────────┐
│  1. Docker run -e / docker-compose environment            │
│  2. appsettings.Production.json                           │
│  3. appsettings.json                                      │
└───────────────────────────────────────────────────────────┘

Environment Variable Mapping:
KKdayApi__Url  →  appsettings.json.KKdayApi.Url
```

## Related Code Files
**Read:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/appsettings.json.template`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/Program.cs`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/AppCode/Website.cs`

**Create:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/appsettings.Production.json`
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/appsettings.Development.json`

## Implementation Steps

1. **Create appsettings.Development.json**
   - Enable detailed logging
   - Set SIT API URL
   - Document required environment variables

2. **Create appsettings.Production.json**
   - Minimal logging (Warning/Error only)
   - Enable HSTS
   - No hardcoded URLs

3. **Document environment variable mappings**

   | Environment Variable | JSON Path | Description |
   |---------------------|-----------|-------------|
   | `KKdayApi__Url` | KKdayApi:Url | API base URL |
   | `KKdayApi__AuthorToken` | KKdayApi:AuthorToken | Bearer token |
   | `Currency` | Currency | Default currency (TWD) |
   | `Marketing` | Marketing | Marketing code (TW) |
   | `AesCryptoKey` | AesCryptoKey | Encryption key |
   | `ASPNETCORE_ENVIRONMENT` | - | Environment name |
   | `ASPNETCORE_URLS` | - | Bind URLs |

4. **Fix certificate validation issue**
   - Create configuration option for SSL validation
   - Default to `true` (validate certificates)
   - Allow `false` only for Development environment
   - Modify all Proxy classes:
     - `SearchProxy.cs`
     - `ProductProxy.cs`
     - `OrderProxy.cs`
     - `BookingProxy.cs`
     - `CommonProxy.cs`
     - `VoucherProxy.cs`

## Todo List
- [ ] Create appsettings.Development.json
- [ ] Create appsettings.Production.json
- [ ] Document environment variables in this file
- [ ] Add SSL validation configuration option
- [ ] Update all Proxy classes with conditional SSL validation
- [ ] Test environment variable overrides
- [ ] Add startup validation for required settings

## Success Criteria
- Environment variables override appsettings values
- SSL validation enabled in production
- SSL validation can be disabled for development only
- Missing required settings causes clear error at startup

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Hardcoded tokens in git | Critical | Use .env.example, git-secrets |
| SSL bypass in production | Critical | Environment-gated validation |
| Missing settings | Medium | Startup validation |

## Security Considerations
- **CRITICAL**: Remove all certificate validation bypasses from production code
- Implement environment-aware SSL validation
- Use Docker secrets or external vault for production
- Rotate API tokens regularly
- Add .env to .gitignore

## Code Changes Required

### SSL Validation Fix Pattern (apply to all Proxies):

```csharp
// In Website.cs or configuration
public static bool DisableSSLValidation {
    get => bool.Parse(Website.Instance.GetConfig("DisableSSLValidation", "false"));
}

// In each Proxy.cs
using (var handler = new HttpClientHandler())
{
    // Only disable SSL in Development
    if (builder.Environment.IsDevelopment() && Website.DisableSSLValidation)
    {
        handler.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;
    }
    // ...
}
```

## Next Steps
- Complete Phase 04: Health check endpoints
- Update .gitignore for .env files
