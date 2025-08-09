/**
 * @description Evince coordinate checker service (discontinued)
 * Service hosted at evince.locusprime.net, became unavailable March 2016
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since March 2016
 */
class EvincService extends DeadService {
    /**
     * Constructor for dead Evince service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "evince", "evince.locusprime.net", "2016-03")
    }
}