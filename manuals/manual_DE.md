# PDP13 Minicomputer (TA3)

PDP13 ist ein 16-Bit-Minicomputer, inspiriert von DEC, IBM und anderen Computer aus den 60er und 70er Jahren. "Mini" deshalb, weil die Rechnenanlagen bis dahin nicht nur Schränke, sondern ganze Räume oder Hallen gefüllt hatten. Erst mit der Erfindung der ersten integrierten Schaltkreisen ließen sich die Rechner auf Kleiderschrankgröße reduzieren. Damit passt dieser Computer ideal in das Ölzeitalter. Dadurch dass dieser Computer nur in Maschinencode programmiert werden kann (wie die Originale damals auch), setzt dies einiges an Computerwissen voraus, was nicht in dieser Anleitung vermittelt werden kann.

Voraussetzungen sind damit:

- Grundkenntnisse in Englisch (weitere Dokumente nur in englisch)
- Rechnen mit HEX-Zahlen (16 Bit System)
- Grundkenntnisse im Aufbau einer CPU (Register, Speicheraddressierung) und Assemblerprogrammierung
- Ausdauer und Lernbereitschaft, denn PDP13 ist anders, als alles, was du evtl. schon kennst

Der PDP13 Minicomputer wird aber im Spiel auch nicht benötigt, sondern dient eher als Lehrmaterial in Computergrundlagen und Computergeschichte. Er kann aber wie die anderen Controller zur Steuerung von Maschinen eingesetzt werden. Die PDP13 Mod bringt auch eigene Ausgabeblöcke mit, so dass sich viele Möglichkeiten zur Anwendung bieten.

Aufgrund der Länge empfiehlt sich, diese Anleitung direkt auf GitHub zu lesen. Über den Link `github.com/joe7575/pdp13/wiki` kommt ihr direkt zu der Seite mit Anleitungen und weiteren Links.

[pdp13_cpu|image]


## Anleitung

- Crafte die 3 Blöcke "PDP-13 Power Module", "PDP-13 CPU" und "PDP-13 I/O Rack".
- Das Rack gibt es in 2 Varianten, die sich aber nur vom Frontdesign unterschieden
- Setzte den CPU Block auf den Power Block und das I/O-Rack direkt neben den Power Block
- Diese Reihenfolge muss eingehalten werden, sonst können sich die I/O-Racks nicht mit der CPU verbinden. Der maximale Abstand zwischen einem Erweiterungsblock und der CPU beträgt 2 Blöcke
- Über den Power Block wird die CPU und die weiteren Blöcke eingeschaltet
- Das I/O-Rack kann nur konfiguriert werden, wenn der Power Block ausgeschaltet ist
- Die CPU kann nur programmiert werden, wenn der Power Block eingeschaltet ist (logisch)

[pdp13_cpu|image]


## I/O Rack

Das I/O-Rack verbindet die CPU mit der Welt, also anderen Blöcken und Maschinen. Es können mehrere I/O-Blöcke pro CPU genutzt werden

- Das erste I/O-Rack belegt die I/O-Adressen #0 bis #7. Diesen Adressen können über das Menü des I/O-Racks Blocknummern zugeordnet werden
- Kommandow, welche an Adresse #0 bis #7 ausgegeben werden, werden dann vom I/O-Rack an den entsprechenden Block weitergegeben
- Kommandos, die an die CPU bzw. an die Nummer der CPU gesendet werden (bspw. von einem Schalter) können so wieder eingelesen werden
- Das Description Feld ist optional und muss nicht beschrieben werden
- Das "OUT" Feld zeigt den zuletzt ausgegebenen Wert/das zuletzt ausgegebene Kommando
- Das "IN" Feld zeigt entweder das empfangene Kommando oder die Antwort auf ein gesendetes Kommando. Wird 65535 ausgegeben, wurde kein Antwort empfangen (viele Blöcke senden keine Anwort auf ein "on"/"off" Kommando)
- Das "help" Register zeigt eine Tabelle mit Informationen zur Umsetzung von Ein/Ausgabe Werten der CPU zu Techage Kommandos

[pdp13_iorack|image]

## PDP-13 CPU

Der CPU Block ist der Rechenkern der Anlage. Der Block besitzt ein Menü, das echten Minicomputern nachempfunden ist. Über die Schalterreihe mussten bei echten Rechnern die Maschinenbefehle eingegeben werden, über die Lampenreihen wurden Speicherinhalte ausgegeben.

