---
hide:
  - toc

title: Testing in Parallel
---


Parallel execution of multiple Mac2 driver instances is **highly discouraged**.

Access to the accessibility layer is single-threaded, which means that only one UI test must be
running at any time. Similarly, various HID devices, such as a mouse or keyboard, must be acquired
exclusively.

Only a single session is supported at a time. Starting a new session terminates the one that is
currently active on the same Appium server, and the new session waits until the old one has quit.
If the old session does not finish quitting within 15 seconds, the new session fails to start.
The terminated session's commands fail with `NoSuchDriverError`. Consider enabling the Appium
server's `--session-override` flag, and always quit sessions explicitly.
