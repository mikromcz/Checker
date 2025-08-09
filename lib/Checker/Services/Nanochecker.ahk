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
     * Skips coordinate filling as this service asks questions instead of requiring coordinates
     * @override
     */
    executeCoordinateFilling() {
        ; For nanochecker.de - no coordinates to fill, it asks a question instead
        this.app.updateStatusLeft("Nanochecker.de loaded - This service asks a question instead of coordinates")
        this.app.updateStatus("Nanochecker: No coordinates to fill - Please answer the question manually and wait for result")

        ; No JavaScript to execute since there are no coordinates to fill
        ; The service just displays a question that needs to be answered manually

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