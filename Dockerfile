# Build stage
# Purpose: Builds the final deployable app image.
# Used by Jenkins agent during pipeline (usually after dotnet publish).
   # Stage 1: SDK image → build app.
   # Stage 2: Runtime image → copy only final output (.dll), no SDK.
# This final image is lightweight, safe for production. It contains only the compiled app and the runtime, no SDK or build tools.

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies (layer caching optimization)
COPY *.csproj ./
RUN dotnet restore --use-current-runtime

# Copy source and publish
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage with security hardening
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled AS runtime
WORKDIR /app

# Copy published output from build stage
COPY --from=build /app/publish .

# Chiseled images already run as non-root user (UID 1654)
# No need to create a user manually

# Runtime configuration
EXPOSE 80
ENV ASPNETCORE_URLS="http://+:80" \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_NOLOGO=true \
    DOTNET_USE_POLLING_FILE_WATCHER=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Use the actual executable name or .dll name, Replace YourApp.dll with your actual application name
ENTRYPOINT ["dotnet", "YourApp.dll"] 