# JS in WordPress

| Front-End | **JS in the context of WordPress** (excluding Site and Block Editor) |
|-----------|----------------------------------------------------------------------|

## Overview

This proof demonstrates JavaScript integration with WordPress core functionality, focusing on frontend interactions with REST APIs. Part of a full-stack implementation, the selected example shows a React UI that integrates with WordPress data structures and maintains WordPress coding standards.

## Evidence

**React Frontend**

1. [React Application](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/assets/js/component/Application.jsx)
   - Small React app, split into several components
   - Each component imports its individual SCSS file (modular styling)
   - Implementing React hooks 

**Theme Integration**

2. [SCSS Implementation](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/assets/scss/application.scss)
   - Clean and documented SCSS structure
   - Using `--custom-properties` to define a theme
   - Leveraging `%scss-placeholders` instead of mixins, to create predictable and smaller CSS files

**REST API Integration**

3. [JS API handler](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/assets/js/api/UserApi.js)
   - JS class that consumes the provided REST endpoints
   - Usage of `#private` attributes/functions

4. [REST API](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/docs/usage.md)
   - Provides two GET endpoints to list all users or get details of one user

## Context

- This implementation is part of an assessment plugin that demonstrates a real-world full-stack architecture.
- The backend implementation of this project is detailed in the [PHP Architecture](../php-arch/README.md) section.
- While this section focuses on WordPress-specific JavaScript integration, the React patterns used here complement the broader React examples in the [React Development](../react-ui/README.md) section.

---

[Introduction](../README.md) |
**JS in WordPress** |
[React Development](../react-ui/README.md) |
[WordPress Core](../wp-core/README.md) |
[PHP Architecture](../php-arch/README.md) |
[Automation](../automation/README.md)

---
