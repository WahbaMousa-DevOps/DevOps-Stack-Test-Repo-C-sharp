# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["*.sln", "./"]
COPY ["src/**/*.csproj", "./"]
RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*}/ && mv $file src/${file%.*}/; done
RUN dotnet restore

# Copy source code
COPY . .

# Build and publish
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Build arguments
ARG APP_VERSION=dev
ARG BUILD_NUMBER=0
ARG GIT_COMMIT=unknown

# Set labels with build information
LABEL org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.vendor="Your Organization" \
      org.opencontainers.image.title=".NET Sample Application" \
      org.opencontainers.image.description=".NET Core Sample Application" \
      build.number="${BUILD_NUMBER}"

WORKDIR /app
COPY --from=build /app/publish .

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Set permissions
RUN chown -R appuser:appgroup /app

# Set environment variables
ENV ASPNETCORE_ENVIRONMENT="Production" \
    ASPNETCORE_URLS="http://+:80" \
    DOTNET_EnableDiagnostics=0

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

# Expose port
EXPOSE 80

# Run application
ENTRYPOINT ["dotnet", "SampleApp.dll"]
