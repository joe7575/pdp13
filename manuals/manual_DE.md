# PDP13 Minicomputer (TA3)

PDP13 ist ein 16-Bit-Minicomputer, inspiriert von DEC, IBM und anderen Computer aus den 60er und 70er Jahren. "Mini" deshalb, weil die Rechenanlagen bis dahin nicht nur Schränke, sondern ganze Räume oder Hallen gefüllt hatten. Erst mit der Erfindung der ersten integrierten Schaltkreisen ließen sich die Rechner auf Kleiderschrankgröße reduzieren. Damit passt dieser Computer ideal in das Ölzeitalter. Dadurch dass dieser Computer nur in Maschinencode programmiert werden kann (wie die Originale damals auch), setzt dies einiges an Computerwissen voraus, was nicht in dieser Anleitung vermittelt werden kann.

Voraussetzungen sind damit:

- Grundkenntnisse in Englisch (weitere Dokumente nur in englisch)
- Rechnen mit HEX-Zahlen (16 Bit System)
- Grundkenntnisse im Aufbau einer CPU (Register, Speicheradressierung) und Assemblerprogrammierung
- Ausdauer und Lernbereitschaft, denn PDP13 ist anders, als alles, was du evtl. schon kennst

Der PDP13 Minicomputer wird aber im Spiel auch nicht benötigt, sondern dient eher als Lehrmaterial in Computergrundlagen und Computergeschichte. Er kann aber wie die anderen Controller zur Steuerung von Maschinen eingesetzt werden. Die PDP13 Mod bringt auch eigene Ausgabeblöcke mit, so dass sich viele Möglichkeiten zur Anwendung bieten.

Aufgrund der Länge dieses Textes empfiehlt sich, diese Anleitung direkt auf GitHub zu lesen. Über den Link `github.com/joe7575/pdp13/wiki` kommst du direkt zu der Seite mit Anleitungen und weiteren Links (todo).

[pdp13_cpu|image]


## Anleitung

- Crafte die 3 Blöcke "PDP-13 Power Module", "PDP-13 CPU" und "PDP-13 I/O Rack".
- Das Rack gibt es in 2 Varianten, die sich aber nur vom Frontdesign unterschieden
- Setzte den CPU Block auf den Power Block und das I/O-Rack direkt neben den Power Block
- Diese Reihenfolge muss eingehalten werden, sonst können sich die I/O-Racks nicht mit der CPU verbinden. Der maximale Abstand zwischen einem Erweiterungsblock und der CPU beträgt 3 Blöcke. Dies gilt auch für Telewriter, Terminal und alle weiteren Blöcke.
- Über den Power Block wird die CPU und die weiteren Blöcke eingeschaltet
- Das I/O-Rack kann nur konfiguriert werden, wenn der Power Block ausgeschaltet ist
- Die CPU kann nur programmiert werden, wenn der Power Block eingeschaltet ist (logisch)

[pdp13_cpu|image]


## I/O Rack

Das I/O-Rack verbindet die CPU mit der Welt, also anderen Blöcken und Maschinen. Es können mehrere I/O-Blöcke pro CPU genutzt werden

- Das erste I/O-Rack belegt die I/O-Adressen #0 bis #7. Diesen Adressen können über das Menü des I/O-Racks Blocknummern zugeordnet werden
- Kommandos, welche an Adresse #0 bis #7 ausgegeben werden, werden dann vom I/O-Rack an den entsprechenden Block weitergegeben
- Kommandos, die an die CPU bzw. an die Nummer der CPU gesendet werden (bspw. von einem Schalter) können so wieder eingelesen werden
- Das Description Feld ist optional und muss nicht beschrieben werden
- Das "OUT" Feld zeigt den zuletzt ausgegebenen Wert/das zuletzt ausgegebene Kommando
- Das "IN" Feld zeigt entweder das empfangene Kommando oder die Antwort auf ein gesendetes Kommando. Wird 65535 ausgegeben, wurde kein Antwort empfangen (viele Blöcke senden keine Anwort auf ein "on"/"off" Kommando)
- Das "help" Register zeigt eine Tabelle mit Informationen zur Umsetzung von Ein/Ausgabe Werten der CPU zu Techage Kommandos (Die CPU kann nur Nummern ausgeben, diese werden dann in Techage Text-Kommandos umgesetzt und umgekehrt)

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

