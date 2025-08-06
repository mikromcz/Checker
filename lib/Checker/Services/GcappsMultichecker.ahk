class GcappsMulticheckerService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gcappsmultichecker"
    }

    executeCoordinateFilling() {
        ; For gc-apps.com multichecker - no coordinates to fill, it asks questions instead
        this.app.updateStatusLeft("GC-Apps Multichecker loaded - This service asks questions instead of coordinates")
        this.app.updateStatus("GC-Apps Multichecker: No coordinates to fill - Please answer the questions manually and wait for result")
        
        ; No JavaScript to execute since there are no coordinates to fill
        ; The service just displays questions that need to be answered manually
        
        ; Mark coordinates as "filled" so result checking can start
        this.app.coordinatesFilled := true
        
        ; Start result checking if enabled
        if (this.app.settings.answer) {
            this.app.startResultChecking()
        } else {
            this.app.updateStatusRight("Result checking disabled")
        }
    }

    buildResultCheckingJS() {
        ; Check for GC-Apps Multichecker specific success/failure patterns (same as geochecker)
        return "try { " .
               "var successDiv = document.querySelector('div.alert.alert-success'); " .
               "var dangerDiv = document.querySelector('div.alert.alert-danger'); " .
               "if (successDiv && successDiv.textContent) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (dangerDiv && dangerDiv.textContent) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}