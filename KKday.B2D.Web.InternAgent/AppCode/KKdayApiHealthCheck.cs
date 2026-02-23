using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace KKday.B2D.Web.InternAgent.AppCode
{
    public class KKdayApiHealthCheck : IHealthCheck
    {
        private readonly ILogger<KKdayApiHealthCheck> _logger;
        private readonly string _apiUrl;

        public KKdayApiHealthCheck(IConfiguration config, ILogger<KKdayApiHealthCheck> logger)
        {
            _logger = logger;
            _apiUrl = config["KKdayApi:Url"] ?? "";
        }

        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            try
            {
                if (string.IsNullOrEmpty(_apiUrl))
                {
                    return HealthCheckResult.Unhealthy("KKday API URL not configured");
                }

                // Simple connectivity check with short timeout
                using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };

                try
                {
                    // Try to reach the API base URL with a simple HEAD request
                    // Most APIs respond to HEAD or return 405 Method Not Allowed (which means host is up)
                    using var request = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Head, _apiUrl);
                    var response = await client.SendAsync(request, cancellationToken);

                    // Any response from the server means connectivity is working
                    // (even 401, 403, 404, 405 means the server is reachable)
                    return HealthCheckResult.Healthy($"KKday API is reachable (status: {response.StatusCode})");
                }
                catch (HttpRequestException ex)
                {
                    // API is not reachable
                    return HealthCheckResult.Unhealthy($"KKday API is unreachable: {ex.Message}");
                }
                catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
                {
                    // Timeout
                    return HealthCheckResult.Unhealthy("KKday API check timed out");
                }
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Unhealthy($"KKday API check failed: {ex.Message}");
            }
        }
    }
}
