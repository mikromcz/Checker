/**
 * @description Komurka coordinate checker service (discontinued)
 * Service hosted at geo.komurka.cz, became unavailable March 2018
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since March 2018
 */
class KomurkaService extends DeadService {
    /**
     * Constructor for dead Komurka service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "komurka", "geo.komurka.cz", "2018-03")
    }
}