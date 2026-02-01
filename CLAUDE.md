# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Checker is a coordinate verification tool for geocaching services, built with AutoHotkey v2 and WebView2. It automates the process of submitting coordinates to various geocaching coordinate checker websites and verifies the results. Originally an AutoHotkey v1 application using Internet Explorer, it has been modernized to use WebView2 for better compatibility with current web standards.

The application features a modular architecture with service-specific implementations in separate files under `lib/Checker/` for better maintainability and extensibility.

## Translation Support

The application uses an external INI-based translation system located in `lib/Checker/lang/`:

### Supported Languages
- **English** (en.ini) - default/fallback
- **Czech** (cs.ini) - language code 0405
- **Slovak** (sk.ini) - language code 041B
- **Polish** (pl.ini) - language code 0415
- **German** (de.ini) - language codes 0407, 0807, 0C07

### Language Selection
1. **Manual override**: Set `language=xx` in `Checker.ini` (e.g., `language=de`)
2. **Auto-detect**: If no manual setting, detects from Windows system language
3. **Fallback**: English is used if language not found

### Adding New Languages
1. Copy `lib/Checker/lang/en.ini` to `xx.ini` (where xx is language code)
2. Translate all values in the `[Strings]` section
3. Add the Windows language code mapping in `Translation.init()` in `Translation.ahk`

### Technical Notes
- INI files must be saved as **UTF-8 with BOM** for proper character display
- Uses `FileRead` with UTF-8 encoding (not `IniRead`) to properly handle special characters
- Language can be changed in Preferences dialog (requires app restart)

## Command Line Usage

The application accepts exactly **10 parameters** in this format:
```
Checker.exe service lat latdeg latmin latdec lon londeg lonmin londec url
```

### Parameter Validation
The application now includes **comprehensive parameter validation** that checks:

- **Parameter count**: Exactly 10 parameters required
- **Coordinate directions**: `lat` must be N or S, `lon` must be E or W  
- **Numeric values**: All coordinate numbers (latdeg, latmin, latdec, londeg, lonmin, londec) must be valid numbers
- **Value ranges**: 
  - Latitude degrees: 0-90
  - Longitude degrees: 0-180  
  - Minutes: 0-59 for both lat and lon

### Error Handling
When invalid parameters are provided:
- Application displays a styled error page with specific error messages
- Shows exactly what parameters were received vs. expected
- Provides usage examples
- Exits with **exit code 4**

Examples:
```
Checker.exe geochecker S 50 15 123 W 015 54 123 "https://geochecker.com/?language=English"
Checker.exe challenge N 49 42 660 E 018 23 165 "http://project-gc.com/Challenges/GC5KDPR/11265"
```

Test files are provided in the `test/` directory with 23+ different service tests:
- `Test.Challenge.bat` - project-gc.com challenges (no coordinate filling required)
- `Test.Certitudes.bat` - certitudes.org with clipboard message support
- `Test.Geochecker.bat` - geochecker.com
- `Test.Geocheck.bat` - geocheck.org
- `Test.Gzchecker.bat` - gzchecker with clipboard support
- `Test.Gcm.bat` - validator.gcm.cz with automatic URL fixing
- `Test.Geocachefi.bat` - geocache.fi
- Plus 16+ additional service test files for comprehensive testing

**All test files now support exit code 4** for invalid parameter detection.

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

### Service URL Language Handling

The `transformServiceUrl()` method in CheckerApp handles language-aware URL transformations:

| Service | Method | Languages |
|---------|--------|-----------|
| geochecker | `?language=` param | English, German |
| geocheck | `changeLocale.php` redirect | cs_CZ, sk_SK, pl_PL, de_DE, en_US |
| certitudes | `?lang=` param | cs_CZ, sk_SK, pl_PL, de_DE, en_GB |
| gc-apps | Path prefix `/en/` or `/de/` | English, German |
| puzzlechecker | `?lang=` param | cs, sk, en |
| geocachefi | `?z=1` (English only) | Finnish, English |

Note: geocheck.org requires a special approach - it uses `changeLocale.php` to set a session cookie, not a URL parameter.

## Exit Codes

The application uses the following exit codes for automation and script integration:

- **0**: Normal exit (user closed window or no result checking)
- **1**: Coordinates are correct ✅
- **2**: Coordinates are wrong ❌  
- **3**: Dead service (service unavailable)
- **4**: Invalid parameters ⚠️ *(NEW)*

**Exit code 4** is returned when:
- Insufficient parameters provided (< 10)
- Invalid coordinate directions (not N/S or E/W)
- Non-numeric coordinate values
- Out-of-range coordinate values

## UI Improvements

### Window Management
- **Resizable window** with minimum size constraints (1000x600)
- **Persistent window size** - automatically saves and restores window dimensions in `Checker.ini`
- **Fixed window size drift bug** - window no longer grows by decoration margins on each run

### Status Display  
- **Enhanced status bar** with colored result indicators
- **Bold text formatting** for correct/wrong results
- **Improved colors**: Dark green (#008000) for correct, red for wrong - better visibility on light backgrounds

### Error Pages
- **Professional error pages** with green color theme when invalid parameters are detected
- **Detailed parameter breakdown** showing exactly what was received vs. expected
- **Multiple usage examples** for different services
- **Specific error messages** explaining exactly what's wrong with the parameters

### Dead Service Pages
- **Custom HTML pages** for discontinued services instead of loading potentially harmful URLs
- Shows warning icon, service name, date when service died, and explanation message
- Prevents loading domains that may contain ads or be for sale
- Sets exit code 3 immediately without network request

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
├── BaseService.ahk             # Base service class (with copyTextFromSelector helper)
├── Services/
│   ├── Challenge.ahk           # Project-GC challenges
│   ├── Certitudes.ahk          # Certitudes.org
│   ├── Geochecker.ahk          # Standard geochecker
│   └── ...                     # Other service implementations
├── Translation.ahk             # Multi-language support (loads from lang/*.ini)
└── lang/
    ├── en.ini                  # English translations (fallback)
    ├── cs.ini                  # Czech translations
    ├── sk.ini                  # Slovak translations
    ├── pl.ini                  # Polish translations
    └── de.ini                  # German translations
```

### Main Application Classes
- **CheckerApp** - Main application window and WebView2 management
- **CheckerSettings** - INI settings load/save management
- **CoordinateValidator** - Command-line parameter validation
- **Translation** - External INI-based translation system