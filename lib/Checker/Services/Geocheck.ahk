/**
 * @description Geocheck.org service implementation with comprehensive multilingual support
 * Handles complex form with separate degree/minute/decimal fields and radio buttons
 * Includes captcha focus and multilingual result detection
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GeocheckService extends BaseService {
    /**
     * Constructor for Geocheck service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "geocheck"
    }

    /**
     * Fills Geocheck form with separate coordinate fields and radio buttons
     * Prevents duplicate filling and automatically focuses captcha field
     * @override
     */
    executeCoordinateFilling() {
        ; For geocheck.org - separate degree/minute/decimal fields with radio buttons
        this.app.updateStatusLeft("Filling geocheck.org form...")

        ; Build JavaScript code to fill separate coordinate fields and radio buttons
        jsCode := "try { " .
                  "var success = true; " .
                  "var errors = []; " .

                  ; Fill latitude direction radio button (N/S)
                  "var latRadios = document.getElementsByName('lat'); " .
                  "var latRadioSet = false; " .
                  "for (var i = 0; i < latRadios.length; i++) { " .
                  "  if (latRadios[i].value === '" . this.app.lat . "') { " .
                  "    latRadios[i].checked = true; " .
                  "    latRadioSet = true; " .
                  "    break; " .
                  "  } " .
                  "} " .
                  "if (!latRadioSet) errors.push('Latitude radio " . this.app.lat . " not found'); " .

                  ; Fill longitude direction radio button (E/W)
                  "var lonRadios = document.getElementsByName('lon'); " .
                  "var lonRadioSet = false; " .
                  "for (var i = 0; i < lonRadios.length; i++) { " .
                  "  if (lonRadios[i].value === '" . this.app.lon . "') { " .
                  "    lonRadios[i].checked = true; " .
                  "    lonRadioSet = true; " .
                  "    break; " .
                  "  } " .
                  "} " .
                  "if (!lonRadioSet) errors.push('Longitude radio " . this.app.lon . " not found'); " .

                  ; Fill latitude fields
                  "var latdeg = document.getElementsByName('latdeg')[0]; " .
                  "if (latdeg) { latdeg.value = '" . this.app.latdeg . "'; } else { errors.push('latdeg field not found'); } " .
                  "var latmin = document.getElementsByName('latmin')[0]; " .
                  "if (latmin) { latmin.value = '" . this.app.latmin . "'; } else { errors.push('latmin field not found'); } " .
                  "var latdec = document.getElementsByName('latdec')[0]; " .
                  "if (latdec) { latdec.value = '" . this.app.latdec . "'; } else { errors.push('latdec field not found'); } " .

                  ; Fill longitude fields
                  "var londeg = document.getElementsByName('londeg')[0]; " .
                  "if (londeg) { londeg.value = '" . this.app.londeg . "'; } else { errors.push('londeg field not found'); } " .
                  "var lonmin = document.getElementsByName('lonmin')[0]; " .
                  "if (lonmin) { lonmin.value = '" . this.app.lonmin . "'; } else { errors.push('lonmin field not found'); } " .
                  "var londec = document.getElementsByName('londec')[0]; " .
                  "if (londec) { londec.value = '" . this.app.londec . "'; } else { errors.push('londec field not found'); } " .

                  ; Trigger change events
                  "var fields = [latdeg, latmin, latdec, londeg, lonmin, londec]; " .
                  "fields.forEach(function(field) { " .
                  "  if (field) { " .
                  "    field.focus(); " .
                  "    field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "    field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "  } " .
                  "}); " .

                  "if (errors.length > 0) { " .
                  "'ERROR: ' + errors.join(', '); " .
                  "} else { " .
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementsByName('usercaptcha')[0]; " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.click(); " .
                  "} " .
                  "}, 100); " .
                  "'SUCCESS: Geocheck fields filled - " . this.app.lat . this.app.latdeg . " " . this.app.latmin . "." . this.app.latdec . " " . this.app.lon . this.app.londeg . " " . this.app.lonmin . "." . this.app.londec . " - Captcha field focused'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript for Geocheck multilingual result detection
     * Supports 15+ languages with comprehensive success/failure pattern matching
     * @returns {String} JavaScript code for multilingual Geocheck result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for geocheck.org specific success/failure with comprehensive multilingual patterns
        return "try { " .
               "var body = document.body.innerHTML; " .

               ; Success patterns (multilingual)
               "var successPatterns = [ " .
               "'your solution is correct!!!', " .
               "'Deine L.*sung ist korrekt!!!', " .
               "'vous avez trouvé la solution!!!', " .
               "'tu solución es correcta!!!', " .
               "'La teva solució és correcta!!!', " .
               "'la tua risposta e corretta!!!', " .
               "'a a sua solu.*ao está correcta!!!', " .
               "'A sua soluçao está correta!!!!!!', " .
               "'Twoje rozwi.*zanie jest poprawne!!!', " .
               "'Je oplossing is juist!!!', " .
               "'din losning er korrekt!!!', " .
               "'l.*sningen er korrekt!!!', " .
               "'din l.*sning .*r r.*tt!!!', " .
               "'ení je správné!!!', " .
               "'Zadané sou.*adnice nejsou zcela p.*esné', " .
               "'riešenie je správne!!!' " .
               "]; " .

               ; Failure patterns (multilingual)
               "var failurePatterns = [ " .
               "'Sorry, that answer is incorrect', " .
               "'Schade, die L.*sung ist falsch', " .
               "'Désolé, il ne s.*agit pas des bonnes coordonnées', " .
               "'Lo sentimos, la respuesta no es correcta', " .
               "'Ho sentim, la resposta és incorrecta', " .
               "'Spiacente, questa risposta non e corretta', " .
               "'Pe.*o desculpa, essa resposta é incorrecta', " .
               "'Infelizmente a sua solu.*ao está incorreta', " .
               "'Niestety Twoja odpowied.* jest niepoprawna', " .
               "'Sorry, dat antwoord is niet juist', " .
               "'Beklager, det svar er forkert', " .
               "'Beklager, det svaret er feil', " .
               "'Tyv.*rr, svaret .*r fel', " .
               "'Bohu.*el, zadaná odpov.* není správná', " .
               "'Ľutujeme, odpoveď nie je správna' " .
               "]; " .

               ; Check for success patterns
               "var isSuccess = false; " .
               "for (var i = 0; i < successPatterns.length; i++) { " .
               "  var regex = new RegExp(successPatterns[i], 'i'); " .
               "  if (regex.test(body)) { " .
               "    isSuccess = true; " .
               "    break; " .
               "  } " .
               "} " .

               ; Check for failure patterns
               "var isFailure = false; " .
               "for (var i = 0; i < failurePatterns.length; i++) { " .
               "  var regex = new RegExp(failurePatterns[i], 'i'); " .
               "  if (regex.test(body)) { " .
               "    isFailure = true; " .
               "    break; " .
               "  } " .
               "} " .

               "if (isSuccess) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (isFailure) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }

    /**
     * Copies owner's message from Geocheck results page
     * Uses complex table selector to extract message content
     * @returns {Boolean} True if clipboard operation was initiated
     * @override
     */
    copyOwnerMessage() {
        ; Copy geocheck.org owner's message using specific selector
        this.app.updateStatus("Executing clipboard JavaScript for geocheck.org...")
        jsCode := "try { " .
                  "var messageElement = document.querySelector('body > table > tbody > tr:nth-child(2) > td > table > tbody > tr > td:nth-child(2) > form > table > tbody > tr:nth-child(7) > td > p'); " .
                  "if (messageElement) { " .
                  "var messageText = messageElement.textContent || messageElement.innerText; " .
                  "if (messageText) { " .
                  "messageText = messageText.replace(/\\\\s+/g, ' ').trim(); " .
                  "'CLIPBOARD:' + messageText; " .
                  "} else { " .
                  "'CLIPBOARD:NO_TEXT'; " .
                  "} " .
                  "} else { " .
                  "'CLIPBOARD:NO_ELEMENT'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.app.webView.ExecuteScriptAsync(jsCode)
            .then((result) => this.app.onClipboardResult(result))
            .catch((error) => this.app.onClipboardError(error))

        return true
    }
}