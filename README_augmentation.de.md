## Augmentation

Als *Augmentation* bezeichnen wir einen besonderen Anwendungsfall von Irma, bei
dem die Benutzeroberfläche einer bestehenden Webanwendung (z.B. GEPRIS) um
Funktionalität erweitert wird, *ohne dass dabei die ursprüngliche Codebasis
angepasst werden muss*. Hierzu wird ein oder mehrerere Javascript-Module in
die Ursprüngliche Weboberfläche injiziert, die die neuen Funktionen Client-seitig
umsetzen oder aber an entsprechende Webservices delegieren. `Irma` stellt die
dafür notwendigen Middleware-Komponenten zur Verfügung, deren Zusammenspiel beispielhaft
anhand folgender Darstellung beschrieben werden soll:

![Kommunikationsdiagram zum UC Augmentation](skizze.svg)

Der `Anwender` öffnet in gewohnter Weise GEPRIS im Webbrowser (1).  Der
`Browser` schickt einen entsprechenden Request an `Irma` (1.1).  `Irma`
übergibt den Request intern an die `Proxy`-Komponente, die ihn wiederum an die
ursprüngliche Webanwendung `GEPRIS` weiterleitet (1.1.1).  `GEPRIS` liefert als
Antwort den HTML-Inhalt der angefragten Seite (1.1.1.1).  Die
`Proxy`-Komponente stellt anhand hinterlegter Regeln fest, ob und wie der
HTML-Inhalt modifziert werden muss. Dieser Schritt ist vergleichbar mit den
XSLT-Override-Regeln in GEPRIS, ist aber technisch anders gelöst und -- ganz
wichtig! -- kein Teil von `GEPRIS`.  Im gegebenen Beispiel ändert der `Proxy`
den HTML-Inhalt und fügt Referenzen auf ein zusätzliches Javascript-Modul
`/client.js` sowie mglw. zusätzliche Style-Sheets ein. Dann gibt `Irma` den so
"augmentierten" Inhalt zurück an den `Browser` (1.1.2).  Beim Aufbau der Seite
stößt dieser auf die Referenz zu besagtem Javascript-Modul und generiert eine
weitere Anfrage (1.2). `Irma` übergibt diesen Request intern an den
`FileServer`, der wiederum den Inhalt einer zu dem Request passenden Datei aus
dem lokalen `Dateisystem` liest (1.2.1 und 1.2.1.1). Der Javascript-Code des
Moduls wird zurück an den `Browser` zurückgegeben. Dieser interpretiert den
Code und erzeugt daraus eine Laufzeit-Instanz `Client` (1.2.2.1).  Und diese
`Client`-Komponente ist schließlich für die eigentliche Erweiterung der
Funktionalität von GEPRIS verantwortlich.  Dies geschieht in erster Linie durch
DOM-Scritping, d.h. dynamische Modifikation des HTML DOMs (1.2.2.1.1).

Nehmen wir für das Beispiel an, der `Client` würde die Such-Ansicht von GEPRIS
um einen neuen Reiter erweitern, der seinerseits eine neue Suchfunktionalität realisiert.
Er kann Suchanfragen des `Anwenders` (2) abfangen und entsprechende asynchrone
Anfragen an `Irma`s REST `API` stellen (2.1). Völlig analog zum Vorgehen im
Falle der GEPRIS-App werden diese Anfragen interpretiert, in geeigneter Form
ans Backend (z. Zt. `ElasticSearch`) weitergegeben(2.1.1). Ebenso ist die
Backend-spezifische interpretation der Ergebnisse (2.1.1.1 und 2.1.2) Aufgabe
dieser `API`-Komponente.  Zurück im `Browser` kann der `Client` die Ergebnisse verarbeiten
und sichtbar machen(2.1.2.1).


