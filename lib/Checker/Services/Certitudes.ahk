/**
 * @description Certitudes.org service implementation with dual-mode support
 * Handles both coordinate and answer modes by detecting field maxlength attribute
 * Includes clipboard support for copying owner messages from hint spans
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class CertitudesService extends BaseService {
    /**
     * Constructor for Certitudes service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "certitudes"
    }

    /**
     * Smart coordinate filling that detects coordinate vs answer mode
     * Uses maxlength attribute to determine if coordinates should be filled
     * If service has comment (certitudes|comment), fills the answer field
     * @override
     */
    executeCoordinateFilling() {
        ; Check if service name contains a comment (format: "certitudes|comment")
        comment := ""
        if (InStr(this.app.service, "|")) {
            parts := StrSplit(this.app.service, "|")
            if (parts.Length >= 2) {
                comment := Trim(parts[2])
            }
        }

        ; For certitudes.org - check mode first (coordinates vs answer) using maxlength attribute
        this.app.updateStatusLeft("Checking certitudes.org mode...")

        ; Build JavaScript code to check for maxlength and conditionally fill
        if (comment != "") {
            ; We have a comment - force answer mode and fill the answer
            ; Escape the comment for safe JavaScript injection
            escapedComment := StrReplace(comment, "'", "\'")
            escapedComment := StrReplace(escapedComment, "`"", "\`"")
            escapedComment := StrReplace(escapedComment, "`n", "\n")
            escapedComment := StrReplace(escapedComment, "`r", "\r")

            this.app.updateStatusLeft("Certitudes.org loaded - Filling answer: " . comment)
            
            jsCode := "try { " .
                      "var solutionField = document.querySelector('input[name=`"coordinates`"]'); " .
                      "if (solutionField) { " .
                      "var maxLength = solutionField.getAttribute('maxlength'); " .
                      "if (maxLength && parseInt(maxLength) > 100) { " .
                      ; Answer mode detected - fill the provided answer
                      "solutionField.value = '" . escapedComment . "'; " .
                      "solutionField.dispatchEvent(new Event('input', { bubbles: true })); " .
                      "solutionField.dispatchEvent(new Event('change', { bubbles: true })); " .
                      "'SUCCESS: Certitudes answer field filled with: " . escapedComment . "'; " .
                      "} else { " .
                      "'ERROR: Certitudes is in coordinate mode but answer was provided - maxlength=' + maxLength; " .
                      "} " .
                      "} else { " .
                      "'ERROR: coordinates field not found on certitudes page'; " .
                      "} " .
                      "} catch (e) { " .
                      "'ERROR: ' + e.message; " .
                      "}"
        } else {
            ; No comment - use original logic (coordinate mode or detect answer mode)
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
        }

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript for Certitudes.org result detection
     * Checks for woohoo.png (success), doh.png (wrong), or hint span content
     * @returns {String} JavaScript code for Certitudes result detection
     * @override
     */
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

    /**
     * Copies owner's message from hint span to clipboard
     * Extracts text content from span.hint element
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy certitudes owner's message from hint span
        this.app.updateStatus(Translation.get("executing_clipboard") . " certitudes...")
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