Hier werden Kommandos aber über die 6 Tasten links und Maschinenbefehle über das Eingabefeld unten eingegeben. Der obere Bereich dient nur zur Ausgabe.

- Über die Taste "start" wird die CPU gestartet. Sie startet dabei immer an der aktuellen Adresse des Program Counters (PC), welche bspw. auch oben über die Lampenreihe angezeigt wird.
- Über die Taste "stop" wird eine gestartete CPU wieder gestoppt. Ob die CPU gestartet oder gestoppt ist, sieht man bspw. oben an der "run" Lampe.
- Über die Taste "reset" wird der Program Counter auf Null gesetzt (CPU muss dazu gestoppt sein)
- Über die Taste "step" führt die CPU genau einen Befehl aus. Im Ausgabefeld sieht man dann die Registerwerte, den ausgeführten Maschinencode sowie den Maschinencode, der mit dem nächsten "step" ausgeführt wird.
- Über die Taste "address" kann der Program Counter auf einen Wert gesetzt werden.
- Über die Taste "dump" wird ein Speicherbereich ausgegeben. Die Startadresse muss zuvor über die Taste "address" eingegeben worden sein.

Das "help" Register zeigt die wichtgsten Assemblerbefehle und jeweils den Maschinencode dazu. Mit diesem Subset an Befehlen kann man bereits arbeiten. Weitere Informationen zum Befehlssatz findest du [hier](https://github.com/joe7575/vm16/blob/master/doc/introduction.md) und [hier](https://github.com/joe7575/vm16/blob/master/doc/opcodes.md).

Am Ende der Tabelle werden die System Kommandos aufgeführt. Dies sind quasi Betriebssystemsaufrufe, welche zusätzliche Befehle ausführen, die sonst nicht möglich wären, wie bspw. einen Text auf dem Telewriter ausgeben. 

### Performance

Die CPU ist in der Lage, bis zu 100.000 Befehle pro Sekunde (0.1 MIPS) auszuführen. Dies gilt, solange nur interne CPU-Befehle ausgeführt werden. Dabei gibt es folgende Ausnahmen:

- Der `sys` und der `in` Befehl "kosten" pauschal 1000 Zyklen, da hier externer Code ausgeführt wird. 
- Der `out` Befehl unterbricht die Ausführung für 100 ms, sofern sich der Wert am Ausgang ändert und eine externe Aktionen in der Spielewelt durchgeführt werden muss. Anderenfalls sind es auch nur die 1000 Zyklen.
- Der `nop` Befehl, der für Pausen genutzt werden kann, unterbricht die Ausführung auch für 100 ms.

Ansonsten läuft die CPU "full speed", aber nur solange der Bereich der Welt geladen ist. Damit ist die CPU fast so schnell wie ihr großen Vorbild, die DEC PDP-11/70 (0.4 MIPS). 

TODO:

- Speichererweiterungenüber ein Memory-Rack.
- ROM Erweiterung über den ROM Block und ROM Chips, bspw. das Monitor-ROM mit asm/disasm

[pdp13_cpu|image]

## PDP-13 Telewriter

Der Telewriter war das Terminal an einem Minicomputer. Ausgaben erfolgten nur auf Papier, Eingaben über die Tastatur. Eingegebene Zeichen konnten an den Rechner gesendet, oder auch auf ein Band (tape) geschrieben werden. Dabei wurden Löcher in das Tape gestanzt. Diese Tapes konnten dann wieder eingelegt und abgespielt werden, so dass gespeicherte Programme wieder an den Computer übertragen werden konnten.

Auch hier dient  das Terminal zur Ein-/Ausgabe und zum Schreiben und Lesen von Tapes. 

Es gibt bereits mehrere Demo Tapes, die über das "tape" Menü-Register in den Telewriter eingelegt und über die Schalter an die PDP13 CPU gesendet werden können. Die CPU muss dazu aber eingeschaltet (power) und gestoppt sein. Ob die Übertragung geklappt hat, wird auf Papier ausgegeben ("main" Menü-Register). 

Eigene Programme können so auch auf Tape gespeichert und später wieder wieder eingelesen und abgearbeitet werden. 

Der Telewriter kann über folgende `sys` Befehle angesprochen werden:

```assembly
; Ausgabe Text
move    A, #100     ; Lade A mit der Adresse des Textes
sys     #0          ; Ausgabe Text auf dem Telewriter

; Einlesen Text
move    A, #100     ; Lade A mit der Zieladresse, wo der Text hin soll (32 Zeichen max.)
sys     #1          ; Einlesen Text vom Telewriter (In A wird die Anzahl der Zeichen zurück geliefert, oder 65535)

; Einlesen Zahl
sys     #2          ; Einlesen Zahl vom Telewriter, das Ergebnis steht in A 
                    ; (65535 = kein Wert eingelesen)
```



[pdp13_telewriter|image]

## PDP13 Tape

Neben den Demo Tapes mit festen, kleinen Programmen gibt es ach die beschreibbaren und editierbaren Tapes. Diese können (im Gegensatz zum Original) mehrfach geschrieben/geändert werden.

Die Tapes besitzen ein Menü so dass diese uch von Hand beschrieben werden können. Dies dient dazu:

- dem Tape einen eindeutigen Namen zu geben
- zu beschreiben, wie das Programm genutzt werden kann (Description)
- direkt ein H16 File in das Code-Fenster zu kopieren, welches bspw. am eigenen PC erstellt wurde (vm16asm). 

[pdp13_tape|image]

## PDP13 7-Segment

Über diesen Block kann eine HEX-Ziffer, also 0-9 und A-F ausgegeben werden, indem Werte von 0 bis 15 über das Kommando `value` an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Werte größer 15 löschen die Ausgabe.

Lua: `$send_cmnd(num, "value", 0..16)`

Asm:

```assembly
move A, #$80    ; 'value' command
move B, #8      ; value 0..16 in B
out #00, A      ; output on port #0
```

[pdp13_7segment|image]

## PDP13 Color Lamp

Dieser Lampenblock kann in verschiedenen Farben leuchten. Dazu müssen Werte von 1-64 über das Kommando `value`an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Der Werte 0 schaltet die Lampe aus.

Lua: `$send_cmnd(num, "value", 0..64)`

Asm:

```assembly
move A, #$80    ; 'value' command
move B, #8      ; value 0..64 in B
out #00, A      ; output on port #0
```

[pdp13_lamp|image]

## Minimal Beipiel

Hier ein konkretes Beispiel, das den Umgang mit der Mod zeigt. Ziel ist es, die TechAge Signallampe (nicht die PDP13 Color Lamp!) einzuschalten. Dazu muss man den Wert 1 über ein `out` Befehl an dem Port ausgeben, wo die Lampe "angeschlossen" ist. Das Assembler-Programm dazu sieht aus wie folgt:

```assembly
mov A, #1   ; Lade das A-Register mit den Wert 1
out #0, A   ; Gebe den Wert aus dem A-Register auf I/O-Adresse 0 aus
halt        ; Stoppe die CPU nach der Ausgabe
```

Da der Rechner diese Asemblerbefehle nicht direkt versteht, muss das Programm in Maschinencode übersetzt werden. Dazu dient die Hilfeseite im Menü des CPU-Blocks. Das Ergebnis sieht dann so aus:

```
2010 0001
6600 0000
1C00
```

Diese Maschinenbefehle müssen bei der CPU eingegeben werden, wobei für `0000` auch nur `0` eingegeben werden darf (führende Nullen sind nicht relevant).

Dazu sind die folgenden Schritte notwendig:

- Rechner mit Power, CPU, und IO-Rack aufbauen wie oben beschrieben
- 7-Segement Bock in die Nähe setzen und die Nummer des Blockes im Menü des I/O-Racks in der obersten Zeile bei Adresse #0 eingeben
- Den Rechner am Power Block einschalten
- Die CPU gegebenenfalls stoppen und mit "reset" auf die Adresse 0 setzen
- Den 1. Befehl eingeben und mit "enter" bestätigen: `2010 1`
- Den 2. Befehl eingeben und mit "enter" bestätigen: `6600 0`
- Den 3. Befehl eingeben und mit "enter" bestätigen: `1C00`
- Die Tasten "reset" und "dump" drücken und die Eingaben überprüfen
- Nochmals die Taste "reset" und dann die Taste "start" drücken

Wenn du alles richtig gemacht hast, leuchtet danach die Lampe. Das "OUT" Feld im Menü des I/O-Racks zeigt die ausgegebene 1, das "IN" Feld zeigt eine 65535, da von der Lampe keine Antwort gesendet wird.

[pdp13_cpu|image]

