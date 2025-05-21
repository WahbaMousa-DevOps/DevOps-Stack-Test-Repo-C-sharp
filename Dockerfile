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
# RUNTIME STAGE (toggle via ARG)
# -----------------------------------

ARG RUNTIME_IMAGE=mcr.microsoft.com/dotnet/aspnet:8.0
FROM ${RUNTIME_IMAGE} AS runtime


WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "DevOps-Stack-Test-Repo-C-sharp.dll"]
