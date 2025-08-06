class GeocacheplannerService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "geocacheplanner"
    }

    executeCoordinateFilling() {
        ; For geocacheplanner.com - separate coordinate fields
        this.app.updateStatusLeft("Filling geocacheplanner.com form...")

        ; Build JavaScript code to fill separate coordinate fields
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Fill latitude fields - NORD1 (degrees), NORD2 (minutes), NORD3 (decimal minutes)
                  "var nord1 = document.getElementById('NORD1'); " .
                  "if (nord1) { nord1.value = '" . this.app.latdeg . "'; } else { errors.push('NORD1 field not found'); } " .
                  "var nord2 = document.getElementById('NORD2'); " .
                  "if (nord2) { nord2.value = '" . this.app.latmin . "'; } else { errors.push('NORD2 field not found'); } " .
                  "var nord3 = document.getElementById('NORD3'); " .
                  "if (nord3) { nord3.value = '" . this.app.latdec . "'; } else { errors.push('NORD3 field not found'); } " .

                  ; Fill longitude fields - OST1 (degrees), OST2 (minutes), OST3 (decimal minutes)
                  "var ost1 = document.getElementById('OST1'); " .
                  "if (ost1) { ost1.value = '" . Format("{:03d}", Integer(this.app.londeg)) . "'; } else { errors.push('OST1 field not found'); } " .
                  "var ost2 = document.getElementById('OST2'); " .
                  "if (ost2) { ost2.value = '" . this.app.lonmin . "'; } else { errors.push('OST2 field not found'); } " .
                  "var ost3 = document.getElementById('OST3'); " .
                  "if (ost3) { ost3.value = '" . this.app.londec . "'; } else { errors.push('OST3 field not found'); } " .

                  ; Trigger change events on all fields (without focus to avoid stealing)
                  "var allFields = [nord1, nord2, nord3, ost1, ost2, ost3]; " .
                  "allFields.forEach(function(field) { " .
                  "  if (field) { " .
                  "    field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "  } " .
                  "}); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: Geocacheplanner fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . "'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    buildResultCheckingJS() {
        ; Check for geocacheplanner specific success/failure patterns
        return "try { " .
               "var body = document.body.innerHTML; " .
               "if (body.includes('Das war wohl nix') || body.includes('bitte nochmal genau nach rechnen') || body.includes('Nochmal versuchen')) { " .
               "'RESULT:WRONG'; " .
               "} else if (body.includes('richtig') || body.includes('correct') || body.includes('Success') || body.includes('Glückwunsch') || body.includes('geschafft')) { " .
               "'RESULT:SUCCESS'; " .
               "} else { " .
               "var success = document.querySelector('div.success, .success, span.success'); " .
               "var wrong = document.querySelector('div.wrong, .wrong, span.wrong, div.error, .error'); " .
               "if (success && success.textContent) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (wrong && wrong.textContent) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}