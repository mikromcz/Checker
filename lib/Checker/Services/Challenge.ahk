class ChallengeService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "challenge"
    }

    executeCoordinateFilling() {
        ; Challenge service does not require coordinate filling
        this.app.updateStatusLeft("Challenge service: No coordinates to fill, ready for result checking")
        this.app.coordinatesFilled := true ; Mark as filled so result checking can start

        ; Start result checking if enabled
        if (this.app.settings.answer) {
            this.app.startResultChecking()
        } else {
            this.app.updateStatusRight("Result checking disabled")
        }
    }

    buildResultCheckingJS() {
        ; Check for challenge fulfilled/unfulfilled divs based on hide class
        return "try { " .
               "var fulfilledDiv = document.getElementById('challengeFulfilled'); " .
               "var unfulfilledDiv = document.getElementById('challengeUnfulfilled'); " .
               "if (fulfilledDiv && !fulfilledDiv.classList.contains('hide')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (unfulfilledDiv && !unfulfilledDiv.classList.contains('hide')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}