# Prod real app runtime not for Jenkins CI agent
# -----------------------------------
# BUILD STAGE
# -----------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY *.csproj ./
RUN dotnet restore --use-current-runtime

COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# -----------------------------------
# RUNTIME STAGE
# -----------------------------------

# ARG PROD_RUNTIME_IMAGE=mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled
ARG RUNTIME_IMAGE=mcr.microsoft.com/dotnet/aspnet:8.0
FROM ${RUNTIME_IMAGE} AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=build /app/publish .

RUN chown -R appuser:appgroup /app

USER appuser

ENTRYPOINT ["dotnet", "DevOps-Stack-Test-Repo-C-sharp.dll"]
