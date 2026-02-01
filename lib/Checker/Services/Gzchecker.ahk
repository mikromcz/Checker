/**
 * @description GZChecker gzchecker.de service implementation
 * Uses specialized coordinate format and includes clipboard support
 * for copying owner messages after successful verification
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GZCheckerService extends BaseService {
    /**
     * Constructor for GZChecker service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gzchecker"
    }

    /**
     * Fills GZChecker LLall field using specialized coordinate format
     * Format: "N 51 45.000 E 0 45.000"
     * @override
     */
    executeCoordinateFilling() {
        ; For gzchecker.de - LLall field with format "N 51 45.000 E 0 45.000"
        coordString := this.formatCoordinatesForGzchecker()
        this.app.updateStatusLeft("Filling gzchecker coordinates: " . coordString)

        jsCode := "try { " .
                  "var field = document.getElementById('LLall'); " .
                  "if (!field) field = document.getElementsByName('LLall')[0]; " .
                  "if (field) { " .
                  "field.value = '" . coordString . "'; " .
                  "field.focus(); " .
                  "field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "'SUCCESS: GZChecker LLall field filled with: ' + field.value; " .
                  "} else { " .
                  "'ERROR: LLall field not found on gzchecker page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript for GZChecker result detection
     * Uses specific table selectors and div#Failed element
     * @returns {String} JavaScript code for GZChecker result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for gzchecker success/failure using specific selectors
        return "try { " .
               "var successElement = document.querySelector('body > div > table > tbody > tr:nth-child(3) > td > div:nth-child(1) > p:nth-child(3)'); " .
               "var failureElement = document.querySelector('div#Failed'); " .
               "if (successElement && successElement.textContent.includes('CORRECT')) { " .
               "  'RESULT:SUCCESS'; " .
               "} else if (failureElement && failureElement.textContent.includes('NOT CORRECT')) { " .
               "  'RESULT:WRONG'; " .
               "} else { " .
               "  'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Copies owner's message from GZChecker results page
     * Uses specific table selectors with fallback to search all paragraphs
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy gzchecker owner's message using specific selector
        this.app.updateStatus(Translation.get("executing_clipboard") . " gzchecker...")
        jsCode := "try { " .
                  "var messageElement = document.querySelector('body > div > table > tbody > tr:nth-child(3) > td > div:nth-child(1) > p:nth-child(5)'); " .
                  "if (messageElement) { " .
                  "var messageText = messageElement.textContent || messageElement.innerText; " .
                  "if (messageText) { " .
                  "messageText = messageText.replace(/\\s+/g, ' ').trim(); " .
                  "'CLIPBOARD:' + messageText; " .
                  "} else { " .
                  "'CLIPBOARD:NO_TEXT'; " .
                  "} " .
                  "} else { " .
                  "var allPs = document.querySelectorAll('p'); " .
                  "var foundMessage = ''; " .
                  "for (var i = 0; i < allPs.length; i++) { " .
                  "var pText = allPs[i].textContent || allPs[i].innerText; " .
                  "if (pText && (pText.includes('Go to') || pText.includes('location') || pText.includes('compromised'))) { " .
                  "foundMessage = pText.replace(/\\s+/g, ' ').trim(); " .
                  "break; " .
                  "} " .
                  "} " .
                  "if (foundMessage) { " .
                  "'CLIPBOARD:' + foundMessage; " .
                  "} else { " .
                  "'CLIPBOARD:NO_ELEMENT'; " .
                  "} " .
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