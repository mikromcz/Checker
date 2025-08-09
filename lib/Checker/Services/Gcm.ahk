/**
 * @description GCM validator.gcm.cz service implementation
 * Handles complex coordinate form with separate dropdowns and input fields
 * Includes automatic URL fixing and captcha focus
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GcmService extends BaseService {
    /**
     * Constructor for GCM service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gcm"
    }

    /**
     * Fills GCM validator form with dropdowns and separate coordinate fields
     * Automatically focuses captcha field after filling coordinates
     * @override
     */
    executeCoordinateFilling() {
        ; For validator.gcm.cz - dropdown selections plus separate coordinate fields
        this.app.updateStatusLeft("Filling GCM validator form...")

        ; Build JavaScript code to fill dropdowns and coordinate fields
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Set latitude direction dropdown (N/S) - field name: lat_ns
                  "var latNsDropdown = document.getElementsByName('lat_ns')[0]; " .
                  "if (latNsDropdown) { " .
                  "  for (var i = 0; i < latNsDropdown.options.length; i++) { " .
                  "    if (latNsDropdown.options[i].value === '" . this.app.lat . "' || latNsDropdown.options[i].text === '" . this.app.lat . "') { " .
                  "      latNsDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('lat_ns dropdown not found'); } " .

                  ; Set longitude direction dropdown (E/W) - field name: lon_ew
                  "var lonEwDropdown = document.getElementsByName('lon_ew')[0]; " .
                  "if (lonEwDropdown) { " .
                  "  for (var i = 0; i < lonEwDropdown.options.length; i++) { " .
                  "    if (lonEwDropdown.options[i].value === '" . this.app.lon . "' || lonEwDropdown.options[i].text === '" . this.app.lon . "') { " .
                  "      lonEwDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('lon_ew dropdown not found'); } " .

                  ; Fill latitude fields - lat_deg (degrees), lat_min (decimal minutes)
                  "var latDeg = document.getElementsByName('lat_deg')[0]; " .
                  "if (latDeg) { latDeg.value = '" . this.app.latdeg . "'; } else { errors.push('lat_deg field not found'); } " .
                  "var latMin = document.getElementsByName('lat_min')[0]; " .
                  "if (latMin) { latMin.value = '" . this.app.latmin . "." . this.app.latdec . "'; } else { errors.push('lat_min field not found'); } " .

                  ; Fill longitude fields - lon_deg (degrees), lon_min (decimal minutes)
                  "var lonDeg = document.getElementsByName('lon_deg')[0]; " .
                  "if (lonDeg) { lonDeg.value = '" . this.app.londeg . "'; } else { errors.push('lon_deg field not found'); } " .
                  "var lonMin = document.getElementsByName('lon_min')[0]; " .
                  "if (lonMin) { lonMin.value = '" . this.app.lonmin . "." . this.app.londec . "'; } else { errors.push('lon_min field not found'); } " .

                  ; Trigger change events on dropdowns and fields (without focus to avoid stealing)
                  "var allElements = [latNsDropdown, lonEwDropdown, latDeg, latMin, lonDeg, lonMin]; " .
                  "allElements.forEach(function(element) { " .
                  "  if (element) { " .
                  "    element.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "    if (element.tagName === 'INPUT') { " .
                  "      element.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    } " .
                  "  } " .
                  "}); " .

                  ; Focus captcha input field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaInput = document.querySelector('div.captcha input[name=`"captcha`"]'); " .
                  "if (captchaInput) { " .
                  "captchaInput.focus(); " .
                  "captchaInput.click(); " .
                  "captchaInput.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: GCM fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . " - Captcha focused'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript for GCM result detection using CSS classes
     * Language-independent detection using h3.success and h3.fail selectors
     * @returns {String} JavaScript code for GCM result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for GCM success/failure - CSS class selectors only (language independent)
        return "try { " .
               "var successH3 = document.querySelector('h3.success'); " .
               "var failH3 = document.querySelector('h3.fail'); " .
               "if (successH3) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (failH3) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}