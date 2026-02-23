# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY ["KKday.B2D.Web.InternAgent/KKday.B2D.Web.InternAgent.csproj", "KKday.B2D.Web.InternAgent/"]
RUN dotnet restore "KKday.B2D.Web.InternAgent/KKday.B2D.Web.InternAgent.csproj"

# Copy source code and publish
COPY . .
WORKDIR "/src/KKday.B2D.Web.InternAgent"
RUN dotnet publish "KKday.B2D.Web.InternAgent.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS final

# Install locales for zh-TW and en-US, plus curl for health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales curl && \
    sed -i '/zh_TW.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale environment
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy published output from build stage
COPY --from=build /app/publish .

# Set ownership to non-root user
RUN chown -R appuser:appuser /app
USER appuser

# Expose ports
EXPOSE 80
EXPOSE 443

# Health check
HEALTHCHECK CMD curl -f http://localhost:80/health/live || exit 1

# Entry point
ENTRYPOINT ["dotnet", "KKday.B2D.Web.InternAgent.dll"]
