class GocachingService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gocaching"
    }

    executeCoordinateFilling() {
        ; For gocaching.eu - separate coordinate fields with dropdowns
        this.app.updateStatusLeft("Filling gocaching.eu form...")

        ; Build JavaScript code to fill dropdowns and coordinate fields
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Set latitude direction dropdown (N/S)
                  "var latDropdown = document.getElementsByName('ck_lat')[0]; " .
                  "if (latDropdown) { " .
                  "  for (var i = 0; i < latDropdown.options.length; i++) { " .
                  "    if (latDropdown.options[i].value === '" . this.app.lat . "') { " .
                  "      latDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('ck_lat dropdown not found'); } " .

                  ; Set longitude direction dropdown (E/W)
                  "var lngDropdown = document.getElementsByName('ck_lng')[0]; " .
                  "if (lngDropdown) { " .
                  "  for (var i = 0; i < lngDropdown.options.length; i++) { " .
                  "    if (lngDropdown.options[i].value === '" . this.app.lon . "') { " .
                  "      lngDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('ck_lng dropdown not found'); } " .

                  ; Fill latitude fields - ck_lat1 (degrees), ck_lat2 (minutes), ck_lat3 (decimal minutes)
                  "var ckLat1 = document.getElementsByName('ck_lat1')[0]; " .
                  "if (ckLat1) { ckLat1.value = '" . this.app.latdeg . "'; } else { errors.push('ck_lat1 field not found'); } " .
                  "var ckLat2 = document.getElementsByName('ck_lat2')[0]; " .
                  "if (ckLat2) { ckLat2.value = '" . this.app.latmin . "'; } else { errors.push('ck_lat2 field not found'); } " .
                  "var ckLat3 = document.getElementsByName('ck_lat3')[0]; " .
                  "if (ckLat3) { ckLat3.value = '" . this.app.latdec . "'; } else { errors.push('ck_lat3 field not found'); } " .

                  ; Fill longitude fields - ck_lng1 (degrees), ck_lng2 (minutes), ck_lng3 (decimal minutes)
                  "var ckLng1 = document.getElementsByName('ck_lng1')[0]; " .
                  "if (ckLng1) { ckLng1.value = '" . Format("{:03d}", Integer(this.app.londeg)) . "'; } else { errors.push('ck_lng1 field not found'); } " .
                  "var ckLng2 = document.getElementsByName('ck_lng2')[0]; " .
                  "if (ckLng2) { ckLng2.value = '" . this.app.lonmin . "'; } else { errors.push('ck_lng2 field not found'); } " .
                  "var ckLng3 = document.getElementsByName('ck_lng3')[0]; " .
                  "if (ckLng3) { ckLng3.value = '" . this.app.londec . "'; } else { errors.push('ck_lng3 field not found'); } " .

                  ; Trigger change events on dropdowns and fields (without focus to avoid stealing)
                  "var allElements = [latDropdown, lngDropdown, ckLat1, ckLat2, ckLat3, ckLng1, ckLng2, ckLng3]; " .
                  "allElements.forEach(function(element) { " .
                  "  if (element) { " .
                  "    element.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "    if (element.tagName === 'INPUT') { " .
                  "      element.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    } " .
                  "  } " .
                  "}); " .

                  ; Focus reCAPTCHA field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementsByName('recaptcha_response_field')[0]; " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: Gocaching fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . " - reCAPTCHA focused'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    buildResultCheckingJS() {
        ; Check for gocaching.de specific success/failure patterns
        return "try { " .
               "var trueImg = document.querySelector('img[src*=`"coc_true.gif`"]'); " .
               "var falseImg = document.querySelector('img[src*=`"coc_false.gif`"]'); " .
               "var body = document.body.innerHTML; " .
               "if (trueImg || body.includes('Richtig')) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (falseImg || body.includes('Falsch')) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}