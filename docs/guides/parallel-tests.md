---
hide:
  - toc

title: Testing in Parallel
---


Parallel execution of multiple Mac2 driver instances is **highly discouraged**.

Access to the accessibility layer is single-threaded, which means that only one UI test must be
running at any time. Similarly, various HID devices, such as a mouse or keyboard, must be acquired
exclusively.
