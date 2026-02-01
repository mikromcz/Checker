/**
 * @description gccheck.com coordinate checker service implementation
 * Uses specific format N50° 20.200 E12° 22.000 and includes clipboard support for owner messages
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GccheckService extends BaseService {
    /**
     * Constructor for gccheck.com service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gccheck"
    }

    /**
     * Fills gccheck.com realcoords field using degree-based coordinate format with automatic captcha focus
     * @override
     */
    executeCoordinateFilling() {
        ; For gccheck.com - uses 'realcoords' field with format "N50° 20.200 E12° 22.000"
        this.app.updateStatusLeft("Filling gccheck.com form...")

        ; Format coordinates for gccheck: N50° 20.200 E12° 22.000
        latMinDec := this.app.latmin . "." . this.app.latdec
        lonMinDec := this.app.lonmin . "." . this.app.londec
        coordString := this.app.lat . this.app.latdeg . "° " . latMinDec . " " . this.app.lon . Format("{:03d}", Integer(this.app.londeg)) . "° " . lonMinDec

        ; Build JavaScript code to fill the realcoords field
        jsCode := "try { " .
                  "var field = document.getElementsByName('realcoords')[0]; " .
                  "if (!field) field = document.querySelector('input.coordsinput[name=`"realcoords`"]'); " .
                  "if (field) { " .
                  "field.value = '" . coordString . "'; " .
                  "field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "} " .

                  ; Focus captcha field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementsByName('captcha')[0]; " .
                  "if (!captchaField) captchaField = document.getElementById('captcha'); " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .

                  "if (field) { " .
                  "'SUCCESS: Gccheck realcoords field filled with: ' + field.value + ' - Captcha focused'; " .
                  "} else { " .
                  "'ERROR: realcoords field not found on gccheck page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript code to detect gccheck.com success/failure using span elements
     * @returns {String} JavaScript code for result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for gccheck.com specific success/failure elements
        return "try { " .
               "var congrats = document.querySelector('span#congrats'); " .
               "var nope = document.querySelector('span#nope'); " .
               "if (congrats && congrats.textContent) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (nope && nope.textContent) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Copies gccheck.com owner message from div#hint element to clipboard
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy gccheck.com owner's message from div#hint element
        this.app.updateStatus(Translation.get("executing_clipboard") . " gccheck.com...")
        jsCode := "try { " .
                  "var messageElement = document.querySelector('div#hint'); " .
                  "if (messageElement) { " .
                  "var messageText = messageElement.textContent || messageElement.innerText; " .
                  "if (messageText) { " .
                  "messageText = messageText.replace(/\\\\\\\\s+/g, ' ').trim(); " .
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