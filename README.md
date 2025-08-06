# Checker - Nástroj pro ověření souřadnic

Checker je nástroj pro automatické ověření souřadnic u geocaching coordinate checker služeb. Aplikace automatizuje proces odesílání souřadnic na různé webové stránky pro ověření koordinátů a vyhodnocuje výsledky.

## Verze 4.0.0 - Kompletní přepis

Tato verze byla **kompletně přepsána** z AutoHotkey v1 používající Internet Explorer na **AutoHotkey v2 s WebView2** pro lepší kompatibilitu s moderními webovými standardy a budoucí podporu.

### Hlavní změny ve verzi 4:
- ✅ **AutoHotkey v2** - moderní verze AutoHotkey
- ✅ **WebView2** - nahrazuje zastaralý Internet Explorer
- ✅ **Modulární architektura** - služby v samostatných souborech
- ✅ **Podpora schránky** - automatické kopírování zpráv autorů
- ✅ **Dvojí režim** - některé služby podporují ověření koordinátů i odpovědí
- ✅ **Vícejazyčnost** - automatická detekce češtiny/angličtiny
- ✅ **Vylepšené GUI** - profesionální menu a stavový řádek

## Rychlé použití

```batch
Checker.exe služba N 50 15 123 E 015 54 123 "URL_adresa"
```

**Příklad:**
```batch
Checker.exe geochecker S 50 15 123 W 015 54 123 "https://geochecker.com/?language=English"
```

## Podporované služby (24 celkem)

### Aktivní služby (15)
- **certitudes** - certitudes.org *(dvojí režim, schránka)*
- **gccheck** - gccheck.com *(schránka)*
- **geocachefi** - geocache.fi *(rozbalovací seznamy, schránka)*
- **geocheck** - geocheck.org *(oddělená pole, schránka)*
- **geochecker** - geochecker.com *(standardní pole)*
- **gcm** - validator.gcm.cz *(automatická oprava URL)*
- **gzchecker** - gzchecker *(speciální pole, schránka)*
- **hermansky** - geo.hermansky.net *(rozbalovací seznamy)*
- **puzzlechecker** - puzzlechecker.com *(dvojí režim, schránka)*
- **a 6 dalších standardních služeb**

### Nefunkční služby (8)
- **doxina**, **evince**, **komurka** *(mrtvé od 2017)*
- **gccounter** *(mrtvé od 2020-09)*
- **gccounter2** *(mrtvé od 2018-10)*
- **a 3 další**

## Exit kódy

- **0**: Normální ukončení (uživatel zavřel nebo bez kontroly)
- **1**: Souřadnice jsou správné ✅
- **2**: Souřadnice jsou nesprávné ❌
- **3**: Nefunkční služba ⚠️

## Testování

Adresář `test/` obsahuje testovací soubory pro všechny služby:
```batch
cd test
Test.Geochecker.bat
```

## Konfigurace

Nastavení jsou uložena v souboru `Checker.ini`:
- `answer=1` - Povolit kontrolu výsledků a exit kódy
- `debug=0` - Režim ladění
- `copymsg=1` - Kopírovat zprávy autorů do schránky
- `timeout=10` - Časový limit načítání stránky (sekundy)

## Požadavky

- **Windows 10/11** (WebView2 je součástí systému)
- **AutoHotkey v2.0** (pro spuštění zdrojového kódu)
- **Internetové připojení**

## Dokumentace

📖 **Hlavní dokumentace:** https://www.geoget.cz/doku.php/user:skript:checker

Kompletní dokumentace včetně instalace, použití a troubleshootingu je k dispozici na výše uvedené adrese.

## Licence

Projekt je licencován pod GNU General Public License v3.0.

## O aplikaci

- **Autor:** mikrom (https://www.mikrom.cz)
- **Verze:** 4.0.0
- **Forum:** http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
- **Ikona:** https://icons8.com/icon/18401/Thumb-Up

---

*Checker v4 - Modernizace pro budoucnost geocachingu* 🚀