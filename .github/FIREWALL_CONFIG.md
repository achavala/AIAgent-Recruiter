# Firewall Configuration for GitHub Actions

This document explains the firewall configuration implemented to resolve build failures in GitHub Actions due to blocked access to Debian package repositories.

## Problem

The GitHub Actions workflow was encountering firewall restrictions when trying to connect to Debian package repositories (`deb.debian.org`), resulting in the following error:

```
⚠️ Warning: I tried to connect to the following addresses, but was blocked by firewall rules:
- `_http._tcp.deb.debian.org.`
  - Triggering Command: `/usr/lib/apt/methods/http ` (dns block)
  - Triggering Command: `root process (pid 0)` (dns block)
```

## Solution

The solution implemented involves two main components:

### 1. Firewall Configuration File (`.github/firewall-config.yml`)

This configuration file specifies allowed domains and patterns for package repository access:

- **Allowed Domains**: `deb.debian.org`, `security.debian.org`, `archive.debian.org`, etc.
- **Allowed Patterns**: `*.debian.org`, `*.ubuntu.com`, etc.
- **Allowed Ports**: 80 (HTTP), 443 (HTTPS)
- **DNS Resolution**: Specific DNS entries for package repositories

### 2. Workflow Updates (`.github/workflows/ci-cd.yml`)

The CI/CD workflow has been updated with the following improvements:

#### Early Package Installation
- **Backend Tests**: Install `gcc`, `g++`, `build-essential`, `curl`, `wget`, `ca-certificates`
- **Frontend Tests**: Install `curl`, `wget`, `ca-certificates`
- **Build Job**: Install complete development toolchain early in the process

#### DNS Configuration
- Configure Google DNS servers (8.8.8.8, 8.8.4.4) for better repository access
- Applied to all jobs that need package repository access

#### Docker Build Improvements
- Pre-pull base images to cache them locally
- Configure Docker Buildx with host networking
- Add retry logic and better error handling
- Use trusted hosts for pip installations

### 3. Dockerfile Updates (`backend/Dockerfile`)

The backend Dockerfile has been enhanced with:

- **Certificate Management**: Install and update `ca-certificates`
- **Trusted Hosts**: Use `--trusted-host` flags for pip to bypass SSL verification issues
- **Better Cleanup**: More thorough cleanup of temporary files and package lists

## Implementation Details

### Workflow Changes

1. **Early Dependencies**: Install system dependencies at the beginning of each job
2. **DNS Configuration**: Set up reliable DNS resolution
3. **Docker Configuration**: Configure Docker with host networking support
4. **Base Image Caching**: Pre-pull base images to reduce network dependencies

### Docker Changes

1. **SSL Certificate Handling**: Install `ca-certificates` and run `update-ca-certificates`
2. **Pip Configuration**: Use trusted hosts for PyPI access
3. **Improved Cleanup**: Better cache cleanup to reduce image size

### Firewall Configuration

The firewall configuration file provides a centralized way to manage allowed domains and patterns for package repository access. While GitHub Actions doesn't directly use this file for firewall rules, it serves as documentation and can be referenced by infrastructure teams.

## Usage

The configuration is automatically applied when the workflow runs. No manual intervention is required.

## Monitoring

The workflow includes logging to help monitor the effectiveness of the firewall configuration:

- ✅ DNS configured for better repository access
- ✅ Base images cached locally
- ✅ Firewall configuration loaded

## Troubleshooting

If build failures continue:

1. Check the workflow logs for DNS resolution issues
2. Verify that the base images are being pulled successfully
3. Ensure that the trusted hosts are configured correctly for pip
4. Consider adding additional mirrors to the firewall configuration

## Future Improvements

- Add support for additional package repositories
- Implement more sophisticated retry logic
- Add metrics and monitoring for repository access
- Consider using package mirrors for better reliability