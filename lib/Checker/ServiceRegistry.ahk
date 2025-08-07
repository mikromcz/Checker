#Include BaseService.ahk
#Include DeadService.ahk
#Include Translation.ahk

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
#Include Services\Gccounter2.ahk
#Include Services\Gctoolbox.ahk
#Include Services\Geowii.ahk
#Include Services\Komurka.ahk

class ServiceRegistry {
    static services := ""

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
            ServiceRegistry.registerService("gccounter2", Gccounter2Service)
            ServiceRegistry.registerService("gctoolbox", GctoolboxService)
            ServiceRegistry.registerService("geowii", GeowiiService)
            ServiceRegistry.registerService("komurka", KomurkaService)
        }
    }

    static registerService(serviceName, serviceClass) {
        ServiceRegistry.services[StrLower(serviceName)] := serviceClass
    }

    static registerStandardService(serviceName, displayName) {
        ServiceRegistry.services[StrLower(serviceName)] := (app) => StandardLatLonService(app, serviceName, displayName
        )
    }

    static createService(serviceName, checkerApp) {
        ServiceRegistry.initializeServices()
        serviceKey := StrLower(serviceName)

        if (ServiceRegistry.services.Has(serviceKey)) {
            serviceFactory := ServiceRegistry.services[serviceKey]

            ; Handle both class constructors and factory functions
            if (IsObject(serviceFactory) && serviceFactory.HasProp("Prototype")) {
                ; It's a class constructor
                return serviceFactory(checkerApp)
            } else {
                ; It's a factory function
                return serviceFactory(checkerApp)
            }
        }

        ; Unknown service
        return UnknownService(checkerApp, serviceName)
    }

    static getSupportedServices() {
        ServiceRegistry.initializeServices()
        services := []
        for serviceName in ServiceRegistry.services {
            services.Push(serviceName)
        }
        return services
    }
}

; Standard LatLonString service for services that follow the common pattern
class StandardLatLonService extends BaseService {
    __New(checkerApp, serviceName, displayName) {
        super.__New(checkerApp)
        this.serviceName := serviceName
        this.displayName := displayName
    }

    executeCoordinateFilling() {
        this.fillSingleLatLonField("LatLonString", this.displayName)
    }
}

; Unknown service handler
class UnknownService extends BaseService {
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
