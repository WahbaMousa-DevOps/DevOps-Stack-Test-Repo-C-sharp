# Build stage
# Purpose: Builds the final deployable app image.
# Used by Jenkins agent during pipeline (usually after dotnet publish).
   # Stage 1: SDK image → build app.
   # Stage 2: Runtime image → copy only final output (.dll), no SDK.
# This final image is lightweight, safe for production. It contains only the compiled app and the runtime, no SDK or build tools.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Layer caching optimization
COPY *.csproj ./
RUN dotnet restore --use-current-runtime

# Build/publish optimization
COPY . .
RUN dotnet publish -c Release -o /out --no-restore

# Runtime stage with security hardening
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled AS runtime
WORKDIR /app
COPY --from=build /out .

# Non-root user setup
RUN adduser --disabled-login --no-create-home --gecos '' appuser \
    && chown -R appuser:appuser /app
USER appuser

# Runtime configuration
EXPOSE 80
ENV ASPNETCORE_URLS="http://+:80" \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_NOLOGO=true
ENTRYPOINT ["dotnet", "csharp-hello.dll"]