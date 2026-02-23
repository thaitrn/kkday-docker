# Security Code Review: Docker Deployment & Health Checks

**Report Date:** 2026-02-21
**Review Type:** Security-focused analysis of PR changes
**Review Scope:** Docker deployment, health checks, SSL validation improvements
**Files Changed:** 27 files (Docker configurations, health checks, SSL validation logic)

## Executive Summary

This PR adds Docker deployment support and health check infrastructure to a .NET application. The changes include conditional SSL validation (an improvement over the previous always-disabled approach), health check endpoints, and containerization.

**Overall Security Assessment:** **MEDIUM RISK**

While the SSL validation changes are improvements, the PR introduces **2 HIGH-confidence security vulnerabilities** related to:
1. Unauthenticated health check endpoints exposing system information
2. Hardcoded weak encryption key in version-controlled files

---

## HIGH-CONFIDENCE VULNERABILITIES

### 1. Unauthenticated Health Check Endpoints Leak System Information

**File:** `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/Program.cs` (Lines 102-107)

**Severity:** HIGH

**Category:** `data_exposure`, `information_disclosure`

**Description:**
Health check endpoints `/health/live` and `/health/ready` are publicly accessible without any authentication or authorization. The `/health/ready` endpoint returns detailed health status including:

- KKday API reachability status
- API connection errors
- API response status codes
- Timeout information
- Configuration state (e.g., "KKday API URL not configured")

This reveals internal infrastructure topology and can be used for reconnaissance.

**Exploit Scenario:**
```bash
# Attacker discovers internal API endpoint details
curl https://target.com/health/ready

# Response reveals:
{
  "status": "Unhealthy",
  "totalDuration": "00:00:05.2345678",
  "entries": {
    "kkday-api": {
      "data": "KKday API is unreachable: Connection refused",
      "duration": "00:00:05.1234567"
    }
  }
}
```

An attacker can:
1. Map internal service dependencies
2. Identify API endpoint patterns (api-b2d-10.sit.kkday.com)
3. Detect when backend services are degraded
4. Use timing analysis to probe internal network topology

**Confidence Score:** 9/10 (Health check responses are documented in ASP.NET Core and will expose this information)

**Fix Recommendation:**
```csharp
// Option 1: Require authentication for health endpoints
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false,
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync("{"status":"healthy"}");
    }
});

// Option 2: Restrict to localhost/internal network only
app.MapHealthChecks("/health/ready").RequireHost("localhost", "127.0.0.1");

// Option 3: Add API key protection
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = (check) =>
    {
        var httpContext = check.HttpContext;
        var authHeader = httpContext.Request.Headers["Authorization"].FirstOrDefault();
        return authHeader == "Bearer YOUR_HEALTH_CHECK_SECRET";
    }
});
```

---

### 2. Hardcoded Encryption Key in Version-Controlled Files

**Files:**
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/.env.example` (Line 19)
- `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/appsettings.Development.json` (Line 11)

**Severity:** HIGH

**Category:** `hardcoded_secrets`, `crypto_weak_key`

**Description:**
The AES encryption key `7638792F423F4528482B4D6251655468` is hardcoded in multiple files that are committed to version control. This key appears to be a hexadecimal string used by `AesCryptHelper` for encryption/decryption operations.

**Key Security Issues:**
1. **Hardcoded in version control:** The key is now permanently in git history
2. **Used in development config:** Even if "just an example", developers may use it
3. **Static across deployments:** All development instances share the same key
4. **Insufficient entropy:** 32 hex chars = 16 bytes (128-bit), which is acceptable for AES-128, but the key value itself appears to be ASCII text converted to hex

**Exploit Scenario:**
```csharp
// If this key is used to encrypt sensitive data (tokens, PII, etc.),
// an attacker who can access the git repository can decrypt the data:

var encryptedData = "base64_encrypted_string_from_database";
var stolenKey = "7638792F423F4528482B4D6251655468";
var decrypted = AesCryptHelper.aesDecryptBase64(encryptedData, stolenKey);
```

Even if this is "just" for development:
- Developers may copy this pattern to production
- Database backups encrypted with this key are now compromised
- Any encrypted test data in repositories can be decrypted

**Confidence Score:** 8/10 (The code in `AesCryptHelper.cs` clearly uses this key for actual encryption/decryption operations)

**Fix Recommendation:**
```bash
# 1. Immediately rotate the key
# 2. Remove from .env.example and use a placeholder
sed -i 's/AesCryptoKey=.*/AesCryptoKey=CHANGE_THIS_TO_A_RANDOM_32_CHAR_KEY/' .env.example

