class GcappsGeocheckerService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gcappsgeochecker"
    }

    executeCoordinateFilling() {
        ; For gc-apps.com geochecker - uses specific field name and captcha focus
        this.app.updateStatusLeft("Filling GC-Apps Geochecker form...")

        ; Format coordinates for gc-apps: N50 15.123 E015 54.123 (standard geochecker format)
        coordString := this.formatCoordinatesForGeochecker()

        ; Build JavaScript code to fill the try[fields][coordinates] field
        jsCode := "try { " .
                  "var field = document.getElementById('try_fields_coordinates'); " .
                  "if (!field) field = document.getElementsByName('try[fields][coordinates]')[0]; " .
                  "if (field) { " .
                  "field.value = '" . coordString . "'; " .
                  "field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "} " .
                  
                  ; Focus captcha field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementById('try_captcha'); " .
                  "if (!captchaField) captchaField = document.getElementsByName('try[captcha]')[0]; " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .
                  
                  "if (field) { " .
                  "'SUCCESS: GC-Apps Geochecker coordinates field filled with: ' + field.value + ' - Captcha focused'; " .
                  "} else { " .
                  "'ERROR: try[fields][coordinates] field not found on GC-Apps Geochecker page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    buildResultCheckingJS() {
        ; Check for GC-Apps Geochecker specific success/failure patterns
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