Das "help" Register zeigt die wichtigsten Assemblerbefehle und jeweils den Maschinencode dazu. Mit diesem Subset an Befehlen kann man bereits arbeiten. Weitere Informationen zum Befehlssatz findest du [hier](https://github.com/joe7575/vm16/blob/master/doc/introduction.md) und [hier](https://github.com/joe7575/vm16/blob/master/doc/opcodes.md).

Am Ende der Tabelle werden die System-Kommandos aufgeführt. Dies sind quasi Betriebssystemtaufrufe, welche zusätzliche Befehle ausführen, die sonst nicht möglich wären, wie bspw. einen Text auf dem Telewriter auszugeben. 

### Performance

Die CPU ist in der Lage, bis zu 100.000 Befehle pro Sekunde (0.1 MIPS) auszuführen. Dies gilt, solange nur interne CPU-Befehle ausgeführt werden. Dabei gibt es folgende Ausnahmen:

- Der `sys` und der `in` Befehl "kosten" bis zu 1000 Zyklen, da hier externer Code ausgeführt wird. 
- Der `out` Befehl unterbricht die Ausführung für 100 ms, sofern sich der Wert am Ausgang ändert und eine externe Aktionen in der Spielwelt durchgeführt werden muss. Anderenfalls sind es auch nur die 1000 Zyklen.
- Der `nop` Befehl, der für Pausen genutzt werden kann, unterbricht die Ausführung auch für 100 ms.

Ansonsten läuft die CPU "full speed", aber nur solange der Bereich der Welt geladen ist. Damit ist die CPU fast so schnell wie ihr großes Vorbild, die DEC PDP-11/70 (0.4 MIPS). 

[pdp13_cpu|image]

## PDP-13 Telewriter

Der Telewriter war das Terminal an einem Minicomputer. Ausgaben erfolgten nur auf Papier, Eingaben über die Tastatur. Eingegebene Zeichen konnten an den Rechner gesendet, oder auch auf ein Band (tape) geschrieben werden. Dabei wurden Löcher in das Tape gestanzt. Diese Tapes konnten dann wieder eingelegt und abgespielt werden, so dass gespeicherte Programme wieder an den Computer übertragen werden konnten. Das Tape erfüllte damit die Aufgabe einer Festplatte, eines USB-Sticks oder sonstige Speichermedien.

Auch hier dient  das Terminal zur Ein-/Ausgabe und zum Schreiben und Lesen von Tapes, wobei es zwei Typen von Telewriter Terminals gibt:

- Telewriter Operator für normale Ein-/Ausgaben aus einem laufenden Programm
- Telewriter Programmer für die Programmierung der CPU über Assembler (Monitor ROM Chip wird benötigt)

Beide Typen können an einer CPU "angeschlossen" sein, wobei es pro Typ maximal ein Gerät sein darf, also in der Summe maximal zwei.

Über das "tape" Menü des Telewriters können Programme von Punch Tape zum Rechner (Schalter "tape -> PDP13") und vom Rechner auf das Punch Tape (Schalter "PDP13 -> tape") kopiert werden. In beiden Fällen muss dazu ein Punch Tape "eingelegt" sein. Die CPU muss dazu eingeschaltet (power) und gestoppt sein. Ob die Übertragung geklappt hat, wird auf Papier ausgegeben ("main" Menü-Register). 

Über das "tape" Menü können auch Demo Programme auf ein Punch Tape kopiert und anschließend in den Rechner geladen werden. Diese Programme zeigen, wie man elementare Funktionen des Rechners programmiert.

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

## PDP13 Punch Tape

Neben den Demo Tapes mit festen, kleinen Programmen gibt es auch die beschreibbaren und editierbaren Punch Tapes. Diese können (im Gegensatz zum Original) mehrfach geschrieben/geändert werden.

Die Punch Tapes besitzen ein Menü so dass diese auch von Hand beschrieben werden können. Dies dient dazu:

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

## PDP13 Memory Rack

Dieser Block vervollständigt als 4. Block den Rechneraufbau. Der Block hat ein Inventar für Chips zur Speichererweiterung. Der Rechner hat intern 4 KWords an Speicher (4096 Worte) und kann durch einen 4 K RAM Chip auf 8 KWords erweitert werden. Mit einem zusätzlichen 8 K RAM Chip kann der Speicher dann auf 16 KWords erweitert werden. Theoretisch sind bis zu 64 KWords möglich.

In der unteren Reihe kann das Rack bis zu 4 ROM Chips aufnehmen. Diese ROM Chips beinhalten Programme und sind quasi das BIOS (basic input/output system) des Rechners. ROM Chips kann man nur auf der TA3 Elektronikfabrik produzieren. Das Programm für den Chip muss man dazu auf Tape besitzen, welches dann mit Hilfe der Elektronikfabrik auf den Chip "gebrannt" wird. An diese Programme kommt man nur, wenn man entsprechende Programmieraufgaben gelöst hat (dazu später mehr).

Das Inventar des Speicherblocks lässt sich nur in der vorgegebenen Reihenfolge von links nach rechts füllen. Der Rechner muss dazu ausgeschaltet sein.

[pdp13_iorack|image]

## Minimal Beipiel

Hier ein konkretes Beispiel, das den Umgang mit der Mod zeigt. Ziel ist es, die TechAge Signallampe (nicht die PDP13 Color Lamp!) einzuschalten. Dazu muss man den Wert 1 über ein `out` Befehl an dem Port ausgeben, wo die Lampe "angeschlossen" ist. Das Assembler-Programm dazu sieht aus wie folgt:

```assembly
mov A, #1   ; Lade das A-Register mit den Wert 1
out #0, A   ; Gebe den Wert aus dem A-Register auf I/O-Adresse 0 aus
halt        ; Stoppe die CPU nach der Ausgabe
```

Da der Rechner diese Assemblerbefehle nicht direkt versteht, muss das Programm in Maschinencode übersetzt werden. Dazu dient die Hilfeseite im Menü des CPU-Blocks. Das Ergebnis sieht dann so aus (der Assemblercode steht als Kommentar dahinter):

```assembly
2010 0001   ; mov A, #1  
6600 0000   ; out #0, A
1C00        ; halt
```

`mov A` entspricht dem Wert `2010`, der Parameter `#1` steht dann im zweiten Wort `0001`. Über das zweite Wort lassen sich so Werte von 0 bis 65535 (0000 - FFFF) in das Register A laden.  Ein `mov B` ist beispielsweise `2030`. A und B sind Register der CPU, mit denen die CPU rechnen kann, aber auch alle `in` und `out` Befehle gehen über diese Register. Die CPU hat noch weitere Register, diese werden für einfache Aufgaben aber nicht benötigt.

Bei allen Befehlen mit 2 Operanden steht das Ergebnis der Operation immer im ersten Operand, bei `mov A, #1` also in A. Beim `out #0, A` wird A auf den I/O-Port #0 ausgegeben. Der Code dazu ist `6600 0000`. Da sehr viele Ports unterstützt werden, steht dieser Wert #0 wieder im zweiten Wort. Damit lassen sich wieder bis zu 65535 Ports adressieren.

Diese 5 Maschinenbefehle müssen bei der CPU eingegeben werden, wobei für `0000` auch nur `0` eingegeben werden darf (führende Nullen sind nicht relevant).

Dazu sind die folgenden Schritte notwendig:

- Rechner mit Power, CPU, und einem IO-Rack aufbauen wie oben beschrieben
- 7-Segment Bock in die Nähe setzen und die Nummer des Blockes im Menü des I/O-Racks in der obersten Zeile bei Adresse #0 eingeben
- Den Rechner am Power Block einschalten
- Die CPU gegebenenfalls stoppen und mit "reset" auf die Adresse 0 setzen
- Den 1. Befehl eingeben und mit "enter" bestätigen: `2010 1`
- Den 2. Befehl eingeben und mit "enter" bestätigen: `6600 0`
- Den 3. Befehl eingeben und mit "enter" bestätigen: `1C00`
- Die Tasten "reset" und "dump" drücken und die Eingaben überprüfen
- Nochmals die Taste "reset" und dann die Taste "start" drücken

Wenn du alles richtig gemacht hast, leuchtet danach die Lampe. Das "OUT" Feld im Menü des I/O-Racks zeigt die ausgegebene 1, das "IN" Feld zeigt eine 65535, da von der Lampe keine Antwort gesendet wird.

[pdp13_cpu|image]

## Monitor ROM

Hat man den Rechner mit dem "Monitor ROM" Chip erweitert und ein "Telewriter Programmer" Terminal angeschlossen, kann man den Rechner in Assembler programmieren. Dies ist deutlich komfortabler und weniger fehleranfällig.

Das Monitor Programm auf dem Rechner wird durch Eingabe des Kommandos "mon" an der CPU gestartet und über die Taste "stop" auch wieder gestoppt werden. Alle anderen Tasten der CPU sind im Monitor-Mode nicht aktiv. Die Bedienung erfolgt nur über das Terminal. 

Das Monitor Programm unterstützt folgende Kommandos, die auch mit Eingabe von `?` am Telewriter ausgegeben werden (die folgende Tabelle ist in der ingame Hilfe nicht darstellbar):

| Kommando   | Bedeutung                                                    |
| ---------- | ------------------------------------------------------------ |
| `?`        | Hilfetext ausgeben                                           |
| `st`       | Starten der CPU (entspricht der "start" Taste an der CPU)    |
| `sp`       | Stoppen der CPU (entspricht der "stop" Taste an der CPU)     |
| `rt`       | Rücksetzen des Programm Counters (entspricht der "reset" Taste an der CPU) |
| `n`        | Nächsten Befehl ausführen (entspricht der "step" Taste an der CPU) |
| `r`        | Inhalt der CPU Register ausgeben                             |
| `ad #`     | Setzen des Programm Counters (entspricht der "address" Taste an der CPU). `#` ist dabei die Adresse |
| `d #`      | Speicher ausgeben (entspricht der "dump" Taste an der CPU). `#` ist dabei die Startadresse. Wird erneut "enter" gedrückt, wird der nächste Speicherblock ausgegeben |
| `en #`     | Daten eingeben. `#` ist dabei die Adresse. Danach können Werte (Zahlen) eingegeben und mit "enter" übernommen werden |
| `as #`     | Starten des Assemblers. Für `#` muss die Startadresse angegeben werden Danach können Assemblerbefehle eingegeben werden. Aus diesem Mode kommt man durch Eingabe eines anderen Kommandos |
| `di #`     | Ausgabe eines Speicherbereichs der CPU in Assemblerschreibweise (disassemble). Es werden immer 8 Befehle ausgegeben. Wird erneut "enter" gedrückt, werden die nächsten 8 Befehle ausgegeben |
| `ct # txt` | Kopieren von Text in den Speicher, also mit `ct 100 Hallo Welt,` wird der Text an die Adresse 100  kopiert |
| `cm # # #` | Speicher kopieren. Die drei `#` bedeuten: Quell-Adresse, Ziel-Adresse, Anzahl Worte |
| `ex`       | Monitor Mode vom Terminal aus beenden                        |

Auf dem "Terminal Programmer" läuft die Version 2 des Monitors. Diese bietet folgende zusätzliche Kommandos:

| Kommando    | Bedeutung                                                    |
| ----------- | ------------------------------------------------------------ |
| `ld name`   | Laden einer `.com` oder `.h16` Datei in den Speicher         |
| `sys # # #` | Aufrufen eines `sys` Kommandos mit Nummer, Wert für Reg A, Wert für Reg B |
| `br #`      | Setzen eines Breakpoints an der angegebenen Adresse. Es kann nur ein Breakpoint gesetzt werden |
| `br`        | Löschen des Breakpoints                                      |


Alle Kommandos unterstützen die dezimale und hexadezimale Eingabe von Zahlen, `100` ist dezimal und entspricht damit `$64` (hexadezimal).

[pdp13_telewriter|image]

## BIOS ROM

Hat man den Rechner mit dem "BIOS ROM" Chip erweitert, hat der Rechner Zugriff auf das Terminal und auf das Filesystem des Bandlaufwerks und der Festplatte. Der Rechner kann damit theoretisch von einem der Laufwerke booten, wenn er denn eine Betriebssystem hätte, aber dazu später mehr.

Zur Verfügung stehen ab sofort bspw. folgende zusätzliche sys-Kommandos (Das Zeichen `@` bedeutet "Speicheradresse von"):

| sys # | Bedeutung                          | Parameter in A             | Parameter in B  | Ergebnis in A   |
| ----- | ---------------------------------- | -------------------------- | --------------- | --------------- |
| $50   | file open                          | @file name                 | mode `w` / `r`  | file reference  |
| $51   | file close                         | file reference             | -               | 1=ok, 0=error   |
| $52   | read file (ins Shared Memory)      | file reference             | -               | 1=ok, 0=error   |
| $53   | read line                          | file reference             | @destination    | 1=ok, 0=error   |
| $54   | write file (aus dem Shared Memory) | file reference             | -               | 1=ok, 0=error   |
| $55   | write line                         | file reference             | @text           | 1=ok, 0=error   |
| $56   | file size                          | @file name                 | -               | size in bytes   |
| $57   | list files (ins Shared Memory)     | @file name pattern         | -               | number of files |
| $58   | remove files                       | @file name pattern         | -               | number of files |
| $59   | copy file                          | @source file name          | @dest file name | 1=ok, 0=error   |
| $5A   | move file                          | @source file name          | @dest file name | 1=ok, 0=error   |
| $5B   | change drive                       | drive character `t` or `h` |                 | 1=ok, 0=error   |

Zusätzlich beinhaltet der BIOS ROM Chip eine Selbsttest Routine, die beim Einschalten des Rechners ausgeführt und das Ergebnis an der CPU ausgegeben wird (dies dient zur Überprüfung, ob man alles korrekt angeschlossen hat):

```
RAM=8K   ROM=16K   I/O=8
Telewriter..ok  Terminal..ok
Tape drive..ok
```

## Terminal

Sofern das BIOS ROM verfügbar ist, kann am Rechner auch ein Terminal angeschlossen und angesteuert werden. Auch hier gibt es zwei Typen von Terminals:

- Terminal Operator für normale Ein-/Ausgaben aus einem laufenden Programm
- Terminal Programmer für die Programmierung/Fehlersuche über Assembler (Monitor ROM Chip wird benötigt)

Beide Terminals können an einer CPU angeschlossen sein, wobei es pro Typ wieder maximal ein Gerät sein darf, also in der Summe maximal zwei. Das Terminal Programmer ersetzt dabei den Telewriter Programmer, es kann also nur ein Programmer Gerät genutzt werden.

Das Terminal besitzt quasi 3 Betriebsarten:

- Editor-Mode (tbd)
- Terminal-Mode 1 mit zeilenweise Ausgabe von Texten
- Terminal-Mode 2 mit Bildschirmspeicher (48 Zeichen x 16 Zeilen) Hierbei wird immer der komplette Bildschirmspeicher an das Terminal übertragen 

Zu allen drei Betriebsarten gibt es Demoprogramme, die die Funktionsweise zeigen.

Das Terminal besitzt auch zusätzliche Tasten mit folgenden Codierung:  `ESC` = 27, `F1` = 28, `F2` = 29, `F3` = 30, `F4` = 31

Für das Terminal stehen folgende sys-Kommandos zur Verfügung:

| sys # | Bedeutung                        | Parameter in A | Parameter in B | Ergebnis in A |
| ----- | -------------------------------- | -------------- | -------------- | ------------- |
| $10   | clear screen                     | -              | -              | 1=ok, 0=error |
| $11   | print char                       | char/word      | -              | 1=ok, 0=error |
| $12   | print number                     | number         | base: 10 / 16  | 1=ok, 0=error |
| $13   | print string                     | @text          | -              | 1=ok, 0=error |
| $14   | print string with newline        | @text          | -              | 1=ok, 0=error |
| $15   | update screen                    | @text          | -              | 1=ok, 0=error |
| $16   | start editor (<SM)               | @file name     | -              | 1=ok, 0=error |
| $17   | input string                     | @destination   | -              | size          |
| $18   | print from shared memory         | -              | -              | 1=ok, 0=error |
| $19   | flush stdout (Ausgabe erzwingen) |                |                | 1=ok, 0=error |
| $1A   | prompt ausgeben                  |                |                | 1=ok, 0=error |
| $1B   | beep ausgeben                    |                |                | 1=ok, 0=error |

Um die Speicherverwaltung für eine in ASM geschriebene Anwendung bei bestimmten Terminal-Ein-/Ausgaben zu vereinfachen, gibt es in Lua einen zusätzlichen Datenpuffer, hier als "shared memory" bezeichnet. Diesen Puffer verwenden sys-Kommandos, um untereinander Daten auszutauschen. Die CPU hat keinen Zugriff auf diesen Speicher.  Dies wird bspw. dazu genutzt, die Daten  des "list files" Kommando direkt auf dem Terminal auszugeben:

```assembly
move  A, #TEXT          ; file name
sys   #$57              ; list files (->SM)
sys   #$18              ; print SM (<-SM)
```

[pdp13_terminal|image]

## Tape Drive

Das Tape Drive vervollständigt als weitere Block den Rechneraufbau. Damit verfügt der Rechner jetzt über einen echten Massenspeicher, auf dem Daten und Programme wiederholt gespeichert und gelesen werden können. Der Rechner ist mit Hilfe des BIOS ROM Chips auch in der Lage, von diesem Speichermedium zu booten. 

Damit das Tape Drive genutzt werden kann, muss es mit einem Magnetic Tape bestückt und über das Menü gestartet werden. Wird das Tape Drive wieder gestoppt, kann das Tape mit den Daten auch wieder entnommen werden. Damit dienen Tapes auch der Datensicherung und Weitergabe.

Es kann maximal ein Tape Drive am Rechner angeschlossen werden. Das Tape Drive muss bei der Pfadangabe über `t/`, also bspw. `t/myfile.txt` angesprochen werden.

[pdp13_tape_drive|image]

## Hard Disk

Die Hard Disk vervollständigt als weitere Block den Rechneraufbau. Damit verfügt der Rechner jetzt über einen zweiten Massenspeicher mit mehr Kapazität. Der Rechner ist auch hier mit Hilfe des BIOS ROM Chips in der Lage, von diesem Speichermedium zu booten.

Es kann maximal eine Hard Disk am Rechner angeschlossen werden. Der Zugriff auf die Hard Disk erfolgt über `h/`, also bspw. `h/myfile.txt`

Wird dieser Block abgebaut, bleiben die Daten erhalten. Wird der Block zerstört, sind die Daten auch weg.

[pdp13_hard_disk|image]

## Programmieraufgaben

Um einen ROM Chip herstellen zu können, wird das Programm für den Chip auf Tape benötigt. Diese Aufgabe in echt zu lösen wäre zwar eine Herausforderung, aber für 99,9 % der Spieler kaum zu lösen.

Deshalb soll die Programmierung hier simuliert werden, in dem man eine (einfache) Programmieraufgabe löst, was immer noch nicht ganz einfach ist. Aber man bekommt einen Eindruck, wie aufwändig es damals war, ein Programm zu schreiben.

[pdp13_tape|image]

### Aufgabe 1: PDP-13 Monitor ROM

Um das Tape für das PDP-13 Monitor ROM zu erhalten, musst du folgende Aufgabe lösen:

*Berechne den Abstand zwischen zwei Punkten im Raum, wobei der Abstand in Blöcken berechnet werden soll, also wie wenn eine Hyperloop-Strecke von pos1 zu pos2 gebaut werden müsste. Die Blöcke für pos1 und pos2 zählen mit. pos1 und pos2 bestehen aus x, y, z Koordinaten, wobei sich alle Werte im Bereich von 0 bis 1000 bewegen, Wenn man bspw. von (0,0,0) nach (1000,1000,1000) eine Strecke bauen müsste, würde man 3001 Blöcke benötigen.*

Das Programm muss zuerst die 6 Werte (x1, y1, z1, x2, y2, z2) über `sys #300` anfordern und am Ende das Ergebnis wieder über `sys #301` ausgeben. Wenn die Berechnung passt und im "Telewriter Operator" befindet sich ein leeres Tape, dann wird bei passendem Ergebnis das Tape geschrieben. In jedem Falle erfolgt eine Chat-Ausgabe über die berechneten Werte. Hier der Rahmen des Programms:

```assembly
2010 0100  ; move A, #$100  (Zieladresse laden)
0B00       ; sys #$300      (die 6 Werte anfordern, diese stehen dann in $100-$105)
....
0B01       ; sys #$301      (das Rechenergebnis muss zuvor in A gespeichert sein)
1C00       ; halt           (wichtig, sonst läuft das Programm unkontrolliert weiter)
```

[pdp13_tape|image]

### Aufgabe 2: PDP-13 BIOS ROM

Um das Tape für das PDP-13 BIOS ROM zu erhalten, musst du folgende Aufgabe lösen:

*Wandle die übergebenen Wert (0..65535) um in einen String mit der dezimalen Darstellung der Zahl (das was bspw. auch die Lua-Funktion `tostring()` macht).*

Das Programm muss zuerst den Wert über `sys #302` anfordern und am Ende das Ergebnis wieder über `sys #303` ausgeben. Wenn die Umwandlung passt und im "Telewriter Operator" befindet sich ein leeres Tape, dann wird bei passendem Ergebnis das Tape geschrieben. In jedem Falle erfolgt eine Chat-Ausgabe mit den Strings. Hier der Rahmen des Programms:

```assembly
sys #$302      ; den Werte anfordern, dieser stehen dann in A
....
move A, #$nnn  ; A mit der String-Adresse laden
sys #$303      ; Ergebnis übergeben
halt           ; wichtig, sonst läuft das Programm unkontrolliert weiter
```

[pdp13_tape|image]