/**
 * @description puzzlechecker.de coordinate checker service implementation
 * Dual-mode service supporting both coordinate input and answer input with clipboard message support
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class PuzzlecheckerService extends BaseService {
    /**
     * Constructor for puzzlechecker.de service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "puzzlechecker"
    }

    /**
     * Intelligently detects mode (coordinate vs answer) and fills appropriate fields with radio button support
     * @override
     */
    executeCoordinateFilling() {
        ; For puzzlechecker.de - check mode first (coordinates vs answer)
        this.app.updateStatusLeft("Checking puzzlechecker.de mode...")

        ; Build JavaScript code to check for secret field and conditionally fill
        jsCode := "try { " .
                  "var secretField = document.querySelector('input[name=`"secret`"]'); " .
                  "if (secretField) { " .
                  "'SUCCESS: Puzzlechecker in answer mode - secret field detected, skipping coordinate filling'; " .
                  "} else { " .
                  ; No secret field, proceed with coordinate filling
                  "var success = true; " .
                  "var errors = []; " .

                  ; Set latitude direction radio button (N/S)
                  "var latRadios = document.getElementsByName('latdir'); " .
                  "var latRadioSet = false; " .
                  "for (var i = 0; i < latRadios.length; i++) { " .
                  "  if (latRadios[i].value === '" . this.app.lat . "') { " .
                  "    latRadios[i].checked = true; " .
                  "    latRadioSet = true; " .
                  "    break; " .
                  "  } " .
                  "} " .
                  "if (!latRadioSet) errors.push('Latitude radio " . this.app.lat . " not found'); " .

                  ; Set longitude direction radio button (E/W)
                  "var longRadios = document.getElementsByName('longdir'); " .
                  "var longRadioSet = false; " .
                  "for (var i = 0; i < longRadios.length; i++) { " .
                  "  if (longRadios[i].value === '" . this.app.lon . "') { " .
                  "    longRadios[i].checked = true; " .
                  "    longRadioSet = true; " .
                  "    break; " .
                  "  } " .
                  "} " .
                  "if (!longRadioSet) errors.push('Longitude radio " . this.app.lon . " not found'); " .

                  ; Fill latitude fields - lat1 (degrees), lat2 (minutes), lat3 (decimal minutes)
                  "var lat1 = document.getElementsByName('lat1')[0]; " .
                  "if (lat1) { lat1.value = '" . this.app.latdeg . "'; } else { errors.push('lat1 field not found'); } " .
                  "var lat2 = document.getElementsByName('lat2')[0]; " .
                  "if (lat2) { lat2.value = '" . this.app.latmin . "'; } else { errors.push('lat2 field not found'); } " .
                  "var lat3 = document.getElementsByName('lat3')[0]; " .
                  "if (lat3) { lat3.value = '" . this.app.latdec . "'; } else { errors.push('lat3 field not found'); } " .

                  ; Fill longitude fields - long1 (degrees), long2 (minutes), long3 (decimal minutes)
                  "var long1 = document.getElementsByName('long1')[0]; " .
                  "if (long1) { long1.value = '" . Format("{:03d}", Integer(this.app.londeg)) . "'; } else { errors.push('long1 field not found'); } " .
                  "var long2 = document.getElementsByName('long2')[0]; " .
                  "if (long2) { long2.value = '" . this.app.lonmin . "'; } else { errors.push('long2 field not found'); } " .
                  "var long3 = document.getElementsByName('long3')[0]; " .
                  "if (long3) { long3.value = '" . this.app.londec . "'; } else { errors.push('long3 field not found'); } " .

                  ; Trigger change events on fields (without focus to avoid stealing)
                  "var allFields = [lat1, lat2, lat3, long1, long2, long3]; " .
                  "allFields.forEach(function(field) { " .
                  "  if (field) { " .
                  "    field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "  } " .
                  "}); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: Puzzlechecker coordinate fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . "'; " .
                  "} " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript code to detect puzzlechecker.de success/failure using paragraph color classes
     * @returns {String} JavaScript code for result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for puzzlechecker.de specific success/failure patterns
        return "try { " .
               "var successElement = document.querySelector('p.greenb'); " .
               "var wrongElement = document.querySelector('p.redb'); " .
               "if (successElement && successElement.textContent) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (wrongElement && wrongElement.textContent) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Copies puzzlechecker.de owner message from h3 element with special parsing for coordinates text
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy puzzlechecker.de owner's message from specific h3 element
        this.app.updateStatus("Executing clipboard JavaScript for puzzlechecker.de...")
        jsCode := "try { " .
                  "var h3Element = document.querySelector('body > div > div.content > div > div.tipblock > h3'); " .
                  "if (h3Element) { " .
                  "var fullText = h3Element.textContent || h3Element.innerText; " .
                  "if (fullText) { " .
                  ; Simple approach: find 'Coordinates:' and extract everything after it
                  "var infoIndex = fullText.indexOf('Coordinates:'); " .
                  "if (infoIndex !== -1) { " .
                  "var messageText = fullText.substring(infoIndex + 12).trim(); " .
                  "messageText = messageText.replace(/\\n/g, ' ').replace(/\\t/g, ' ').replace(/\\s+/g, ' ').trim(); " .
                  "if (messageText.length > 0) { " .
                  "'CLIPBOARD:' + messageText; " .
                  "} else { " .
                  "'CLIPBOARD:NO_TEXT_AFTER_INFO'; " .
                  "} " .
                  "} else { " .
                  ; Fallback: return the entire h3 content cleaned up
                  "var cleanedText = fullText.replace(/\\n/g, ' ').replace(/\\t/g, ' ').replace(/\\s+/g, ' ').trim(); " .
                  "'CLIPBOARD:' + cleanedText; " .
                  "} " .
                  "} else { " .
                  "'CLIPBOARD:NO_TEXT'; " .
                  "} " .
                  "} else { " .
                  "'CLIPBOARD:NO_ELEMENT'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.app.webView.ExecuteScriptAsync(jsCode)
            .then((result) => this.app.onClipboardResult(result))
            .catch((error) => this.app.onClipboardError(error))

        return true
    }
}