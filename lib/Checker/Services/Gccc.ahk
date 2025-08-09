/**
 * @description GCCC coordinate checker service (discontinued)
 * Service hosted at gccc.eu, became unavailable May 2018
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since May 2018
 */
class GcccService extends DeadService {
    /**
     * Constructor for dead GCCC service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "gccc", "gccc.eu", "2018-05")
    }
}