# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Checker is a coordinate verification tool for geocaching services, built with AutoHotkey v2 and WebView2. It automates the process of submitting coordinates to various geocaching coordinate checker websites and verifies the results. Originally an AutoHotkey v1 application using Internet Explorer, it has been modernized to use WebView2 for better compatibility with current web standards.

The application features a modular architecture with service-specific implementations in separate files under `lib/Checker/` for better maintainability and extensibility.

## Translation Support

- Added capability to integrate translation functionality across different coordinate checker services
- Planned enhancement to support multi-language result detection and localization
- Future improvements to include dynamic language parameter handling in service URL configurations

## Command Line Usage

The application accepts geocaching coordinate parameters in this format:
```
Checker.exe service lat latdeg latmin latdec lon londeg lonmin londec url
```

Example:
```
Checker.exe geochecker S 50 15 123 W 015 54 123 "https://geochecker.com/?language=English"
```

Test files are provided in the `test/` directory with 23+ different service tests:
- `Test.Geochecker.Correct.bat` / `Test.Geochecker.Incorrect.bat` - geochecker.com
- `Test.Geocheck.Incorrect.bat` - geocheck.org
- `Test.Gzchecker.Correct.bat` / `Test.Gzchecker.Incorrect.bat` - gzchecker
- `Test.Gcm.bat` - validator.gcm.cz
- `Test.Geocachefi.bat` - geocache.fi
- Plus 18 additional service test files for comprehensive testing

[... rest of the original content remains unchanged ...]