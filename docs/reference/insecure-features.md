---
hide:
  - toc

title: Insecure Features
---

Some [insecure driver features](https://appium.io/docs/en/latest/guides/security/) are disabled by
default. They can be enabled upon launching Appium as follows:
```
appium --allow-insecure mac2:<feature-name>
```
or
```
appium --relaxed-security
```

For other insecure feature names recognized by the Appium server, see
[their Appium docs reference page](https://appium.io/docs/en/latest/reference/cli/insecure-features/).

|<div style="width:7em">Feature Name</div>|Description|
|------------|-----------|
|`apple_script`|Allows execution of arbitrary AppleScript commands and scripts. Refer to [the AppleScript guide](../guides/applescript.md) for more details.|
