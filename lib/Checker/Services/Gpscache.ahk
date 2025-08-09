/**
 * @description GPS-Cache.de coordinate checker service implementation
 * Uses specific field names (txtKoords) with ListView controls and smiley image result detection
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @extends BaseService
 */
class GpscacheService extends BaseService {
    /**
     * Constructor for GPS-Cache.de service
     * @param {Object} checkerApp Reference to main application
     */
    __New(checkerApp) {
        super.__New(checkerApp)
        this.serviceName := "gpscache"
    }

    /**
     * Fills GPS-Cache.de txtKoords field with N50 12.345 E012 34.567 format and focuses captcha
     * @override
     */
    executeCoordinateFilling() {
        ; For geochecker.gps-cache.de - uses specific field name and format "N50 12.345 E012 34.567"
        this.app.updateStatusLeft("Filling GPS-Cache form...")

        ; Format coordinates for gpscache: N50 12.345 E012 34.567
        latMinDec := this.app.latmin . "." . this.app.latdec
        lonMinDec := this.app.lonmin . "." . this.app.londec
        coordString := this.app.lat . this.app.latdeg . " " . latMinDec . " " . this.app.lon . Format("{:03d}", Integer(this.app.londeg)) . " " . lonMinDec

        ; Build JavaScript code to fill the ListView1$ctrl0$txtKoords field
        jsCode := "try { " .
                  "var field = document.getElementsByName('ListView1$ctrl0$txtKoords')[0]; " .
                  "if (!field) field = document.getElementById('ListView1_txtKoords_0'); " .
                  "if (field) { " .
                  "field.value = '" . coordString . "'; " .
                  "field.dispatchEvent(new Event('input', { bubbles: true })); " .
                  "field.dispatchEvent(new Event('change', { bubbles: true })); " .
                  "} " .

                  ; Focus captcha field after filling coordinates
                  "setTimeout(function() { " .
                  "var captchaField = document.getElementsByName('ListView1$ctrl0$txtCaptchaCode')[0]; " .
                  "if (!captchaField) captchaField = document.getElementById('ListView1_txtCaptchaCode_0'); " .
                  "if (captchaField) { " .
                  "captchaField.focus(); " .
                  "captchaField.scrollIntoView(); " .
                  "} " .
                  "}, 200); " .

                  "if (field) { " .
                  "'SUCCESS: GPS-Cache txtKoords field filled with: ' + field.value + ' - Captcha focused'; " .
                  "} else { " .
                  "'ERROR: txtKoords field not found on GPS-Cache page'; " .
                  "} " .
                  "} catch (e) { " .
                  "'ERROR: ' + e.message; " .
                  "}"

        this.executeJavaScript(jsCode)
    }

    /**
     * Builds JavaScript code to detect GPS-Cache.de success/failure using smiley images
     * @returns {String} JavaScript code for result detection
     * @override
     */
    buildResultCheckingJS() {
        ; Check for GPS-Cache specific smiley images
        return "try { " .
               "var goodSmiley = document.querySelector('img[src*=`"smiley-good-80.png`"]'); " .
               "var badSmiley = document.querySelector('img[src*=`"smiley-bad-80.png`"], img[src*=`"smiley-weird-80.png`"]'); " .
               "if (goodSmiley) { " .
               "'RESULT:SUCCESS'; " .
               "} else if (badSmiley) { " .
               "'RESULT:WRONG'; " .
               "} else { " .
               "'RESULT:NONE'; " .
               "} " .
               "} catch (e) { " .
               "'ERROR: ' + e.message; " .
               "}"
    }
}