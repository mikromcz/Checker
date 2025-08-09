/**
 * @description geocache.fi coordinate checker service implementation
 * Uses complex form with dropdown selections (N/S, E/W) and separate coordinate fields with multi-language support
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GeocachefiService extends BaseService {
    /**
     * Constructor for geocache.fi service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "geocachefi"
    }

    /**
     * Fills geocache.fi complex form with dropdowns and separate coordinate fields
     * @override
     */
    executeCoordinateFilling() {
        ; For geocache.fi - dropdown selections plus separate coordinate fields (new structure)
        this.app.updateStatusLeft("Filling geocache.fi form...")

        ; Build JavaScript code to fill dropdowns and coordinate fields
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Set latitude direction dropdown (N/S)
                  "var nsDropdown = document.getElementsByName('ns')[0]; " .
                  "if (nsDropdown) { " .
                  "  for (var i = 0; i < nsDropdown.options.length; i++) { " .
                  "    if (nsDropdown.options[i].value === '" . this.app.lat . "') { " .
                  "      nsDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('N/S dropdown not found'); } " .

                  ; Set longitude direction dropdown (E/W)
                  "var ewDropdown = document.getElementsByName('ew')[0]; " .
                  "if (ewDropdown) { " .
                  "  for (var i = 0; i < ewDropdown.options.length; i++) { " .
                  "    if (ewDropdown.options[i].value === '" . this.app.lon . "') { " .
                  "      ewDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('E/W dropdown not found'); } " .

                  ; Fill latitude fields - cachelat1 (degrees), cachelat2 (minutes), cachelat3 (decimal)
                  "var cachelat1 = document.getElementsByName('cachelat1')[0]; " .
                  "if (cachelat1) { cachelat1.value = '" . this.app.latdeg . "'; } else { errors.push('cachelat1 field not found'); } " .
                  "var cachelat2 = document.getElementsByName('cachelat2')[0]; " .
                  "if (cachelat2) { cachelat2.value = '" . this.app.latmin . "'; } else { errors.push('cachelat2 field not found'); } " .
                  "var cachelat3 = document.getElementsByName('cachelat3')[0]; " .
                  "if (cachelat3) { cachelat3.value = '" . this.app.latdec . "'; } else { errors.push('cachelat3 field not found'); } " .

                  ; Fill longitude fields - cachelon1 (degrees), cachelon2 (minutes), cachelon3 (decimal)
                  "var cachelon1 = document.getElementsByName('cachelon1')[0]; " .
                  "if (cachelon1) { cachelon1.value = '" . this.app.londeg . "'; } else { errors.push('cachelon1 field not found'); } " .
                  "var cachelon2 = document.getElementsByName('cachelon2')[0]; " .
                  "if (cachelon2) { cachelon2.value = '" . this.app.lonmin . "'; } else { errors.push('cachelon2 field not found'); } " .
                  "var cachelon3 = document.getElementsByName('cachelon3')[0]; " .
                  "if (cachelon3) { cachelon3.value = '" . this.app.londec . "'; } else { errors.push('cachelon3 field not found'); } " .

                  ; Trigger change events on dropdowns and fields (without focus to avoid stealing)
                  "var allElements = [nsDropdown, ewDropdown, cachelat1, cachelat2, cachelat3, cachelon1, cachelon2, cachelon3]; " .
                  "allElements.forEach(function(element) { " .
                  "  if (element) { " .
                  "    element.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "    if (element.tagName === 'INPUT') { " .
                  "      element.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    } " .
                  "  } " .
                  "}); " .

                  ; Focus captcha field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementsByName('seccode')[0]; " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: Geocache.fi fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . " - Captcha focused'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript code to detect geocache.fi success/failure with Finnish and English language support
     * @returns {String} JavaScript code for result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for geocache.fi specific success/failure patterns
        return "try { " .
               "var successFont = document.querySelector('font[color=`"#00AA00`"]'); " .
               "if (successFont && (successFont.textContent.includes('GREAT!') || successFont.textContent.includes('AWESOME!') || successFont.textContent.includes('SPECTACULAR!') || successFont.textContent.includes('SE ON SIINÄ!') || successFont.textContent.includes('SÄ TEIT SEN!'))) { " .
               "'RESULT:SUCCESS'; " .
               "} else { " .
               "var body = document.body.innerHTML; " .
               "if (body.includes('Incorrect') || body.includes('Wrong') || body.includes('Väärin')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Copies geocache.fi owner message using complex CSS selector to clipboard
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy geocache.fi owner's message using specific selector
        this.app.updateStatus("Executing clipboard JavaScript for geocache.fi...")
        jsCode := "try { " .
                  "var messageElement = document.querySelector('body > center > table:nth-child(5) > tbody > tr > td > table > tbody > tr:nth-child(1) > td:nth-child(3) > table > tbody > tr:nth-child(2) > td:nth-child(2) > center > table:nth-child(5) > tbody > tr:nth-child(3) > td > table:nth-child(4) > tbody > tr:nth-child(1) > td > p:nth-child(5)'); " .
                  "if (messageElement) { " .
                  "var messageText = messageElement.textContent || messageElement.innerText; " .
                  "if (messageText) { " .
                  "messageText = messageText.replace(/\\s+/g, ' ').trim(); " .
                  "'CLIPBOARD:' + messageText; " .
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