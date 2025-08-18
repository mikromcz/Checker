/**
 * @description GCCounter coordinate checker service (discontinued)
 * Service hosted at gccounter.de / gccounter.com, became unavailable August 2018
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since August 2018
 */
class GccounterService extends DeadService {
    /**
     * Constructor for dead GCCounter service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "gccounter", "gccounter.de / gccounter.com", "2018-08")
    }
}