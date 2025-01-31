# GitHub Automation

| General topic | Automation, CI/CD |
|---------------|-------------------|

## Overview

This collection of automation scripts demonstrates a complete CI/CD pipeline for WordPress plugin development. The implementation covers quality assurance, testing, and deployment automation. Key features include:

- Automated code quality checks (PHP_CodeSniffer integration)
- Multi-channel deployment packaging (own website + marketplace)
- Local development tooling (test runners, build scripts)
- Cross-plugin synchronization (premium → free version)

## Evidence

**Automated Quality Assurance**

1. [qa-phpcs.yaml](.github/workflows/qa-phpcs.yaml)

   - Runs a phpcs check against every change that's pushed to any branch
   - It downloads and uses custom phpcs rules

**Deployment Pipeline**

2. [deployment.yaml](.github/workflows/deployment.yml)

   - A GitHub action which automatically triggers when pushing changes to the `main` branch.
   - It uses a shell script to build two packages for deployment

3. [build.sh](bin/action/build.sh)

   - The shell script which builds the deployment packages
   - Also contains some documentation on the build process

**Local Dev Tooling**

4. [run-tests.sh](bin/run-test.sh)

   - Executes a test suite, using Codecept, CodeceptJS or Jest (test suites not included)
   - Meant for local execution before pushing to `main` branch; not run via GitHub actions

5. [update-free.sh](bin/update-free.sh)

   - Script that is only present in my "premium" plugin
   - It copies relevant files to the "free" plugin, using some automations to omit files or code-sections marked as "pro-only"
   - Uses string replacement to update text-domain, constant/variable names in the free plugin

## Context

- Repository access: Files copied from original Divimode repository (company sold)
- Production usage: CI/CD pipeline used for 3+ years in [Divi Areas Pro](https://divimode.com/divi-areas-pro/)
- Technology stack: GitHub Actions, Shell scripting, npm integration
- Scale: Managed deployments for both free and premium plugin versions

---

[Introduction](../README.md) |
[JS in WordPress](../frontend-wp/README.md) |
[React Development](../react-ui/README.md) |
[WordPress Core](../wp-core/README.md) |
[PHP Architecture](../php-arch/README.md) |
**Automation**

---
