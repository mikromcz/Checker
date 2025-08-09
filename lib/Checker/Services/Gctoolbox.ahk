/**
 * @description GCToolbox coordinate checker service (discontinued)
 * Service hosted at gctoolbox.com, became unavailable May 2018
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since May 2018
 */
class GctoolboxService extends DeadService {
    /**
     * Constructor for dead GCToolbox service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "gctoolbox", "gctoolbox.com", "2018-05")
    }
}