# 3. Remove from appsettings.Development.json
# Replace with empty string or instructions to use environment variable

# 4. Update code to require key at runtime:
public class AesCryptHelper
{
    private static string GetCryptoKey()
    {
        var key = Environment.GetEnvironmentVariable("AesCryptoKey");
        if (string.IsNullOrEmpty(key) || key == "CHANGE_THIS_TO_A_RANDOM_32_CHAR_KEY")
        {
            throw new SecurityException("AesCryptoKey must be set to a secure value");
        }
        return key;
    }
}
```

**Additional Recommendations:**
- Add to `.gitignore` any files containing real keys
- Use `dotnet user-secrets` for development
- Use Azure Key Vault / AWS Secrets Manager for production
- Generate cryptographically random keys: `openssl rand -hex 32`

---

## MEDIUM-CONFIDENCE VULNERABILITIES

### 3. Configuration API URL Exposure in Health Check

**File:** `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/AppCode/KKdayApiHealthCheck.cs` (Line 39)

**Severity:** MEDIUM

**Category:** `data_exposure`

**Description:**
The health check returns the actual KKday API URL in error messages, potentially exposing internal service architecture.

**Exploit Scenario:**
```bash
# When API is unreachable, health check returns:
# "KKday API is reachable (status: 200)"
# or "KKday API unreachable: https://api-b2d-10.sit.kkday.com/v4"
```

**Confidence Score:** 7/10 (Confirmed by code review)

**Fix Recommendation:**
```csharp
// Line 39 - Don't expose internal URLs
return HealthCheckResult.Healthy("KKday API is reachable");

// Line 44 - Sanitize error messages
return HealthCheckResult.Unhealthy("KKday API is unreachable");
```

---

## LOW-CONFIDENCE / OBSERVATIONS

### 4. Development SSL Validation Control (NOT A VULNERABILITY)

**Files:** Multiple Proxy files, `Website.cs`

**Assessment:** This is an **IMPROVEMENT**, not a vulnerability. The PR correctly changes SSL validation from "always disabled" to "conditional on development environment only."

Previous code (vulnerable):
```csharp
handler.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;
```

New code (improved):
```csharp
if (Website.Instance.ShouldDisableSSLValidation())
{
    handler.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;
}
```

The double-check (requires BOTH `IsDevelopment=true` AND `DisableSSLValidation=true`) is a good security pattern.

---

## SECURITY POSITIVES

1. **Non-root container user:** Dockerfile correctly creates and uses `appuser` instead of running as root
2. **Multi-stage Docker build:** Reduces attack surface by not including SDK in final image
3. **Clean package management:** Dockerfile properly cleans apt cache
4. **SSL validation improvement:** As noted above, this PR fixes a previous security issue
5. **.dockerignore and .gitignore:** Properly configured to exclude sensitive files

---

## SUMMARY

| Issue | Severity | Confidence | Category |
|-------|----------|------------|----------|
| Unauthenticated health check endpoints | HIGH | 9/10 | data_exposure |
| Hardcoded encryption key | HIGH | 8/10 | hardcoded_secrets |
| API URL exposure in health checks | MEDIUM | 7/10 | data_exposure |

---

## RECOMMENDED ACTIONS (Priority Order)

1. **CRITICAL:** Add authentication to health check endpoints or restrict to localhost
2. **CRITICAL:** Remove hardcoded encryption key from version control and rotate it
3. **HIGH:** Sanitize health check responses to remove internal URLs
4. **MEDIUM:** Add secrets scanning to CI/CD pipeline (e.g., git-secrets, truffleHog)
5. **LOW:** Document health check security requirements in deployment guide

---

## TESTING VALIDATION

To verify fixes:

```bash
# Test 1: Verify health checks require auth (after fix)
curl -I https://target.com/health/ready
# Should return 401 Unauthorized or 403 Forbidden

# Test 2: Verify minimal information leakage
curl https://localhost:5000/health/ready
# Should NOT contain internal URLs or detailed error messages

# Test 3: Verify encryption key is not in git
git log --all --full-history --source -- "*env*" "*appsettings*"
# Should return no results with actual keys
```

---

## UNRESOLVED QUESTIONS

None. All security findings are high-confidence with clear remediation paths.

---

**Report End**
