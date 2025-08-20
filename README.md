# Checker - Nástroj pro ověření souřadnic

Checker je nástroj pro automatické ověření souřadnic u geocaching coordinate checker služeb. Aplikace automatizuje proces odesílání souřadnic na různé webové stránky pro ověření koordinátů a vyhodnocuje výsledky.

## Verze 4.0.1 - Kompletní přepis

Tato verze byla **kompletně přepsána** z [AutoHotkey](https://autohotkey.com/download/) v1 používající Internet Explorer na **[AutoHotkey](https://autohotkey.com/download/) v2 s [WebView2](https://github.com/thqby/ahk2_lib/tree/master/WebView2)** pro lepší kompatibilitu s moderními webovými standardy a budoucí podporu.

### Hlavní změny ve verzi 4:
- ✅ **[AutoHotkey](https://autohotkey.com/download/) v2** - moderní verze AutoHotkey
- ✅ **[WebView2](https://github.com/thqby/ahk2_lib/tree/master/WebView2)** - nahrazuje zastaralý Internet Explorer
- ✅ **Modulární architektura** - služby v samostatných souborech
- ✅ **Pokročilá validace parametrů** - inteligentní kontrola souřadnic s detailním error reportem
- ✅ **Podpora schránky** - automatické kopírování zpráv autorů
- ✅ **Dvojí režim** - některé služby podporují ověření koordinátů i odpovědí
- ✅ **Vícejazyčnost** - automatická detekce češtiny/angličtiny
- ✅ **Vylepšené GUI** - profesionální menu a stavový řádek s barevnými výsledky
- ✅ **Změna velikosti okna** - pamatuje si rozměry okna mezi spuštěními

## Rychlé použití

```batch
Checker.ahk služba N 50 15 123 E 015 54 123 "URL_adresa"
```

**Příklady:**
```batch
Checker.ahk geochecker S 50 15 123 W 015 54 123 "https://geochecker.com/?language=English"

Checker.ahk challenge N 49 42 660 E 018 23 165 "http://project-gc.com/Challenges/GC5KDPR/11265"
```

## Pokročilé funkce

### Automatické vyplňování odpovědí pomocí komentářů

Některé služby podporují automatické vyplňování řešení pomocí komentářů v cache. Stačí přidat do komentáře keše "checker" následovaný dvojtečkou a odpovědí:

#### Nanochecker
```
checker: my answer
```
Automaticky vyplní odpověď "my answer" do input pole na nanochecker.com.

#### Certitudes
```
checker: solution word
```
Automaticky vyplní odpověď "solution word" do odpovědního pole na certitudes.org (pouze v answer módu).

**Příklady komentářů:**
```
checker: 42
checker: PRAHA
checker: geocaching is fun
```

**Jak to funguje:**
1. Plugin najde komentář ve formátu `checker: odpověď`
2. Extrahuje odpověď a automaticky ji vyplní do správného pole
3. Pole se okamžitě vyplní a je připravené k odeslání
4. Funguje i s mezerami: `checker: answer` i `checker:answer`

## Podporované služby (24 celkem)

### Aktivní služby (16)
- **challenge** - project-gc.com challenges *(bez vyplňování, pouze kontrola výsledků)*
- **certitudes** - certitudes.org *(dvojí režim, schránka, podpora komentářů)*
- **gcappsgeochecker** - gcapps.org/geochecker *(standardní pole)*
- **gcappsmultichecker** - gcapps.org/multichecker *(standardní pole)*
- **gccheck** - gccheck.com *(schránka)*
- **geocachefi** - geocache.fi *(rozbalovací seznamy, schránka)*
- **geocacheplanner** - geocacheplanner.com *(standardní pole)*
- **geocheck** - geocheck.org *(oddělená pole, schránka)*
- **geochecker** - geochecker.com *(standardní pole)*
- **gcm** - validator.gcm.cz *(automatická oprava URL)*
- **gocaching** - gocaching.de *(standardní pole)*
- **gpscache** - gpscache.com *(standardní pole)*
- **gzchecker** - infin.ity.me.uk *(speciální pole, schránka)*
- **hermansky** - geo.hermansky.net *(rozbalovací seznamy)*
- **nanochecker** - nanochecker.com *(standardní pole, podpora komentářů)*
- **puzzlechecker** - puzzlechecker.com *(dvojí režim, schránka)*

### Nefunkční služby (7)
- **doxina** - doxina.filipruzicka.net *(mrtvé od 2016-10)*
- **evince** - evince.locusprime.net *(mrtvé od 2016-03)*
- **gccc** - gccc.eu *(mrtvé od 2018-05)*
- **gccounter** - gccounter.de / gccounter.com *(mrtvé od 2018-08)*
- **gctoolbox** - gctoolbox.de *(mrtvé od 2018-05)*
- **geowii** - geowii.miga.lv *(mrtvé od 2023-09)*
- **komurka** - geo.komurka.cz *(mrtvé od 2018-03)*

## Exit kódy

- **0**: Normální ukončení (uživatel zavřel nebo bez kontroly)
- **1**: Souřadnice jsou správné ✅
- **2**: Souřadnice jsou nesprávné ❌
- **3**: Nefunkční služba ⚠️
- **4**: Neplatné parametry ❌ *(nový)*

## Validace parametrů

Checker nyní obsahuje pokročilou validaci parametrů, která zkontroluje:

- ✅ **Počet parametrů** - přesně 10 parametrů je vyžadováno
- ✅ **Směry souřadnic** - N/S pro zeměpisnou šířku, E/W pro délku
- ✅ **Číselné hodnoty** - všechny koordináty musí být čísla
- ✅ **Rozsahy hodnot** - stupně (0-90° / 0-180°), minuty (0-59)

**Při chybných parametrech:**
- Aplikace zobrazí přehlednou chybovou stránku s příklady použití
- Ukáže přesné parametry, které obdržela
- Ukončí se s exit kódem 4 pro snadnou detekci chyb ve skriptech

**Příklad chybové stránky:**
```
Error: Invalid latitude direction 'https' (must be N or S)
Parameter 2 (lat): https
Parameter 3 (latdeg): //validator.gcm.cz/...
```

## Testování

Adresář `test/` obsahuje testovací soubory pro všechny služby s **aktualizovanými exit kódy**:
```batch
cd test
Test.Geochecker.bat
```

**Všechny testovací soubory nyní podporují exit kód 4:**
- `0`: No errors
- `1`: Correct coordinates
- `2`: Wrong coordinates
- `3`: Dead service
- `4`: Invalid parameters *(nový)*

## Konfigurace

Nastavení jsou uložena v souboru `Checker.ini`:
- `answer=1` - Povolit kontrolu výsledků a exit kódy
- `copymsg=1` - Kopírovat zprávy autorů do schránky
- `timeout=10` - Časový limit načítání stránky (sekundy)
- `debug=0` - Režim ladění
- `windowWidth=1200` - Šířka okna (automaticky ukládáno)
- `windowHeight=750` - Výška okna (automaticky ukládáno)

## Požadavky

- **Windows 10/11** (WebView2 je součástí systému (na Windows 7 lze tuším doinstalovat))
- **AutoHotkey v2.0** (pro spuštění zdrojového kódu)
- **Internetové připojení**

## Dokumentace

📖 **Hlavní stránka pluginu:** https://www.geoget.cz/doku.php/user:skript:checker

## Využívá

### AutoHotkey2
🌐 **Domovská stránka:** https://autohotkey.com/

### WebView2
🌐 **Domovská stránka:** https://learn.microsoft.com/en-us/microsoft-edge/webview2/

🌐 **AutoHotkey knihovna:** https://github.com/thqby/ahk2_lib/tree/master/WebView2

💬 **Fórum WebView2 knihovny:** https://www.autohotkey.com/boards/viewtopic.php?t=95666

### LittleDebugHelper
🐞 **Plugin:** http://ggplg.valicek.name/plugin/DebugHelper

## Licence

Projekt je licencován pod GNU General Public License v3.0.

## O aplikaci

- **Autor:** mikrom (https://www.mikrom.cz)
- **Verze:** 4.0.1
- **Forum:** http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
- **Ikona:** https://icons8.com/icon/18401/Thumb-Up

---

*Checker v4 - Modernizace pro budoucnost geocachingu* 🚀