class CertitudesService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "certitudes"
    }

    executeCoordinateFilling() {
        ; For certitudes.org - check mode first (coordinates vs answer) using maxlength attribute
        this.app.updateStatusLeft("Checking certitudes.org mode...")

        ; Build JavaScript code to check for maxlength and conditionally fill
        jsCode := "try { " .
                  "var solutionField = document.querySelector('input[name=`"coordinates`"]'); " .
                  "if (solutionField) { " .
                  "var maxLength = solutionField.getAttribute('maxlength'); " .
                  "if (maxLength && parseInt(maxLength) > 100) { " .
                  "'SUCCESS: Certitudes in answer mode - maxlength=' + maxLength + ' detected, skipping coordinate filling'; " .
                  "} else { " .
                  ; No maxlength or small maxlength, proceed with coordinate filling
                  "var coordString = '" . this.formatCoordinatesForGeochecker() . "'; " .
                  "solutionField.value = coordString; " .
                  "solutionField.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "solutionField.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "'SUCCESS: Certitudes coordinate field filled with: ' + coordString; " .
                  "} " .
                  "} else { " .
                  "'ERROR: coordinates field not found on certitudes page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    buildResultCheckingJS() {
        ; Check for certitudes.org specific success/failure images or hint spans
        return "try { " .
               "var woohooImg = document.querySelector('img[src*=`"woohoo.png`"]'); " .
               "var dohImg = document.querySelector('img[src*=`"doh.png`"]'); " .
               "var hintSpan = document.querySelector('span.hint'); " .
               "if (woohooImg || (hintSpan && hintSpan.textContent)) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (dohImg) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    copyOwnerMessage() {
        ; Copy certitudes owner's message from hint span
        this.app.updateStatus("Executing clipboard JavaScript for certitudes...")
        jsCode := "try { " .
                  "var hintElement = document.querySelector('span.hint'); " .
                  "if (hintElement) { " .
                  "var messageText = hintElement.textContent || hintElement.innerText; " .
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