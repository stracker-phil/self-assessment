# React Development

| Front-End | **React.js - Generic**, outside of the context of WordPress |
|-----------|-------------------------------------------------------------|

## Overview

The featured React project showcases component architecture, state management, and UI development practices. While still under active development, the codebase demonstrates initial architectural decisions, Redux store implementation, and established coding standards. The work represents a complex customer project developed under a tight delivery deadline.

## Evidence

1. [The Settings module](https://github.com/woocommerce/woocommerce-paypal-payments/tree/trunk/modules/ppcp-settings)
   - **More specific links are below**
   - This is the full settings module - containing PHP and JS/SCSS code
   - My commits can be easily spotted, as I'm the only person using gitmojis

**Redux Architecture**

2. [Redux store template](https://github.com/woocommerce/woocommerce-paypal-payments/tree/trunk/modules/ppcp-settings/resources/js/data/_example)  
   - A sample implementation of a Redux store
   - The initial Redux store setup was my responsibility
   - Also note that the `onboarding` store is the first to use [thunks](https://developer.wordpress.org/block-editor/how-to-guides/thunks/) instead of controls

3. [Redux debug module](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/data/debug.js)
   - A small helper for Devs, QA, and other team members to test various app stages
   - It also showcases how to access Redux via the global `wp.data` object

**React and Component Design**

4. [Custom React hooks](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/hooks)
   - We try to use hooks to decouple behavior from UI componenty
   - From [simple navigation](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/hooks/useNavigation.js) to [more complex OAuth logic](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/hooks/useHandleConnections.js)

5. [Screen Management](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/Components/Screens/Onboarding/index.js)
   - Note how the content of the screen comes from [`getSteps()`](https://github.com/woocommerce/woocommerce-paypal-payments/blob/6339207bcde5602dfa7f84f8364a3ebc657ad99b/modules/ppcp-settings/resources/js/Components/Screens/Onboarding/Steps/index.js#L53-L69)
   - File organization (onboarding): Screens are separated from the (reusable) Components

**Implementation Sample**

6. [Styling Page](https://github.com/woocommerce/woocommerce-paypal-payments/tree/trunk/modules/ppcp-settings/resources/js/Components/Screens/Settings/Components/Styling)
   - Fully refactored this module, split code into Layout/Content
   - Integrated the UI with the Redux store
   - Generally, I aim to create generic, reusable components ([like this one](https://github.com/woocommerce/woocommerce-paypal-payments/blob/trunk/modules/ppcp-settings/resources/js/Components/ReusableComponents/Icons/GenericIcon.js))

## Context

- Note on the category: This proof _IS_ a WordPress integration, but I've chosen the "generic" section, as there was no "React inside WordPress" option. This category should clarify that it's not a _Block integration_.
- This project is still in progress, and some code needs clean-up
- The linked repo is owned by WooCommerce, but publicly available

---

[Introduction](../README.md) |
[JS in WordPress](../frontend-wp/README.md) |
**React Development** |
[WordPress Core](../wp-core/README.md) |
[PHP Architecture](../php-arch/README.md) |
[Automation](../automation/README.md)

---
