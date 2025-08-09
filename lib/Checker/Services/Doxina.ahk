/**
 * @description Doxina coordinate checker service (discontinued)
 * Service hosted at doxina.filipruzicka.net, became unavailable in October 2016
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since 2016-10
 */
class DoxinaService extends DeadService {
    /**
     * Constructor for dead Doxina service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "doxina", "doxina.filipruzicka.net", "2016-10")
    }
}