---
title: Capabilities
---

This page lists various capabilities used and implemented by the Mac2 driver. To learn more
about capabilities, refer to the [Appium documentation](https://appium.io/docs/en/latest/guides/caps/).

For other capabilities recognized by the Appium server, see
[their Appium docs reference page](https://appium.io/docs/en/latest/reference/session/caps/).

## Standard

Refer to [the W3C WebDriver documentation](https://w3c.github.io/webdriver/#capabilities)
for more information about these capabilities.

### platformName

| Name | Type | Default |
| -- | -- | -- |
| `platformName` | `string` | Not specified |

This capability must be set to `mac` (case-insensitive)

## General

### automationName

| Name | Type | Default |
| -- | -- | -- |
| `appium:automationName` | `string` | Not specified |

Specifies the Appium driver to use. Must be set to `mac2` (case-insensitive)

### prerun

| Name | Type | Default |
| -- | -- | -- |
| `appium:prerun` | `string` | Not specified |

AppleScript command or script to be executed prior to session startup. Refer to
[the AppleScript guide](../guides/applescript.md) for more details.

### postrun

| Name | Type | Default |
| -- | -- | -- |
| `appium:postrun` | `string` | Not specified |

AppleScript command or script to be executed after session termination. Refer to
[the AppleScript guide](../guides/applescript.md) for more details.

## App

### bundleId

| Name | Type | Default |
| -- | -- | -- |
| `appium:bundleId` | `string` | `com.apple.finder` |

The bundle identifier of the application under test. If the application is already running, it will
be moved to the foreground. An error will be thrown if the application is not installed.

### arguments

| Name | Type | Default |
| -- | -- | -- |
| `appium:arguments` | `Array<string>` | Not specified |

Array of command line arguments passed to the application under test when launching it. This
capability only applies if the application is not running or is relaunched on session startup.

### environment

| Name | Type | Default |
| -- | -- | -- |
| `appium:environment` | `Record<string, any>` | Not specified |

Map of environment variables and their values set when launching the application under test. This
capability only applies if the application is not running or is relaunched on session startup.

### skipAppKill

| Name | Type | Default |
| -- | -- | -- |
| `appium:skipAppKill` | `boolean` | `false` |

Whether to skip the termination of the application under test when the session is deleted. This
capability only applies if the `appium:bundleId` capability is provided.

### noReset

| Name | Type | Default |
| -- | -- | -- |
| `appium:noReset` | `boolean` | `false` |

Whether to skip relaunching the application under test upon session start, and just attach to the
application in its current state. Note that the `appium:arguments` and `appium:environment`
capabilities will not take effect if this capability is set to `true`.

### appPath

| Name | Type | Default |
| -- | -- | -- |
| `appium:appPath` | `string` | Not specified |

Path to the application under test. An error will be thrown if the path is invalid, or the
application is damaged.

This capability can be useful when running tests on devices with multiple builds of the same
application, using the same bundle identifier.

On Mac2 driver versions 1.12.0 and earlier, this capability is ignored if `appium:bundleId` is not
specified.

### appLocale

| Name | Type | Default |
| -- | -- | -- |
| `appium:appLocale` | `Record<string, any>` | Not specified |

Map of localization-related properties to apply to the app under test, without changing the system
locale properties. The following properties are supported:

* `locale`: the application locale (e.g. `uk_UA`)
* `language`: the application language (e.g. `de`)
* `useMetricUnits`: whether to use measurement units in metric (`true`, the default value) or imperial (`false`)
* `measurementUnits`: the name of measurement units to use (e.g. `Inches`)

All of the above properties can also be provided using the `appium:arguments` capability, using
arguments like `-AppleLanguages`, `-AppleLocale`, `-AppleMetricUnits` and `-AppleMeasurementUnits`,
respectively.

### appTimeZone

| Name | Type | Default |
| -- | -- | -- |
| `appium:appTimeZone` | `string` | Not specified |

Overrides the timezone used in the application under test. It is possible to specify timezone
abbreviations (e.g. `UTC`) as well as TZ identifiers (e.g. `America/Los_Angeles`) - refer to the
[List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for
more information.

This capability only applies if the application is not running or is relaunched on session startup.
The app timezone can also be set using [the `TZ` environment variable](https://developer.apple.com/forums/thread/86951?answerId=263395022#263395022)
via the `appium:environment` capability.

### initialDeeplinkUrl

| Name | Type | Default |
| -- | -- | -- |
| `appium:initialDeeplinkUrl` | `string` | Not specified |

A deeplink URL used to run the application under test, or, if `appium:bundleId` is omitted, the
default application assigned to handle the specified deeplink protocol. Xcode 14.3 or later is
required. An error is thrown if the URL is invalid or cannot be associeted with any app.

## WebDriverAgent

### systemPort

| Name | Type | Default |
| -- | -- | -- |
| `appium:systemPort` | `number` | `10100` |

The port number on which the WDA server should be listening.

### systemHost

| Name | Type | Default |
| -- | -- | -- |
| `appium:systemHost` | `string` | `127.0.0.1` |

The host name on which the WDA server should be listening. Can be set to `0.0.0.0` to make the
server listen on all available network interfaces. Interface names (e.g. `en1`) can also be used.

### webDriverAgentMacUrl

| Name | Type | Default |
| -- | -- | -- |
| `appium:webDriverAgentMacUrl` | `string` | Not specified |

The URL of a running WDA server. If specified, the driver will try to connect to the WDA instance
at this URL, instead of launching a new WDA instance.

### showServerLogs

| Name | Type | Default |
| -- | -- | -- |
| `appium:showServerLogs` | `boolean` | `false` |

Whether to include `xcodebuild` output in the Appium server log.

### bootstrapRoot

| <div style="width:11em">Name</div> | Type | Default |
| -- | -- | -- |
| `appium:bootstrapRoot` | `string` | The `WebDriverAgentMac` directory under the Mac2 driver installation path |

Full path to a custom directory containing the `WebDriverAgentMac.xcodeproj` WDA project.

### serverStartupTimeout

| Name | Type | Default |
| -- | -- | -- |
| `appium:serverStartupTimeout` | `number` | `120000` |

Time in milliseconds to wait until the WDA server is built and started.
