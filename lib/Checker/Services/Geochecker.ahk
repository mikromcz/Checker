class GeocheckerService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "geochecker"
    }

    executeCoordinateFilling() {
        this.fillSingleLatLonField("LatLonString", "Geochecker")
    }

    buildResultCheckingJS() {
        ; Check for geochecker.com specific success/failure divs
        return "try { " .
               "var success = document.querySelector('div.success'); " .
               "var wrong = document.querySelector('div.wrong'); " .
               "if (success && success.textContent.includes('Success')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (wrong && wrong.textContent.includes('Incorrect')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}