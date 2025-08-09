/**
 * @description GCCounter2 coordinate checker service (discontinued)
 * Service hosted at gccounter.com, became unavailable August 2018
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since August 2018
 */
class Gccounter2Service extends DeadService {
    /**
     * Constructor for dead GCCounter2 service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "gccounter2", "gccounter.com", "2018-08")
    }
}