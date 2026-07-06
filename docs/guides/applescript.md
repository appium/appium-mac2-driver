---
hide:
  - toc

title: AppleScript Support
---

Certain features of the Mac2 driver support executing arbitrary AppleScript commands and scripts.

!!! warning

    This is considered an insecure feature, so it must be explicitly enabled on the Appium server
    using the [`apple_script` feature name](../reference/insecure-features.md).

AppleScript is supported in the following features:

* [`appium:prerun` capability](../reference/capabilities.md#prerun)
* [`appium:postrun` capability](../reference/capabilities.md#postrun)
* [`macos: appleScript` execute method](../reference/execute-methods.md#macos-applescript)

An AppleScript command cannot contain line breaks. In such cases consider making it into a script.

All features supporting AppleScript commands/scripts will return the `stdout` of the AppleScript
command/script. If the script raises an exception (non-zero exit code), the feature invoking the
script will also raise an exception, and include the `stderr` of the AppleScript command/script.

If your script is attempting to access some private entities (such as cameras or the desktop screen),
the AppleScript engine may block it. To fix this, you can explicitly provide such permissions by
adding the parent process (usually Terminal) in the macOS Settings -> _Privacy & Security_ list.
