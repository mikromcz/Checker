/**
 * @description nanochecker.de coordinate checker service implementation
 * Question-based checker that requires manual interaction instead of coordinate filling
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class NanocheckerService extends BaseService {
    /**
     * Constructor for nanochecker.de service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "nanochecker"
    }

    /**
     * Handles nanochecker service - fills comment if provided, otherwise just loads the question
     * @override
     */
    executeCoordinateFilling() {
        ; Check if service name contains a comment (format: "nanochecker|comment")
        comment := ""
        if (InStr(this.app.service, "|")) {
            parts := StrSplit(this.app.service, "|")
            if (parts.Length >= 2) {
                comment := Trim(parts[2])
            }
        }

        if (comment != "") {
            ; Fill the comment in the input field
            this.app.updateStatusLeft("Nanochecker.de loaded - Filling comment: " . comment)
            this.app.updateStatus("Nanochecker: Filling comment into input field...")

            ; Escape the comment for safe JavaScript injection
            escapedComment := StrReplace(comment, "'", "\'")
            escapedComment := StrReplace(escapedComment, "`"", "\`"")
            escapedComment := StrReplace(escapedComment, "`n", "\n")
            escapedComment := StrReplace(escapedComment, "`r", "\r")

            ; JavaScript to fill the comment into the nanochecker input field
            js := "try { " .
                  "var inputField = document.querySelector('#nc-content > form > input:nth-child(1)'); " .
                  "if (inputField) { " .
                  "inputField.value = '" . escapedComment . "'; " .
                  "inputField.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "'SUCCESS: Comment filled'; " .
                  "} else { " .
                  "'ERROR: Input field not found'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

            ; Execute the JavaScript to fill the comment
            result := this.app.webView.executeScript(js)
            
            ; Update status based on result
            if (InStr(result, "SUCCESS")) {
                this.app.updateStatus("Nanochecker: Comment filled successfully - Please submit and wait for result")
            } else {
                this.app.updateStatus("Nanochecker: Failed to fill comment - Please fill manually: " . comment)
            }
        } else {
            ; No comment provided - just load the question
            this.app.updateStatusLeft("Nanochecker.de loaded - This service asks a question instead of coordinates")
            this.app.updateStatus("Nanochecker: No comment provided - Please answer the question manually and wait for result")
        }

        ; Mark coordinates as "filled" so result checking can start
        this.app.coordinatesFilled := true

        ; Start result checking if enabled
        if (this.app.settings.answer) {
            this.app.startResultChecking()
        } else {
            this.app.updateStatusRight("Result checking disabled")
        }
    }

    /**
     * Builds JavaScript code to detect nanochecker.de success/failure using CSS classes for green/red text
     * @returns {String} JavaScript code for result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for nanochecker.de specific success/failure patterns
        return "try { " .
               "var successElement = document.querySelector('p.nc-index-p-small.nc-text-green'); " .
               "var wrongElement = document.querySelector('p.nc-index-p-small.nc-text-red'); " .
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
}