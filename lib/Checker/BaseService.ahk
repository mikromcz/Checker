/**
 * @description Base class for coordinate checker services. Provides common functionality
 * for filling coordinates and checking results across different geocaching coordinate
 * verification websites.
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 */
class BaseService {
    /**
     * Constructor for BaseService
     * @param {Object} checkerApp Reference to the main Checker application instance
     */
    __New(checkerApp) {
        this.app := checkerApp
        this.serviceName := ""
        this.isDead := false
    }

    /**
     * Main entry point for filling coordinates into service forms
     * Validates coordinates and calls service-specific implementation
     */
    fillFields() {
        if (this.isDead) {
            this.showDeadServiceMessage()
            return
        }

        if (!this.app.hasValidCoordinates()) {
            this.app.updateStatus("No valid coordinates to fill")
            return
        }

        this.executeCoordinateFilling()
    }

    /**
     * Service-specific coordinate filling implementation
     * Override in child classes to implement service-specific behavior
     * @abstract
     */
    executeCoordinateFilling() {
        ; Default implementation - show error message
        this.app.updateStatus("Error: executeCoordinateFilling() not implemented for " . this.serviceName)
    }

    /**
     * Formats coordinates for geochecker-style services
     * @returns {String} Formatted coordinate string like "S50 15.123 W015 54.123"
     */
    formatCoordinatesForGeochecker() {
        ; Format: "S50 15.123 W015 54.123"
        latMinDec := this.app.latmin . "." . this.app.latdec
        lonMinDec := this.app.lonmin . "." . this.app.londec

        coordString := this.app.lat . this.app.latdeg . " " . latMinDec . " "
        coordString .= this.app.lon . Format("{:03d}", Integer(this.app.londeg)) . " " . lonMinDec

        return coordString
    }

    /**
     * Formats coordinates for gzchecker service
     * @returns {String} Formatted coordinate string like "N 51 45.000 E 0 45.000"
     */
    formatCoordinatesForGzchecker() {
        ; Format for gzchecker: "N 51 45.000 E 0 45.000"
        latMinDec := this.app.latmin . "." . this.app.latdec
        lonMinDec := this.app.lonmin . "." . this.app.londec

        ; Ensure 3 decimal places for minutes
        latMinDecFormatted := Format("{:.3f}", Float(latMinDec))
        lonMinDecFormatted := Format("{:.3f}", Float(lonMinDec))

        coordString := this.app.lat . " " . this.app.latdeg . " " . latMinDecFormatted . " "
        coordString .= this.app.lon . " " . Integer(this.app.londeg) . " " . lonMinDecFormatted

        return coordString
    }

    /**
     * Executes JavaScript code in the WebView2 control
     * @param {String} jsCode JavaScript code to execute
     */
    executeJavaScript(jsCode) {
        this.app.webView.ExecuteScriptAsync(jsCode)
            .then((result) => this.app.onCoordinatesFilled(result))
            .catch((error) => this.app.onCoordinatesError(error))
    }

    /**
     * Common pattern for filling a single coordinate field
     * @param {String} fieldId HTML element ID or name to fill (default: "LatLonString")
     * @param {String} fieldName Display name for status messages (default: serviceName)
     */
    fillSingleLatLonField(fieldId := "LatLonString", fieldName := "") {
        coordString := this.formatCoordinatesForGeochecker()
        serviceName := fieldName ? fieldName : this.serviceName

        this.app.updateStatusLeft("Filling " . serviceName . " coordinates: " . coordString)

        jsCode := "try { " .
                  "var field = document.getElementById('" . fieldId . "'); " .
                  "if (!field) field = document.getElementsByName('" . fieldId . "')[0]; " .
                  "if (field) { " .
                  "field.value = '" . coordString . "'; " .
                  "field.focus(); " .
                  "field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "'SUCCESS: " . serviceName . " " . fieldId . " field filled with: ' + field.value; " .
                  "} else { " .
                  "'ERROR: " . fieldId . " field not found on " . serviceName . " page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript code for checking coordinate verification results
     * Override in child classes for service-specific result detection
     * @returns {String} JavaScript code that returns "RESULT:SUCCESS", "RESULT:WRONG", or "RESULT:NONE"
     */
    buildResultCheckingJS() {
        if (this.isDead) {
            return "try { 'RESULT:NONE'; } catch (e) { 'ERROR: ' + e.message; }"
        }

        ; Default geochecker-style result checking
        return this.buildGeocheckerStyleResultJS()
    }

    /**
     * JavaScript for detecting geochecker-style success/failure divs
     * @returns {String} JavaScript code for standard geochecker result detection
     */
    buildGeocheckerStyleResultJS() {
        return "try { " .
               "var success = document.querySelector('div.success'); " .
               "var wrong = document.querySelector('div.wrong'); " .
               "if (success && success.textContent.includes('Success')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (wrong && wrong.textContent.includes('Incorrect')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Generic result detection for services without specific selectors
     * @returns {String} JavaScript code for generic text-based result detection
     */
    buildGenericResultJS() {
        return "try { " .
               "var body = document.body.innerHTML; " .
               "if (body.includes('SUCCESS') || body.includes('Congratulations') || body.includes('Correct')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (body.includes('INCORRECT') || body.includes('Wrong') || body.includes('Failed')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Displays message for services that are no longer available
     */
    showDeadServiceMessage() {
        this.app.updateStatus("Warning: " . this.serviceName . " service is no longer available. Cannot fill/check anything. Contact cache author to change verification service.")
        this.app.finalExitCode := 0
    }

    /**
     * Copies owner message to clipboard for services that support it
     * Override in child classes that support clipboard functionality
     * @returns {Boolean} True if message was copied, false otherwise
     */
    copyOwnerMessage() {
        ; Override in child classes that support clipboard
        return false
    }
}