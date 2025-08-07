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

Examples:
```
Checker.exe geochecker S 50 15 123 W 015 54 123 "https://geochecker.com/?language=English"
Checker.exe challenge N 49 42 660 E 018 23 165 "http://project-gc.com/Challenges/GC5KDPR/11265"
```

Test files are provided in the `test/` directory with 25+ different service tests:
- `Test.Challenge.bat` - project-gc.com challenges (no coordinate filling required)
- `Test.Certitudes.bat` - certitudes.org with clipboard message support
- `Test.Geochecker.Correct.bat` / `Test.Geochecker.Incorrect.bat` - geochecker.com
- `Test.Geocheck.Incorrect.bat` - geocheck.org
- `Test.Gzchecker.Correct.bat` / `Test.Gzchecker.Incorrect.bat` - gzchecker
- `Test.Gcm.bat` - validator.gcm.cz
- `Test.Geocachefi.bat` - geocache.fi
- Plus 20+ additional service test files for comprehensive testing

## Supported Services

### Challenge Service (NEW in v4.0.1)

The `challenge` service is specifically designed for Project-GC challenge checkers:

- **No coordinate filling**: This service skips the coordinate filling phase entirely
- **Result detection only**: Uses `challengeFulfilled` and `challengeUnfulfilled` div elements
- **Usage**: `Checker.exe challenge N 49 42 660 E 018 23 165 "http://project-gc.com/Challenges/GC5KDPR/11265"`
- **Detection logic**: 
  - Success: `<div id="challengeFulfilled" class="">` (without hide class)
  - Failure: `<div id="challengeUnfulfilled" class="">` (without hide class)
  - Waiting: Both divs present with `class="hide"`

### Service Categories

**Active Services (16 total):**
- challenge, certitudes, gcappsgeochecker, gcappsmultichecker, gccheck, geocachefi, geocacheplanner, geocheck, geochecker, gcm, gocaching, gpscache, gzchecker, hermansky, nanochecker, puzzlechecker

**Dead Services (9 total):**
- doxina, evince, gccc, gccounter, gccounter2, gctoolbox, geowii, komurka

### Service Features

- **Clipboard support**: Services like certitudes, gzchecker support copying owner messages
- **Dual mode**: Some services support both coordinate and answer verification
- **Language parameters**: Automatic language parameter injection for supported services
- **URL fixing**: Automatic URL correction for legacy service URLs

## Architecture

### Service Implementation
Each service extends `BaseService` and implements:
- `executeCoordinateFilling()` - How to fill coordinate fields
- `buildResultCheckingJS()` - JavaScript to detect success/failure
- `copyOwnerMessage()` - Optional clipboard functionality

### File Structure
```
lib/Checker/
├── ServiceRegistry.ahk          # Service registration and factory
├── BaseService.ahk             # Base service class
├── Services/
│   ├── Challenge.ahk           # Project-GC challenges
│   ├── Certitudes.ahk          # Certitudes.org
│   ├── Geochecker.ahk          # Standard geochecker
│   └── ...                     # Other service implementations
└── Translation.ahk             # Multi-language support
```