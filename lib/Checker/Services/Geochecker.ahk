/**
 * @description Standard Geochecker.com service implementation
 * Handles coordinate verification for geochecker.com coordinate checkers
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GeocheckerService extends BaseService {
    /**
     * Constructor for Geochecker service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "geochecker"
    }

    /**
     * Fills coordinates using standard LatLonString field
     * @override
     */
    executeCoordinateFilling() {
        this.fillSingleLatLonField("LatLonString", "Geochecker")
    }

    /**
     * Builds JavaScript for Geochecker.com result detection
     * @returns {String} JavaScript code to detect success/wrong divs
     * @override
     */
    buildResultCheckingJS() {
        ; Check for geochecker.com specific success/failure divs
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
}