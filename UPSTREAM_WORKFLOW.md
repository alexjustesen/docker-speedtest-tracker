# Upstream Repository Workflow Configuration

This document describes the GitHub Actions workflow that needs to be created in the main `alexjustesen/speedtest-tracker` repository to automatically trigger Docker image builds in this repository.

## Required Workflow

Create the following file in the speedtest-tracker repository:

**File path**: `.github/workflows/trigger-docker-build.yml`

```yaml
name: Trigger Docker Image Build

on:
  release:
    types: [published]

jobs:
  trigger-docker-build:
    runs-on: ubuntu-latest

    steps:
      - name: Generate GitHub App token
        id: generate_token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.APP_ID }}
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
          owner: alexjustesen
          repositories: docker-speedtest-tracker

      - name: Trigger docker-speedtest-tracker build
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ steps.generate_token.outputs.token }}
          repository: alexjustesen/docker-speedtest-tracker
          event-type: speedtest-tracker-release
          client-payload: '{"tag_name": "${{ github.event.release.tag_name }}"}'
```

## Setup Requirements

### 1. Create a GitHub App

1. Go to GitHub Settings > Developer settings > GitHub Apps > New GitHub App
2. Configure the app:
   - **Name**: Something like "Speedtest Tracker Docker Build"
   - **Homepage URL**: `https://github.com/alexjustesen/speedtest-tracker`
   - **Webhook**: Uncheck "Active"
   - **Permissions**:
     - Repository permissions > Contents: Read and write
   - **Where can this GitHub App be installed?**: Only on this account
3. Click "Create GitHub App"
4. Note the **App ID** (you'll need this)
5. Scroll down to "Private keys" and click "Generate a private key"
6. Save the downloaded `.pem` file

### 2. Install the GitHub App

1. On your GitHub App page, click "Install App" in the left sidebar
2. Select your account (alexjustesen)
3. Choose "Only select repositories"
4. Select `docker-speedtest-tracker`
5. Click "Install"

### 3. Add Secrets to speedtest-tracker Repository

1. Go to `https://github.com/alexjustesen/speedtest-tracker/settings/secrets/actions`
2. Add the following secrets:
   - **Name**: `APP_ID`
     - **Value**: The App ID from step 1.4
   - **Name**: `APP_PRIVATE_KEY`
     - **Value**: The entire contents of the `.pem` file (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`)

## How It Works

1. When a new release is published in `alexjustesen/speedtest-tracker`
2. This workflow triggers automatically
3. It sends a `repository_dispatch` event to `alexjustesen/docker-speedtest-tracker`
4. The event includes the release tag name in the payload
5. The docker repository's `release.yml` workflow receives the event and builds the Docker image

## Alternative: Using Personal Access Token (PAT)

If you prefer a simpler setup (though less secure for organizations), you can use a Personal Access Token:

**Workflow:**
```yaml
name: Trigger Docker Image Build

on:
  release:
    types: [published]

jobs:
  trigger-docker-build:
    runs-on: ubuntu-latest

    steps:
      - name: Trigger docker-speedtest-tracker build
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.DOCKER_REPO_PAT }}
          repository: alexjustesen/docker-speedtest-tracker
          event-type: speedtest-tracker-release
          client-payload: '{"tag_name": "${{ github.event.release.tag_name }}"}'
```

**Setup:**
1. Create a Personal Access Token with `repo` scope
2. Add it as a secret named `DOCKER_REPO_PAT` in the speedtest-tracker repository

Note: GitHub Apps are recommended over PATs for better security, audit logging, and fine-grained permissions.

## Testing

To test the workflow without creating a release:

1. Trigger manually using workflow_dispatch in the docker repository
2. Go to `https://github.com/alexjustesen/docker-speedtest-tracker/actions/workflows/release.yml`
3. Click "Run workflow"
4. Enter a release tag (e.g., `v0.1.0`)
5. Verify the build completes successfully

## Expected Behavior

When a release like `v0.1.0` is published in speedtest-tracker:
- Docker images will be built for `linux/amd64` and `linux/arm64`
- Images will be tagged as:
  - `ghcr.io/alexjustesen/docker-speedtest-tracker:0.1.0`
  - `ghcr.io/alexjustesen/docker-speedtest-tracker:0.1`
  - `ghcr.io/alexjustesen/docker-speedtest-tracker:0`
  - `ghcr.io/alexjustesen/docker-speedtest-tracker:latest`
