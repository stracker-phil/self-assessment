# General PHP Architecture

| Back-End | PHP - Generic, ~~outside the context of WordPress~~ |
|----------|-----------------------------------------------------|

## Overview

This proof presents a WordPress plugin built with modern PHP practices. While developed within WordPress, the implementation demonstrates generic PHP skills through its Symfony-inspired architecture, object-oriented design principles, and Modularity for dependency injection.

## Evidence

**Modern PHP Features**

1. [Data Transfer Objects](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Dto/UserDto.php)
   - Constructor Property Promotion
   - Named Arguments implementation
   - Type-safe data handling

2. [Related Data Transformers](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Service/Transformer/UserJsonPlaceholderTransformer.php)
   - Combines data parsing logic in an isolated module
   - Parses arrays into DTOs
   - Isolates knowledge of internal data structures from REST endpoints

**Architecture Patterns**

3. [Simple Modularity Wrapper](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Application.php)
   - Provides means to [easily configure the plugin](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/dfe351b8a26bd1b6095a44f740d267849f2dfbc0/backend-user-list.php#L64-L92)

4. [DI Service-Providers](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Provider/FrontendProvider.php)
   - PSR-11 compatible containers, using Modularity
   - Service provider implementation

5. [Repository Pattern](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Repository/UserRepository.php)
   - Data access abstraction
   - Caching integration
   - Error handling implementation

**Advanced Patterns**

6. [SettingResolver Pattern](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Service/Setting/SettingResolver.php)
   - Configuration proxy implementation
   - Allows filtering values _after_ plugin initialization
   - Unit test compatibility

7. [Action Handler Pattern](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/main/src/Action/TerminateAction.php)
   - Sample [usage of the TerminateAction](https://github.com/stracker-phil/inpsyde-assessment-user-list/blob/dfe351b8a26bd1b6095a44f740d267849f2dfbc0/src/Controller/ListPageController.php#L103-L104)
   - Command pattern implementation
   - Testable action execution
   - WordPress hook integration

## Context

- This assessment plugin was specifically created to demonstrate clean architecture principles and modern PHP practices.
- The project includes a React-based frontend, documented in the [JS in WordPress](../frontend-wp/README.md) section, showcasing how the backend architecture supports frontend integration.
- Though built as a WordPress plugin, the PHP architecture deliberately follows generic best practices that would apply in any modern PHP project.

---

[Introduction](../README.md) |
[JS in WordPress](../frontend-wp/README.md) |
[React Development](../react-ui/README.md) |
[WordPress Core](../wp-core/README.md) |
**PHP Architecture** |
[Automation](../automation/README.md)

---
