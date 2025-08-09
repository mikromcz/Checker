/**
 * @description Handler for dead/discontinued coordinate checker services
 * Provides consistent messaging and behavior for services that are no longer available
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class DeadService extends BaseService {
    /**
     * Constructor for dead service handler
     * @param {Object} checkerApp Reference to the main Checker application
     * @param {String} serviceName Internal service identifier
     * @param {String} siteName Human-readable site name for display
     * @param {String} deadSince Optional date when service became unavailable
     */
    __New(checkerApp, serviceName, siteName, deadSince := "") {
        super.__New(checkerApp)
        this.serviceName := serviceName
        this.siteName := siteName
        this.deadSince := deadSince
        this.isDead := true
    }

    /**
     * Override coordinate filling to show dead service message
     * @override
     */
    executeCoordinateFilling() {
        this.showDeadServiceMessage()
    }

    /**
     * Displays dead service warning message and sets exit code 3
     * @override
     */
    showDeadServiceMessage() {
        deadInfo := this.deadSince ? " " . Translation.get("dead_since") . " " . this.deadSince . ")" : ""
        this.app.updateStatus(Translation.get("dead_service_warning") . " " . this.siteName . deadInfo . " " . Translation.get("dead_service_desc"))
        this.app.finalExitCode := 3
    }

    /**
     * Returns JavaScript for dead services (always returns NONE)
     * @returns {String} JavaScript code that returns "RESULT:NONE"
     * @override
     */
    buildResultCheckingJS() {
        return "try { 'RESULT:NONE'; } catch (e) { 'ERROR: ' + e.message; }"
    }
}