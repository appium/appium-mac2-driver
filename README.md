appium-geckodriver
====

This is Appium driver for automating Firefox on different platforms, including Android.
The driver only supports Firefox and Gecko-based web views (Android only) automation using [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/).
Under the hood this driver is a wrapper/proxy over `geckodriver` binary. Check the driver [release notes](https://github.com/mozilla/geckodriver/releases) and the [official documentation](https://developer.mozilla.org/en-US/docs/Web/WebDriver/Capabilities) to get more details on the supported features and possible pitfalls.


## Usage

It is mandatory to have both Firefox browser installed and the geckodriver binary downloaded on the platform where automated tests are going to be executed. Firefox could be downloaded from the [official download site](https://www.mozilla.org/en-GB/firefox/all/) and the driver binary could be retrieved from the GitHub [releases page](https://github.com/mozilla/geckodriver/releases). The binary must be put into one of the folders included to PATH environment variable. On macOS it also might be necessary to run `xcattr -cr "<binary_path>"` to avoid [notarization](https://firefox-source-docs.mozilla.org/testing/geckodriver/Notarization.html) issues.

Then you need to decide where the automated test is going to be executed. Gecko driver supports the following target platforms:
 - macOS
 - Windows
 - Linux
 - Android

In order to run your automated tests on Android it is necessary to have [Android SDK](https://developer.android.com/studio) installed, so the destination device is marked as `online` in the `adb devices -l` command output.

Gecko driver allows to define multiple criterions for platform selection and also to fine-tune your automation session properties. This could be done via the following session capabilities:

Capability Name | Description
--- | ---
platformName | Gecko Driver supports the following platforms: `mac`, `linux`, `windows`. The fact your test must be executed on Android is detected based on `moz:firefoxOptions` entry values. Values of platformName are compared case-insensitively.
browserName | Any value passed to this capability will be changed to 'firefox'.
browserVersion | Provide the version number of the browser to automate if there are multiple versions installed on the same machine where the driver is running.
automationName | Must always be set to `Gecko`.
noReset | Being set to `true` adds the `--connect-existing` argument to the server, that allows to connect to an existing browser instance instead of starting a new browser instance on session startup.
systemPort | The number of the port for the driver to listen on. Must be unique for each session. If not provided then Appium will try to detect it automatically.
verbosity | The verbosity level of driver logging. By default minimum verbosity is applied. Possible values are `debug` or `trace`.
androidStorage | See https://firefox-source-docs.mozilla.org/testing/geckodriver/Flags.html#code-android-storage-var-android-storage-var-code
moz:firefoxOptions | See https://developer.mozilla.org/en-US/docs/Web/WebDriver/Capabilities/firefoxOptions
acceptInsecureCerts | See https://www.w3.org/TR/webdriver/#capabilities
pageLoadStrategy | See https://www.w3.org/TR/webdriver/#capabilities
proxy | See https://www.w3.org/TR/webdriver/#capabilities
setWindowRect | See https://www.w3.org/TR/webdriver/#capabilities
timeouts | See https://www.w3.org/TR/webdriver/#capabilities
unhandledPromptBehavior | See https://www.w3.org/TR/webdriver/#capabilities


## Example

```python
# Python3 + PyTest
import pytest
import time

from appium import webdriver
from selenium.webdriver.common.by import By


def generate_caps():
    common_caps = {
        # It does not really matter what to put there, although setting 'Firefox' might cause a failure
        # depending on the particular client library
        'browserName': 'MozillaFirefox',
        # automationName capability presence is mandatory for this Gecko Driver to be selected
        'automationName': 'Gecko',
        # Should have the name of the host platform, where the geckodriver binary is deployed
        'platformName': 'mac',
    }
    android_caps = {
        **common_caps,
        'moz:firefoxOptions': {
            'androidDeviceSerial': '<device/emulator serial>',
            # These capabilities depend on what you are going to automate
            # Refer Mozilla documentation at https://developer.mozilla.org/en-US/docs/Web/WebDriver/Capabilities/firefoxOptions for more details
            'androidPackage': 'org.mozilla.firefox',
        },
    }
    desktop_browser_caps = {
        **common_caps,
    }
    return [android_caps, desktop_browser_caps]


@pytest.fixture(params=generate_caps())
def driver(request):
    drv = webdriver.Remote('http://localhost:4723/wd/hub', request.param)
    yield drv
    drv.quit()


class TimeoutError(Exception):
    pass


def wait_until_truthy(func, timeout_sec=5.0, interval_sec=0.5):
    started = time.time()
    original_error = None
    while time.time() - started < timeout_sec:
        original_error = None
        try:
            result = func()
            if result:
                return result
        except Exception as e:
            original_error = e
        time.sleep(interval_sec)
    if original_error is None:
        raise TimeoutError(f'Condition unmet after {timeout_sec}s timeout')
    raise original_error


def test_feature_status_page_search(driver):
    driver.get('https://webkit.org/status/')

    # Enter "CSS" into the search box.
    # Ensures that at least one result appears in search
    # !!! Remember there are no ID and NAME locators in W3C standard
    # These two have been superseded by CSS ones
    search_box = driver.find_element_by_css('#search')
    search_box.send_keys('CSS')
    value = search_box.get_attribute('value')
    assert len(value) > 0
    search_box.submit()
    # Count the visible results when filters are applied
    # so one result shows up in at most one filter
    assert wait_until_truthy(
        lambda: len(driver.execute_script("return document.querySelectorAll('li.feature:not(.is-hidden)')")) > 0)


def test_feature_status_page_filters(driver):
    driver.get('https://webkit.org/status/')

    assert wait_until_truthy(
        lambda: len(driver.execute_script("return document.querySelectorAll('.filter-toggle')")) == 7)

    # Make sure every filter is turned off.
    for checked_filter in filter(lambda f: f.is_selected(), filters):
        checked_filter.click()

    # Make sure you can select every filter.
    for filt in filters:
        filt.click()
        assert filt.is_selected()
        filt.click()
```


## Development

```bash
# clone repo, then in repo dir:
npm install
gulp watch
```

