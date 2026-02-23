# Code Review Report: Health Check URL Exposure

**Date:** 2026-02-21
**Reviewer:** code-reviewer (aaeb749)
**File:** `KKday.B2D.Web.InternAgent/AppCode/KKdayApiHealthCheck.cs:39`
**Finding Category:** Data Exposure
**Severity:** MEDIUM
**Confidence Score:** 2/10

---

## Executive Summary

**FALSE POSITIVE** - This finding should be rejected.

The health check endpoint returns status information about API connectivity without exposing the actual API URL. While the finding claims "internal API URLs" are exposed, the code only returns HTTP status codes and descriptive messages.

---

## Analysis

### 1. What Is Actually Being Exposed?

**Code in question:**
```csharp
return HealthCheckResult.Healthy($"KKday API is reachable (status: {response.StatusCode})");
```

**Actual output:**
- "KKday API is reachable (status: 200)"
- "KKday API is reachable (status: 404)"
- "KKday API is reachable (status: 405)"

**What is NOT exposed:**
- The API URL itself (`_apiUrl` variable is never included in output)
- API endpoints
- Authentication tokens
- Internal topology details

### 2. Application of Filtering Rules

This finding is excluded by **HARD EXCLUSION RULE #2**: "Secrets or sensitive data stored on disk if they are otherwise secured."

The health check reveals:
- **Service availability** (up/down)
- **HTTP status codes** (standard public information)

These are operational metrics, not security-sensitive information.

### 3. Precedent Analysis

**Precedent #1:** "Logging URLs is assumed to be safe."
- Even if the URL were logged, it would be considered safe per established precedents
- The actual URL is NOT being exposed here

**Precedent #9:** "Only include MEDIUM findings if they are obvious and concrete issues."
- This is NOT an obvious vulnerability
- Knowing that "KKday API is reachable" provides no actionable intelligence for an attacker

### 4. Security Risk Assessment

**Claimed Risk:** "An attacker querying the /health/ready endpoint could learn the internal API URL and system status"

**Actual Risk Analysis:**
- **URL Discovery:** FALSE - The URL is never included in the response
- **System Status:** TRUE - But this is the intended purpose of a health check endpoint
- **Reconnaissance Value:** NONE - Health checks are standard practices and don't reveal attack surface

### 5. Industry Standard Practice

Health check endpoints are designed to expose operational status:
- **Kubernetes Liveness/Readiness Probes:** Standard practice
- **ASP.NET Core Health Checks:** Framework-recommended pattern
- **Monitoring/Alerting:** Require this information to function

The `/health/ready` endpoint is unauthenticated by design, as it needs to be queried by:
- Load balancers
- Kubernetes controllers
- Monitoring systems
- Orchestrators

Requiring authentication would break standard operational patterns.

### 6. URL Discoverability Analysis

From configuration files:
```
Development: https://api-b2d-10.sit.kkday.com/v4
Production: (configured via environment variable)
```

**Discovery Methods Available to Attackers:**
1. DNS enumeration (`*.sit.kkday.com`)
2. Subdomain bruteforcing
3. Certificate transparency logs
4. Public code repositories
5. Network scanning
6. Browser developer tools (frontend makes API calls)

The API URL is easily discoverable through normal application usage since the frontend communicates with it directly.

---

## Conclusion

### False Positive Determination

**Confidence Score: 2/10** (Likely false positive or noise)

### Reasons for Rejection:

1. **No URL Exposure:** The `_apiUrl` variable is never included in health check responses
2. **Status Codes Are Public:** HTTP status codes are not sensitive information
3. **Standard Practice:** Health checks exposing operational status is industry standard
4. **No Reconnaissance Value:** Attackers gain no meaningful advantage from this information
5. **URL Already Discoverable:** The API URL is trivial to discover via other means
6. **Precedent Alignment:** Matches "Logging URLs is assumed to be safe" precedent

### Risk Reality:

- **Exposure:** "KKday API is reachable (status: 200)"
- **Impact:** None - This is operational telemetry
- **Attack Vector:** Does not exist
- **Security Boundary:** No security boundary is crossed

---

## Recommendation

**REJECT THIS FINDING** as a false positive.

The health check implementation follows ASP.NET Core best practices and does not expose sensitive information. The finding appears to be based on incorrect code analysis (assuming the URL is exposed when it is not).

---

## References

- **File:** `/home/thaitrn/Workspace/kkday/kkday-b2d-internagent/KKday.B2D.Web.InternAgent/AppCode/KKdayApiHealthCheck.cs`
- **Lines:** 39, 44, 49, 54
- **Health Check Registration:** `Program.cs:69-70, 102, 107`
- **Configuration:** `appsettings.Development.json:14-16`

---

**No unresolved questions.**