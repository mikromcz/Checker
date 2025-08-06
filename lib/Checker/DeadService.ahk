class DeadService extends BaseService {
    __New(checkerApp, serviceName, siteName, deadSince := "") {
        super.__New(checkerApp)
        this.serviceName := serviceName
        this.siteName := siteName
        this.deadSince := deadSince
        this.isDead := true
    }

    executeCoordinateFilling() {
        this.showDeadServiceMessage()
    }

    showDeadServiceMessage() {
        deadInfo := this.deadSince ? " " . Translation.get("dead_since") . " " . this.deadSince . ")" : ""
        this.app.updateStatus(Translation.get("dead_service_warning") . " " . this.siteName . deadInfo . " " . Translation.get("dead_service_desc"))
        this.app.finalExitCode := 3
    }

    buildResultCheckingJS() {
        return "try { 'RESULT:NONE'; } catch (e) { 'ERROR: ' + e.message; }"
    }
}