/**
 * @description GeoWii coordinate checker service (discontinued)
 * Service hosted at geowii.miga.lv, became unavailable September 2023
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends DeadService
 * @deprecated Service discontinued since September 2023
 */
class GeowiiService extends DeadService {
    /**
     * Constructor for dead GeoWii service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp, "geowii", "geowii.miga.lv", "2023-09")
    }
}