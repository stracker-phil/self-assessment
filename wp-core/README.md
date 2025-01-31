# WordPress Core Development

| Back-End | **WordPress Core internals** |
|----------|------------------------------|

## Overview

This plugin provides a GDPR-compliant local caching solution for external assets. Key implementations:

- Non-blocking asset detection via WordPress hooks
- Asynchronous asset caching using wp-cron
- Admin interface for cache management

## Evidence

**Asset Management**

1. [Asset detection](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/scanner.php#L17-L20) (4 lines, used filters)
   - Using hooks like [`script_loader_src`](https://developer.wordpress.org/reference/hooks/script_loader_src/) to detect external assets
   - Only swap out external URLs with local ones, if the local cache is ready
   - New assets are added to a queue, which is processed by the background worker, to not impact the site performance

2. [Background worker](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/worker.php#L52-L85) (~30 lines, two functions)
   - Custom cron job is registered to run once per day to refresh stale assets
   - When new assets are detected, a cron task is spawned on-demand to fetch new assets
   - Chosen, as this approach has nearly no impact on performance
   - A limitation is, that sometimes external or stale assets are served, which I considered better than slowing down requests

3. [Server-side asset loading](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/cache.php#L166-L236) (~70 lines, one function)
   - Using methods like [`wp_safe_remote_get()`](https://developer.wordpress.org/reference/functions/wp_safe_remote_get/) to load an external file into the local cache.
   - Respecting the remote servers' [`cache-control` header](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/cache.php#L221) to determine lifetime of the cache.
   
4. [Cache management](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/cache.php#L54-L90) (~35 lines, one function)
   - Local cache can be purged or invalidated (via a custom wp-admin page)

5. [Detection of stale assets](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/data.php#L253-L303) (~50 lines, core logic of a function)
   - Each time a cached asset is served, its staleness is reset
   - When cached files reach a certain level of staleness, they are deleted
   - The [daily staleness-check](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/ef356d718753109d46caf0d715e2a67be5d98e88/includes/libs/worker.php#L318-L371) automatically keeps the cache clean

6. [Admin page](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/main/includes/admin/options.php)
   - The plugin adds a simple admin page
   - Content of the admin page is defined in a [template file](https://github.com/stracker-phil/gdpr-cache-script-styles/blob/main/templates/admin-options.php)

## Context

- Created during a 72-hour Hackathon as proof-of-concept
- Successfully published to WordPress.org plugin repository
- GitHub repo: https://github.com/stracker-phil/gdpr-cache-script-styles
- WordPress.org plugin: https://wordpress.org/plugins/gdpr-cache-scripts-styles/

---

[Introduction](../README.md) |
[JS in WordPress](../frontend-wp/README.md) |
[React Development](../react-ui/README.md) |
**WordPress Core** |
[PHP Architecture](../php-arch/README.md) |
[Automation](../automation/README.md)

---
