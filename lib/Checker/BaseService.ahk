class BaseService {
    __New(checkerApp) {
        this.app := checkerApp
        this.serviceName := ""
        this.isDead := false
    }

    ; Main entry point for filling coordinates
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

    ; Override in child classes
    executeCoordinateFilling() {
        ; Default implementation - show error message
        this.app.updateStatus("Error: executeCoordinateFilling() not implemented for " . this.serviceName)
    }

    ; Common coordinate formatting methods
    formatCoordinatesForGeochecker() {
        ; Format: "S50 15.123 W015 54.123"
        latMinDec := this.app.latmin . "." . this.app.latdec
        lonMinDec := this.app.lonmin . "." . this.app.londec

        coordString := this.app.lat . this.app.latdeg . " " . latMinDec . " "
        coordString .= this.app.lon . Format("{:03d}", Integer(this.app.londeg)) . " " . lonMinDec

        return coordString
    }

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

    ; Common JavaScript execution wrapper
    executeJavaScript(jsCode) {
        this.app.webView.ExecuteScriptAsync(jsCode)
            .then((result) => this.app.onCoordinatesFilled(result))
            .catch((error) => this.app.onCoordinatesError(error))
    }

    ; Common single field filling pattern (LatLonString)
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

    ; Common result checking patterns
    buildResultCheckingJS() {
        if (this.isDead) {
            return "try { 'RESULT:NONE'; } catch (e) { 'ERROR: ' + e.message; }"
        }

        ; Default geochecker-style result checking
        return this.buildGeocheckerStyleResultJS()
    }

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

    ; Dead service handler
    showDeadServiceMessage() {
        this.app.updateStatus("Warning: " . this.serviceName . " service is no longer available. Cannot fill/check anything. Contact cache author to change verification service.")
        this.app.finalExitCode := 0
    }

    ; Clipboard functionality
    copyOwnerMessage() {
        ; Override in child classes that support clipboard
        return false
    }
}