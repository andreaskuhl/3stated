<h1 name="top"> 3STATED | 3-Zustand-Anzeige </h1>
Widget für die textuelle und farbliche Anzeige von 3 Zuständen einer Quelle (Schalter, Variablen, ...).  
Version 1.0.0

|                      |                                                     |
| -------------------- | --------------------------------------------------- |
| Entwicklungsumgebung | Ethos X20S-Simulator 1.6.3                          |
| Testumgebung         | FrSky Tandem X20, Ethos 1.6.3 EU, Bootloader 1.4.15 |
| Autor                | Andreas Kuhl (https://github.com/andreaskuhl)       |
| Lizenz               | GPL 3.0                                             |

- [Funktionalität](#funktionalität)
- [Ideen zu weiteren Funktionen](#ideen-zu-weiteren-funktionen)
- [Installation](#installation)
- [Danksagung](#danksagung)
- [Bilder](#bilder)
- [Release Informationen](#release-informationen)


# Funktionalität
  - **3 Zustände** (Status) definierbar
    - Unten -> i.d.R. negative Werte
    - Mitte -> i.d.R. Null
    - Oben  -> i.d.R. positive Werte
  - **Zustands-Quelle frei wählbar** (Schalter, Variablen, ...).
  - Je Zustand sind **Text, Hintergrundfarbe und Textfarbe wählbar**.
  - **Schwellenwerte** (SW) frei definierbar
      - Vorbelegung: SW-Unten = -50, SW-Oben = +50
      - Auswerteregel:
        1. kleiner SW-Unten --> Zustand "Unten"
        2. größer/gleich SW-Unten und kleiner SW-Oben -> Zustand "Mitte"
        3. sonst (größer SW-Oben) -> Zustand "Oben"
      - Wenn SW-Unten gleich S-Oben gesetzt wird, reduzieren sich die möglichen Zustände auf "Unten" und "Oben"
        ("Mitte" ist nicht erreichbar).  
      Hinweis: Die verschiedenen Quell-Typen haben auch verschiedene Wertebereiche (Schalter -100 bis 100,
                 Drehregler -1024 bis 1024, ...). Daraus ergeben entsprechend unterschiedlich sinnvolle
                 Schwellenwerte.
  - **Titel und Quelle anzeigen** (jeweils schaltbar), in klein oberhalb des Zustandstextes. Der Titelbereich kann dabei wahlweise in den Zustandsfarben angezeigt werden oder mit gesondert definierten Farben für Hintergrund und Text.
  - **Effiziente Widget-Aktualisierung** nur bei wirklichem Zustandswechsel, also nicht bei jeder Änderung der Zustands-Quelle.
  - **Analyse-Modus** (schaltbar): Ausgabe von Quelle, Wert und Zustandstext. U.a. zum Testen und Ermitteln passender Schwellwerte.
  - **Lokalisierung**: Deutsch (de), Englisch (en), Französisch (fr), Spanisch (es), Italienisch (it) und Tschechisch (cz)

# Ideen zu weiteren Funktionen
  - **Template-Mechanismus**, um verschiedene Konfigurationen des Widgets einfach in ein Modell zu laden.  
  Sinnvoll, da die Konfiguration recht umfangreich geworden ist und in vielen Modellen die gleiche Zustands-Anzeige benötigt wird - z.B. Schleppkupplung offen/geschlossen, Motor-Notaus aktiv/deaktiv, Wölbklappenstellung Thermik/Normal/Speed, ...
  - **Zweizeiliger Zustandstext**, für längere Texte -> Braucht man das?
  - **5-Zustände**, statt 3 auch 5 Zustände - z.B. bei Analogen Reglern -> Braucht man das? 
  - Weitere Lokalisierung -> Bei Bedarf einfach melden ... oder noch besser eine Übersetzung zuliefern.
  
  Bitte melden wenn dafür, bzw. anderen Funktionen, ein Bedarf besteht.  
  => In GitHub ein Issue einstellen, natürlich ebenso bei Fehlern!
  
# Installation
Aus dem aktuellen GitHub-Release die 3stated_x_x_x.zip herunterladen und daraus das Verzeichnis "3stated" in das "scripts"-Verzeichnis der X20-SD-Karte kopieren.
Beim nächsten Sender-Start sollte das Widget auswählbar sein.
Für weitere Details zur LUA-Widget-Skript-Installation einfach im Internet suchen. Dies wurde schon vielfach beschrieben.  

# Danksagung
Vielen Dank für die folgenden hilfreichen Beispiele:
  - Schalteranzeige (V1.4 vom 28.12.2024), JecoBerlin
  - Ethos-Status-widget / Ethos-TriStatus-widget (V2.1 vom 30.07.2025), Lothar Thole (https://github.com/lthole)

# Bilder
Beispiel-Zustandsanzeigen:

![Beispiel Staus-Anzeigen](./images/example.png)

Widget-Konfiguration:

![Konfiguration (Teil 1)](./images/configuration_1.png)

![Konfiguration (Teil 2)](./images/configuration_2.png)

![Konfiguration (Teil 3)](./images/configuration_3.png)

![Konfiguration (Teil 4)](./images/configuration_4.png)


# Release Informationen

| Version |   Datum    | Inhalte                                                                                                                                                                                   |
| ------: | :--------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1.0.2 | 02.09.2025 | Implementierung der Benutzerdaten-Versionsnummer zur Identifizierung und Konvertierung älterer Benutzerdaten älterer Widget-Versions-Daten. Interne Erweiterung für zukünftige Verwendung - kein Update aus Benutzersicht notwendig. |
|   1.0.1 | 31.08.2025 | Update Readme: Angepasste Installations-Beschreibung. Kein eigenständiges Release-Paket.                                                                                                                                     |
|   1.0.0 | 31.08.2025 | Erstes offizielles Release.                                                                                                                                                               |

[↑ Zurück nach oben](#top)
