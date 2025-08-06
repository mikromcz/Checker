class HermanskyService extends BaseService {
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "hermansky"
    }

    executeCoordinateFilling() {
        ; For geo.hermansky.net - dropdown selections plus separate coordinate fields
        this.app.updateStatusLeft("Filling geo.hermansky.net form...")

        ; Build JavaScript code to fill dropdowns and coordinate fields
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Set latitude direction dropdown (N/S) - field name: vyska
                  "var vyskaDropdown = document.getElementsByName('vyska')[0]; " .
                  "if (vyskaDropdown) { " .
                  "  for (var i = 0; i < vyskaDropdown.options.length; i++) { " .
                  "    if (vyskaDropdown.options[i].value === '" . this.app.lat . "') { " .
                  "      vyskaDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('vyska dropdown not found'); } " .

                  ; Set longitude direction dropdown (E/W) - field name: sirka
                  "var sirkaDropdown = document.getElementsByName('sirka')[0]; " .
                  "if (sirkaDropdown) { " .
                  "  for (var i = 0; i < sirkaDropdown.options.length; i++) { " .
                  "    if (sirkaDropdown.options[i].value === '" . this.app.lon . "') { " .
                  "      sirkaDropdown.selectedIndex = i; " .
                  "      break; " .
                  "    } " .
                  "  } " .
                  "} else { errors.push('sirka dropdown not found'); } " .

                  ; Fill latitude fields - stupne21 (degrees), minuty21 (decimal minutes)
                  "var stupne21 = document.getElementsByName('stupne21')[0]; " .
                  "if (stupne21) { stupne21.value = '" . this.app.latdeg . "'; } else { errors.push('stupne21 field not found'); } " .
                  "var minuty21 = document.getElementsByName('minuty21')[0]; " .
                  "if (minuty21) { minuty21.value = '" . this.app.latmin . "." . this.app.latdec . "'; } else { errors.push('minuty21 field not found'); } " .

                  ; Fill longitude fields - stupne22 (degrees), minuty22 (decimal minutes)
                  "var stupne22 = document.getElementsByName('stupne22')[0]; " .
                  "if (stupne22) { stupne22.value = '" . this.app.londeg . "'; } else { errors.push('stupne22 field not found'); } " .
                  "var minuty22 = document.getElementsByName('minuty22')[0]; " .
                  "if (minuty22) { minuty22.value = '" . this.app.lonmin . "." . this.app.londec . "'; } else { errors.push('minuty22 field not found'); } " .

                  ; Trigger change events on dropdowns and fields
                  "var allElements = [vyskaDropdown, sirkaDropdown, stupne21, minuty21, stupne22, minuty22]; " .
                  "allElements.forEach(function(element) { " .
                  "  if (element) { " .
                  "    element.focus(); " .
                  "    element.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "    if (element.tagName === 'INPUT') { " .
                  "      element.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    } " .
                  "  } " .
                  "}); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "'SUCCESS: Hermansky fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . "'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    buildResultCheckingJS() {
        ; Check for hermansky success/failure - look for specific error div and success patterns
        return "try { " .
               "var errorDiv = document.querySelector('div[style*=`"background: #db7777`"]'); " .
               "var successDiv = document.querySelector('div[style*=`"background: #77db7a`"]'); " .
               "if (errorDiv && (errorDiv.textContent.includes('špatně') || errorDiv.textContent.includes('znovu'))) { " .
               "'RESULT:WRONG'; " .
               "} else if (successDiv && (successDiv.textContent.includes('spravně') || successDiv.textContent.includes('můžete vyrazit'))) { " .
               "'RESULT:SUCCESS'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}