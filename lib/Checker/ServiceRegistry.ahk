#Include BaseService.ahk
#Include DeadService.ahk
#Include Translation.ahk

/**
 * @description Service registry and factory for coordinate checker services.
 * Manages registration, initialization, and creation of all supported services.
 * @author mikrom, ClaudeAI
 * @version 4.2.0
 */

; Alive services
#Include Services\Challenge.ahk
#Include Services\Certitudes.ahk
#Include Services\Gzchecker.ahk
#Include Services\GcappsGeochecker.ahk
#Include Services\GcappsMultichecker.ahk
#Include Services\Gccheck.ahk
#Include Services\Gcm.ahk
#Include Services\Geocachefi.ahk
#Include Services\Geocacheplanner.ahk
#Include Services\Geocheck.ahk
#Include Services\Geochecker.ahk
#Include Services\Gocaching.ahk
#Include Services\Gpscache.ahk
#Include Services\Hermansky.ahk
#Include Services\Nanochecker.ahk
#Include Services\Puzzlechecker.ahk

; Dead services
#Include Services\Doxina.ahk
#Include Services\Evince.ahk
#Include Services\Gccc.ahk
#Include Services\Gccounter.ahk
#Include Services\Gctoolbox.ahk
#Include Services\Geowii.ahk
#Include Services\Komurka.ahk

class ServiceRegistry {
    static services := ""

    /**
     * Initializes the service registry with all available services
     * Called automatically when services are first accessed
     */
    static initializeServices() {
        if (ServiceRegistry.services == "") {
            ServiceRegistry.services := Map()

            ; Register all available services
            ServiceRegistry.registerService("challenge", ChallengeService)
            ServiceRegistry.registerService("certitudes", CertitudesService)
            ServiceRegistry.registerService("gcappsgeochecker", GcappsGeocheckerService)
            ServiceRegistry.registerService("gcappsmultichecker", GcappsMulticheckerService)
            ServiceRegistry.registerService("gccheck", GccheckService)
            ServiceRegistry.registerService("gcm", GcmService)
            ServiceRegistry.registerService("geocachefi", GeocachefiService)
            ServiceRegistry.registerService("geocacheplanner", GeocacheplannerService)
            ServiceRegistry.registerService("geocheck", GeocheckService)
            ServiceRegistry.registerService("geochecker", GeocheckerService)
            ServiceRegistry.registerService("gocaching", GocachingService)
            ServiceRegistry.registerService("gpscache", GpscacheService)
            ServiceRegistry.registerService("gzchecker", GZCheckerService)
            ServiceRegistry.registerService("hermansky", HermanskyService)
            ServiceRegistry.registerService("nanochecker", NanocheckerService)
            ServiceRegistry.registerService("puzzlechecker", PuzzlecheckerService)

            ; Dead services
            ServiceRegistry.registerService("doxina", DoxinaService)
            ServiceRegistry.registerService("evince", EvincService)
            ServiceRegistry.registerService("gccc", GcccService)
            ServiceRegistry.registerService("gccounter", GccounterService)
            ServiceRegistry.registerService("gctoolbox", GctoolboxService)
            ServiceRegistry.registerService("geowii", GeowiiService)
            ServiceRegistry.registerService("komurka", KomurkaService)
        }
    }

    /**
     * Registers a service with the registry
     * @param {String} serviceName Name used to identify the service
     * @param {Class|Function} serviceClass Service class constructor or factory function
     */
    static registerService(serviceName, serviceClass) {
        ServiceRegistry.services[StrLower(serviceName)] := serviceClass
    }

    /**
     * Creates a service instance for the given service name
     * @param {String} serviceName Name of the service to create (may include |comment)
     * @param {Object} checkerApp Reference to the main Checker application
     * @returns {BaseService} Service instance or UnknownService if not found
     */
    static createService(serviceName, checkerApp) {
        ServiceRegistry.initializeServices()

        ; Extract base service name (before |) for registry lookup
        baseServiceName := serviceName
        if (InStr(serviceName, "|")) {
            baseServiceName := StrSplit(serviceName, "|")[1]
        }

        serviceKey := StrLower(baseServiceName)

        if (ServiceRegistry.services.Has(serviceKey)) {
            ; Both class constructors and factory functions are callable the same way
            return ServiceRegistry.services[serviceKey](checkerApp)
        }

        ; Unknown service
        return UnknownService(checkerApp, serviceName)
    }

    /**
     * Gets list of all supported service names
     * @returns {Array} Array of service names
     */
    static getSupportedServices() {
        ServiceRegistry.initializeServices()
        services := []
        for serviceName in ServiceRegistry.services {
            services.Push(serviceName)
        }
        return services
    }
}

/**
 * Standard LatLonString service for services that follow the common pattern
 * @extends BaseService
 */
class StandardLatLonService extends BaseService {
    /**
     * Constructor for standard LatLonString services
     * @param {Object} checkerApp Reference to main application
     * @param {String} serviceName Service identifier
     * @param {String} displayName Human-readable service name
     */
    __New(checkerApp, serviceName, displayName) {
        super.__New(checkerApp)
        this.serviceName := serviceName
        this.displayName := displayName
    }

    executeCoordinateFilling() {
        this.fillSingleLatLonField("LatLonString", this.displayName)
    }
}

/**
 * Unknown service handler for unsupported service names
 * @extends BaseService
 */
class UnknownService extends BaseService {
    /**
     * Constructor for unknown service handler
     * @param {Object} checkerApp Reference to main application
     * @param {String} serviceName The unsupported service name
     */
    __New(checkerApp, serviceName) {
        super.__New(checkerApp)
        this.serviceName := serviceName
    }

    executeCoordinateFilling() {
        this.app.updateStatus("Unknown service: " . this.serviceName . " - See documentation for supported services")
    }

    buildResultCheckingJS() {
        ; Default checking for unknown services - look for common patterns
        return "try { " .
        "var success = document.querySelector('div.success, .success, span#congrats'); " .
        "var wrong = document.querySelector('div.wrong, .wrong, span#nope'); " .
        "if (success && (success.textContent.includes('Success') || success.textContent.includes('Correct') || success.textContent.includes('congrats'))) { " .
        "'RESULT:SUCCESS'; " .
        "} else if (wrong && (wrong.textContent.includes('Incorrect') || wrong.textContent.includes('Wrong') || wrong.textContent.includes('nope'))) { " .
        "'RESULT:WRONG'; " .
        "} else { " .
        "'RESULT:NONE'; " .
        "} " .
        "} catch (e) { " .
        "'ERROR: ' + e.message; " .
        "}"
    }
}
