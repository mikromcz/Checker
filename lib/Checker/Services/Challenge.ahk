/**
 * @description Project-GC Challenge checker service implementation
 * This service skips coordinate filling and only performs result detection
 * for Project-GC challenge checkers that don't require coordinate input
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 * @since 4.0.1
 */
class ChallengeService extends BaseService {
    /**
     * Constructor for Challenge service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "challenge"
    }

    /**
     * Skips coordinate filling for challenge services
     * Challenge checkers don't require coordinate input
     * @override
     */
    executeCoordinateFilling() {
        ; Challenge service does not require coordinate filling
        this.app.updateStatusLeft("Challenge service: No coordinates to fill, ready for result checking")
        this.app.coordinatesFilled := true ; Mark as filled so result checking can start

        ; Start result checking if enabled
        if (this.app.settings.answer) {
            this.app.startResultChecking()
        } else {
            this.app.updateStatusRight("Result checking disabled")
        }
    }

    /**
     * Builds JavaScript to detect Project-GC challenge results
     * Checks for challengeFulfilled/challengeUnfulfilled divs without hide class
     * @returns {String} JavaScript code for Project-GC challenge result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for challenge fulfilled/unfulfilled divs based on hide class
        return "try { " .
               "var fulfilledDiv = document.getElementById('challengeFulfilled'); " .
               "var unfulfilledDiv = document.getElementById('challengeUnfulfilled'); " .
               "if (fulfilledDiv && !fulfilledDiv.classList.contains('hide')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (unfulfilledDiv && !unfulfilledDiv.classList.contains('hide')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}