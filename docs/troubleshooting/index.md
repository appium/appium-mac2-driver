---
hide:
  - navigation

title: Troubleshooting
---

## "WebDriverAgentRunner-Runner is from unidentified developer"

This system alert can appear on session startup. It is a macOS security feature and it cannot be
disabled. The only way to workaround this behavior is to configure digital signing for WDA. Check
[the Stackoverlow thread](https://stackoverflow.com/questions/41062607/osx-complains-that-app-is-from-unidentified-developer-although-it-passes-all-va)
for more details on how to do it. You can use the [`open-wda` driver script](../reference/scripts.md)
to easily open the WebDriverAgentMac sources in Xcode.
