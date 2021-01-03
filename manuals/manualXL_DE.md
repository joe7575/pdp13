# PDP-13 Minicomputer (TA3)

PDP-13 ist ein 16-Bit-Minicomputer, inspiriert von DEC, IBM und anderen Computer aus den 60er und 70er Jahren. "Mini" deshalb, weil die Rechenanlagen bis dahin nicht nur Schränke, sondern ganze Räume oder Hallen gefüllt hatten. Erst mit der Erfindung der ersten integrierten Schaltkreisen ließen sich die Rechner auf Kleiderschrankgröße reduzieren. Damit passt dieser Computer ideal in das Ölzeitalter. Dadurch dass dieser Computer nur in Maschinencode programmiert werden kann (wie die Originale damals auch), setzt dies einiges an Computerwissen voraus, was nicht in dieser Anleitung vermittelt werden kann.

Voraussetzungen sind damit:

- Grundkenntnisse in Englisch (weitere Dokumente nur in englisch)
- Rechnen mit HEX-Zahlen (16 Bit System)
- Grundkenntnisse im Aufbau einer CPU (Register, Speicheradressierung) und Assemblerprogrammierung
- Ausdauer und Lernbereitschaft, denn PDP-13 ist anders, als alles, was du evtl. schon kennst

Der PDP-13 Minicomputer wird aber im Spiel auch nicht benötigt, sondern dient eher als Lehrmaterial in Computergrundlagen und Computergeschichte. Er kann aber wie die anderen Controller zur Steuerung von Maschinen eingesetzt werden. Die `pdp13` Mod bringt auch eigene Ausgabeblöcke mit, so dass sich viele Möglichkeiten zur Anwendung bieten.

Aufgrund der Länge dieses Anleitung ist diese nicht in-game, sondern nur über GitHub verfügbar: `github.com/joe7575/pdp13/wiki`.




## Anleitung

- Crafte die 3 Blöcke "PDP-13 Power Module", "PDP-13 CPU" und "PDP-13 I/O Rack".
- Das Rack gibt es in 2 Varianten, die sich aber nur vom Frontdesign unterschieden
- Setzte den CPU Block auf den Power Block und das I/O-Rack direkt neben den Power Block
- Diese Reihenfolge muss eingehalten werden, sonst können sich die I/O-Racks nicht mit der CPU verbinden. Der maximale Abstand zwischen einem Erweiterungsblock und der CPU beträgt 3 Blöcke. Dies gilt auch für Telewriter, Terminal und alle weiteren Blöcke.
- Über den Power Block wird die CPU und die weiteren Blöcke eingeschaltet
- Das I/O-Rack kann nur konfiguriert werden, wenn der Power Block ausgeschaltet ist
- Die CPU kann nur programmiert werden, wenn der Power Block eingeschaltet ist (logisch)




## I/O Rack

Das I/O-Rack verbindet die CPU mit der Welt, also anderen Blöcken und Maschinen. Es können mehrere I/O-Blöcke pro CPU genutzt werden

- Das erste I/O-Rack belegt die I/O-Adressen #0 bis #7. Diesen Adressen können über das Menü des I/O-Racks Blocknummern zugeordnet werden
- Kommandos, welche an Adresse #0 bis #7 ausgegeben werden, werden dann vom I/O-Rack an den entsprechenden Block weitergegeben
- Kommandos, die an die CPU bzw. an die Nummer der CPU gesendet werden (bspw. von einem Schalter) können so wieder eingelesen werden
- Das Description Feld ist optional und muss nicht beschrieben werden
- Das "OUT" Feld zeigt den zuletzt ausgegebenen Wert/das zuletzt ausgegebene Kommando
- Das "IN" Feld zeigt entweder das empfangene Kommando oder die Antwort auf ein gesendetes Kommando. Wird 65535 ausgegeben, wurde kein Antwort empfangen (viele Blöcke senden keine Anwort auf ein "on"/"off" Kommando)
- Das "help" Register zeigt eine Tabelle mit Informationen zur Umsetzung von Ein/Ausgabe Werten der CPU zu Techage Kommandos (Die CPU kann nur Nummern ausgeben, diese werden dann in Techage Text-Kommandos umgesetzt und umgekehrt)



## PDP-13 CPU

Der CPU Block ist der Rechenkern der Anlage. Der Block besitzt ein Menü, das echten Minicomputern nachempfunden ist. Über die Schalterreihe mussten bei echten Rechnern die Maschinenbefehle eingegeben werden, über die Lampenreihen wurden Speicherinhalte ausgegeben.

Hier werden Kommandos aber über die 6 Tasten links und Maschinenbefehle über das Eingabefeld unten eingegeben. Der obere Bereich dient nur zur Ausgabe.

- Über die Taste "start" wird die CPU gestartet. Sie startet dabei immer an der aktuellen Adresse des Program Counters (PC), welche bspw. auch oben über die Lampenreihe angezeigt wird.
- Über die Taste "stop" wird eine gestartete CPU wieder gestoppt. Ob die CPU gestartet oder gestoppt ist, sieht man bspw. oben an der "run" Lampe.
- Über die Taste "reset" wird der Program Counter auf Null gesetzt (CPU muss dazu gestoppt sein)
- Über die Taste "step" führt die CPU genau einen Befehl aus. Im Ausgabefeld sieht man dann die Registerwerte, den ausgeführten Maschinencode sowie den Maschinencode, der mit dem nächsten "step" ausgeführt wird.
- Über die Taste "address" kann der Program Counter auf einen Wert gesetzt werden.
- Über die Taste "dump" wird ein Speicherbereich ausgegeben. Die Startadresse muss zuvor über die Taste "address" eingegeben worden sein.

**Alle Zahlenangaben sind in hexadezimaler Form  einzugeben!**

Das "help" Register zeigt die wichtigsten Assemblerbefehle und jeweils den Maschinencode dazu. Mit diesem Subset an Befehlen kann man bereits arbeiten. Weitere Informationen zum Befehlssatz findest du [hier](https://github.com/joe7575/vm16/blob/master/doc/introduction.md) und [hier](https://github.com/joe7575/vm16/blob/master/doc/opcodes.md).

Am Ende der Tabelle werden die System-Kommandos aufgeführt. Dies sind quasi Betriebssystemtaufrufe, welche zusätzliche Befehle ausführen, die sonst nicht möglich wären, wie bspw. einen Text auf dem Telewriter auszugeben. 

### Performance

Die CPU ist in der Lage, bis zu 100.000 Befehle pro Sekunde (0.1 MIPS) auszuführen. Dies gilt, solange nur interne CPU-Befehle ausgeführt werden. Dabei gibt es folgende Ausnahmen:

- Der `sys` und der `in` Befehl "kosten" bis zu 1000 Zyklen, da hier externer Code ausgeführt wird. 
- Der `out` Befehl unterbricht die Ausführung für 100 ms, sofern sich der Wert am Ausgang ändert und eine externe Aktionen in der Spielwelt durchgeführt werden muss. Anderenfalls sind es auch nur die 1000 Zyklen.
- Der `nop` Befehl, der für Pausen genutzt werden kann, unterbricht die Ausführung auch für 100 ms.

Ansonsten läuft die CPU "full speed", aber nur solange der Bereich der Welt geladen ist. Damit ist die CPU fast so schnell wie ihr großes Vorbild, die DEC PDP-11/70 (0.4 MIPS). 



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



## Demo Punch Tapes

Es gibt mehrere Demo Punch Tapes, die mit Hilfe des Telewrites "gestanzt" werden können. Diese Tapes zeigen grundlegende Programmierbeispiele. Wenn man ein Tape wie ein Buch nutzt, also in die Luft klickt, wird der Code des Tapes angezeigt. Hier das Beispiel zum "Demo: 7-Segment":

```assembly
0000: 2010, 0080    move A, #$80  ; 'value' command
0002: 2030, 0000    move B, #00   ; value in B

loop:
0004: 3030, 0001    add  B, #01
0006: 4030, 000F    and  B, #$0F  ; values from 0 to 15
0008: 6600, 0000    out #00, A    ; output to 7-segment
000A: 0000          nop           ; 100 ms delay
000B: 0000          nop           ; 100 ms delay
000C: 1200, 0004    jump loop
```

Die Ausgabe erfolgt immer nach folgendem Schema:

```assembly
<addr>: <opcodes>   <asm code>    ; <comment>
```



## PDP-13 Punch Tape

Neben den Demo Tapes mit festen, kleinen Programmen gibt es auch die beschreibbaren und editierbaren Punch Tapes. Diese können (im Gegensatz zum Original) mehrfach geschrieben/geändert werden.

Die Punch Tapes besitzen ein Menü so dass diese auch von Hand beschrieben werden können. Dies dient dazu:

- dem Tape einen eindeutigen Namen zu geben
- zu beschreiben, wie das Programm genutzt werden kann (Description)
- direkt ein H16 File in das Code-Fenster zu kopieren, welches bspw. am eigenen PC erstellt wurde (vm16asm). 



## PDP-13 7-Segment

Über diesen Block kann eine HEX-Ziffer, also 0-9 und A-F ausgegeben werden, indem Werte von 0 bis 15 über das Kommando `value` an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Werte größer 15 löschen die Ausgabe.

Lua: `$send_cmnd(num, "value", 0..16)`

Asm:

```assembly
move A, #$80    ; 'value' command
move B, #8      ; value 0..16 in B
out #00, A      ; output on port #0
```



## PDP-13 Color Lamp

Dieser Lampenblock kann in verschiedenen Farben leuchten. Dazu müssen Werte von 1-64 über das Kommando `value`an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Der Werte 0 schaltet die Lampe aus.

Lua: `$send_cmnd(num, "value", 0..64)`

Asm:

```assembly
move A, #$80    ; 'value' command
move B, #8      ; value 0..64 in B
out #00, A      ; output on port #0
```



## PDP-13 Memory Rack

Dieser Block vervollständigt als 4. Block den Rechneraufbau. Der Block hat ein Inventar für Chips zur Speichererweiterung. Der Rechner hat intern 4 KWords an Speicher (4096 Worte) und kann durch einen 4 K RAM Chip auf 8 KWords erweitert werden. Mit einem zusätzlichen 8 K RAM Chip kann der Speicher dann auf 16 KWords erweitert werden. Theoretisch sind bis zu 64 KWords möglich.

In der unteren Reihe kann das Rack bis zu 4 ROM Chips aufnehmen. Diese ROM Chips beinhalten Programme und sind quasi das BIOS (basic input/output system) des Rechners. ROM Chips kann man nur auf der TA3 Elektronikfabrik produzieren. Das Programm für den Chip muss man dazu auf Tape besitzen, welches dann mit Hilfe der Elektronikfabrik auf den Chip "gebrannt" wird. An diese Programme kommt man nur, wenn man entsprechende Programmieraufgaben gelöst hat (dazu später mehr).

Das Inventar des Speicherblocks lässt sich nur in der vorgegebenen Reihenfolge von links nach rechts füllen. Der Rechner muss dazu ausgeschaltet sein.



## Minimal Beipiel

Hier ein konkretes Beispiel, das den Umgang mit der Mod zeigt. Ziel ist es, die TechAge Signallampe (nicht die PDP-13 Color Lamp!) einzuschalten. Dazu muss man den Wert 1 über ein `out` Befehl an dem Port ausgeben, wo die Lampe "angeschlossen" ist. Das Assembler-Programm dazu sieht aus wie folgt:

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



## Monitor ROM

Hat man den Rechner mit dem "Monitor ROM" Chip erweitert und ein "Telewriter Programmer" Terminal angeschlossen, kann man den Rechner in Assembler programmieren. Dies ist deutlich komfortabler und weniger fehleranfällig.

Das Monitor Programm auf dem Rechner wird durch Eingabe des Kommandos "mon" an der CPU gestartet und kann über die Taste "stop" auch wieder gestoppt werden. Alle anderen Tasten der CPU sind im Monitor-Mode nicht aktiv. Die Bedienung erfolgt nur über das Terminal. 

Das Monitor Programm unterstützt folgende Kommandos, die auch mit Eingabe von `?` am Telewriter ausgegeben werden:

| Kommando   | Bedeutung                                                    |
| ---------- | ------------------------------------------------------------ |
| `?`        | Hilfetext ausgeben                                           |
| `st [#]`   | Starten der CPU (entspricht der "start" Taste an der CPU). Die Startadresse kann optional eingegeben werden |
| `sp`       | Stoppen der CPU (entspricht der "stop" Taste an der CPU)     |
| `rt`       | Rücksetzen des Programm Counters (entspricht der "reset" Taste an der CPU) |
| `n`        | Nächsten Befehl ausführen (entspricht der "step" Taste an der CPU). Wird  danach "enter" gedrückt, wird der nächste Befehl ausgeführt. |
| `r`        | Inhalt der CPU Register ausgeben                             |
| `ad #`     | Setzen des Programm Counters (entspricht der "address" Taste an der CPU). `#` ist dabei die Adresse |
| `d #`      | Speicher ausgeben (entspricht der "dump" Taste an der CPU). `#` ist dabei die Startadresse. Wird danach "enter" gedrückt, wird der nächste Speicherblock ausgegeben |
| `en #`     | Daten eingeben. `#` ist dabei die Adresse. Danach können Werte (Zahlen) eingegeben und mit "enter" übernommen werden |
| `as #`     | Starten des Assemblers. Für `#` muss die Startadresse angegeben werden Danach können Assemblerbefehle eingegeben werden. Aus diesem Mode kommt man durch Eingabe eines anderen Kommandos |
| `di #`     | Ausgabe eines Speicherbereichs der CPU in Assemblerschreibweise (disassemble). Es werden immer 8 Befehle ausgegeben. Wird danach "enter" gedrückt, werden die nächsten 8 Befehle ausgegeben |
| `ct # txt` | Kopieren von Text in den Speicher, also mit `ct 100 Hallo Welt,` wird der Text an die Adresse 100  kopiert |
| `cm # # #` | Speicher kopieren. Die drei `#` bedeuten: Quell-Adresse, Ziel-Adresse, Anzahl Worte |
| `ex`       | Monitor Mode vom Terminal aus beenden                        |

Auf dem "Terminal Programmer" läuft die Version 2 des Monitors. Diese bietet folgende zusätzliche Kommandos:

| Kommando   | Bedeutung                                                    |
| ---------- | ------------------------------------------------------------ |
| `ld name`  | Laden einer `.com` oder `.h16` Datei in den Speicher         |
| `sy # # #` | Aufrufen eines `sys` Kommandos mit Nummer, Wert für Reg A, Wert für Reg B |
| `br #`     | Setzen eines Breakpoints an der angegebenen Adresse. Es kann nur ein Breakpoint gesetzt werden |
| `br`       | Löschen des Breakpoints                                      |

**Alle Zahlenangaben sind in hexadezimaler Form  einzugeben!**

#### Breakpoints

Das Monitor Programm V2 (Terminal) unterstützt einen Software Breakpoint. Dies bedeutet, dass bei Eingabe von bspw. `br 100` an der Adresse $100 der Code mit dem neuen Wert $0400 (`brk #0`) überschrieben wird. Mit `br` (Breakpoint löschen) wird wieder der Originalwert eingetragen. Wird von der CPU der Opcode `$0400` ausgeführt, wird das Programm unterbrochen und der Debugger/Monitor zeigt die Adresse an (der Stern zeigt an, dass hier ein Breakpoint gesetzt wurde). Allerdings wird vom Disassembler der Original Code angezeigt und nicht der `brk`. Bei einem Speicherdump sieht mal allerdings den Wert `$0400`. Der Opcode an der Position wird nach Ausführung dieser Originalanweisung wieder auf `$0400` gesetzt, so dass der Breakpoint auch mehrfach genutzt werden kann. 

Der Breakpoint ist allerdings wieder weg, wenn das Programm neu geladen wurde. Für diesen, aber auch andere Testfälle kann es Sinn machen, eine `brk #0` Aweisung direkt im ASM Code einzufügen. Damit kommt das Programm an dieser Position immer zum Halten, so dass man hier seine Debugging Session starten kann.



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



## PDP-13 Terminal

Sofern das BIOS ROM verfügbar ist, kann am Rechner auch ein Terminal angeschlossen und angesteuert werden. Auch hier gibt es zwei Typen von Terminals:

- Terminal Operator für normale Ein-/Ausgaben aus einem laufenden Programm
- Terminal Programmer für die Programmierung/Fehlersuche über Assembler (Monitor ROM Chip wird benötigt)

Beide Terminals können an einer CPU angeschlossen sein, wobei es pro Typ wieder maximal ein Gerät sein darf, also in der Summe maximal zwei. Das Terminal Programmer ersetzt dabei den Telewriter Programmer, es kann also nur ein Programmer Gerät genutzt werden.

Das Terminal besitzt quasi 3 Betriebsarten:

- Editor-Mode (tbd)
- Terminal-Mode 1 mit zeilenweise Ausgabe von Texten
- Terminal-Mode 2 mit Bildschirmspeicher (48 Zeichen x 16 Zeilen) Hierbei wird immer der komplette Bildschirmspeicher an das Terminal übertragen 

Zu allen drei Betriebsarten gibt es Demoprogramme, die die Funktionsweise zeigen.

Das Terminal besitzt auch zusätzliche Tasten mit folgenden Codierung:  `RTN` = 26, `ESC` = 27, `F1` = 28, `F2` = 29, `F3` = 30, `F4` = 31.
`RTN` oder der Wert 26 wird gesendet, wenn nur "enter" gedrückt wurde, ohne dass zuvor Zeichen in die Eingabezeile eingegeben wurden.

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



## PDP-13 Tape Drive

Das Tape Drive vervollständigt als weitere Block den Rechneraufbau. Damit verfügt der Rechner jetzt über einen echten Massenspeicher, auf dem Daten und Programme wiederholt gespeichert und gelesen werden können. Der Rechner ist mit Hilfe des BIOS ROM Chips auch in der Lage, von diesem Speichermedium zu booten. 

Damit das Tape Drive genutzt werden kann, muss es mit einem Magnetic Tape bestückt und über das Menü gestartet werden. Wird das Tape Drive wieder gestoppt, kann das Tape mit den Daten auch wieder entnommen werden. Damit dienen Tapes auch der Datensicherung und Weitergabe.

Es kann maximal ein Tape Drive am Rechner angeschlossen werden. Das Tape Drive muss bei der Pfadangabe über `t/`, also bspw. `t/myfile.txt` angesprochen werden.



## PDP-13 Hard Disk

Die Hard Disk vervollständigt als weitere Block den Rechneraufbau. Damit verfügt der Rechner jetzt über einen zweiten Massenspeicher mit mehr Kapazität. Der Rechner ist auch hier mit Hilfe des BIOS ROM Chips in der Lage, von diesem Speichermedium zu booten.

Es kann maximal eine Hard Disk am Rechner angeschlossen werden. Der Zugriff auf die Hard Disk erfolgt über `h/`, also bspw. `h/myfile.txt`

Wird dieser Block abgebaut, bleiben die Daten erhalten. Wird der Block zerstört, sind die Daten auch weg.



## J/OS-13 Betriebssystem

Wie jeder echte Rechner macht auch PDP-13 ohne Programme oder Betriebssystem gar nichts. Deshalb müssen entweder Programme über die Punch Tapes in den Rechner geladen werden, oder es müssen Programme auf dem Tape Drive oder Hard Disk vorhanden sein, die in den Speicher geladen und ausgeführt werden können.  Um den Rechner von einem Laufwerk zu starten, muss an der CPU das Kommando `boot` eingegeben werden. Über die Taste "stop" kann die CPU wieder gestoppt werden. Alle anderen Tasten der CPU sind im `boot`-Mode nicht aktiv. Die Bedienung erfolgt nur über das Operator Terminal. 



### Datei `boot`

Befindet sich auf einem der Laufwerte eine Textdatei `boot`, so wird diese vom BIOS eingelesen und interpretiert. Die Datei hat nur eine Textzeile mit dem Dateiamen des Programmes, welches als erstes ausgeführt werden soll. Bei J/OS-13 sieht diese Datei auf dem Tape Drive so aus:

```
t/shell1.h16
```



### Datei `shell1.h16`

Damit wird als nächstes die Datei `shell1.16` vom Tape Drive geladen und mit ab Adresse $0000 ausgeführt. `shell1.h16` ist ein Ladeprogramm, das sich im Adressbereich $0000 - $00BF einnistet und dort auch verbleibt. Jede Anwendung muss, sofern sie beendet wird, wieder zu diesem Ladeprogramm zurückkehren. Dies erfolgt normalerweise über die Anweisung `sys #$71`.

Hier das berühmte "Hello World" Programm für J/OS-13 in `vm16asm` Assembler:

```assembly
; Hello world for the Terminal in COM format

    .org $100
    .code
    
    move  A, B          ; com v1 tag $2001
    move    A, #TEXT
    sys     #$14        ; println
    sys     #$71        ; warm start

    .text
TEXT:
    "Hello "
    "World\0"
```

Die Zeile `move  A, B` macht nichts sinnvolles, außer dass der Wert $2001 generiert wird. Steht dieser Wert am Anfang eines `.com` Files, wird dieses File als ausführbare Datei akzeptiert, geladen und ausgeführt (com v1 version tag) .



### Datei `shell2.com`

Da das Ladeprogramm über keine Kommandos verfügt (der Adressbereich $0000 - $00BF ist dafür viel zu klein), wird nach einem Kaltstart ein zweiter Teil in den Addressbereich ab $0100 nachgeladen. Dieses Programm besitzt eine Kommandozeile mit Kommandos und kann andere Programme von einem Laufwerk laden und ausführen.

Es werden 2 Typen von ausführbaren Programmen unterstützt:

- `.h16` Files sind Textfiles im H16  Format. Dieses Format erlaubt ein Programm an eine definierte Adresse zu laden, wie dies bspw. bei `shell1.h16` der Fall ist. Auch alle Punch Tape Programme sind im H16 Format. Nur so lassen sich technisch Programme über Punch Tapes austauschen.
- `.com` Files sind Files im Binärformat. Das Binärformat ist deutlich kompakter (ca. Faktor 3) und deshalb für Programme die bessere Wahl. `.com` Files werden immer ab Adresse $0100 geladen und müssen dafür entsprechend vorbereitet sein (Anweisung `.org $100`).

Für beide Typen von Programmen gilt:  Die Anwendung muss bei Adresse $0100 starten, darf den Adreessbereich unterhalb von $00C0 nicht verändern und muss am Ende über `sys #$71` wieder zum Betriebsystem zurückkehren.

### Kommandos auf der Konsole

`shell2.com` verfügt über die folgenden Kommandos:

- `ed <name>` um den Editor zu starten. Das angegebene File wird dabei in den Editor geladen. Existiert das File noch nicht, wird es angelegt.
- `<name>.h16` bzw. `<name>.com` um ein Programm von einem der Laufwerke auszuführen.
- `mv <old> <new>` um ein File umzubenennen oder zu verschieben
- `rm <name>` um File(s) zu löschen
- `ls [<wc>]` um die Files auszugeben. Mit `ls` werden alle Files des aktuellen Laufwerks ausgegeben. mit `ls h/*` werden bspw. alle Files des Hard Drives ausgegeben.  Mit `ls test.*` nur Files mit dem Namen "test" und mit  `ls *.com` nur `.com` Files.
- `cp <from> <to>` Um eine Datei zu kopieren. 
- `cd t/h` Um das Laufwerk zu wechseln. Also bspw.  `ls h` für das Hard Drive.

Weitere Kommandos sind als Programm (`.com` File) implementiert und werden daher erst vom Laufwerk geladen, bevor sie ausgeführt werden.



### Kommandos vom Laufwerk

- `hellow`  "Hello world" Testprogramm, das zeigt, wie die Parameterübergabe funktioniert. Das Programm kann ohne `.com` Erweiterung mit mehreren Parametern gestartet werden. Diese werden dann zeilenweise wieder ausgegeben.

- `asm <name>`  um ein File zu h16 zu übersetzen (ohne ext)
- `cat <name>` um den Inhalt einer Datei auszugeben



### Bereich für die Parameterübergabe

Jedes eingegebene Kommando mit seinen Parametern wird von der shell in den Bereich $00C0 - $00FF geladen. Kommandos können daher max. 63 Zeichen lang sein. Das Kommando wird dabei bereits an den Leerzeichen (blanks) in einzelne Strings geteilt. Aus `cp test.txt  h/test.txt` wird damit: `cp`,  `test.txt`  und  `h/test.txt`.



## Programmieraufgaben

Um einen ROM Chip herstellen zu können, wird das Programm für den Chip auf Tape benötigt. Diese Aufgabe in echt zu lösen wäre zwar eine Herausforderung, aber für 99,9 % der Spieler kaum zu lösen.

Deshalb soll die Programmierung hier simuliert werden, in dem man eine (einfache) Programmieraufgabe löst, was immer noch nicht ganz einfach ist. Aber man bekommt einen Eindruck, wie aufwändig es damals war, ein Programm zu schreiben.



### Wertebereiche und Zweierkomplement

Zuvor aber etwas Theorie, was für die folgenden Aufgaben benötigt wird.

PDP-13 ist eine 16-Bit Maschine und kann daher nur Werte von 0 bis 65535 darstellen. Bei einer Darstellung mit Vorzeichen sind es nur Werte von -32768  bis +32767. Hier eine Übersicht der Wertebereiche:

| 16-Bit wert (hex) | Ganzzahl ohne Vorzeichen | Ganzzahl mit Vorzeichen |
| ----------------- | ------------------------ | ----------------------- |
| $0000             | 0                        | 0                       |
| $0001             | 1                        | +1                      |
| $7FFF             | 32767                    | +32767                  |
| $8000             | 32768                    | -32768                  |
| $FFFF             | 65535                    | -1                      |

Soll das Vorzeichen geändert werden, also bspw. eine negative Zahl in eine Positive gewandelt werden, so wendet man das [Zweierkomplement](https://de.wikipedia.org/wiki/Zweierkomplement) Verfahren an:

```
pos_zahl = not(neg_zahl) + 1
```

Oder in Assembler:

```assembly
	bpos  A, weiter  ; positive Zahl: springe zu weiter
	not   A			 ; A = not A
	inc   A			 ; A = A + 1
weiter:
```

Beim Rechnen mit Zahlen muss daher immer der Wertebereich im Auge behalten werden. Bei der Addition von zwei 16-Bit Zahlen kann es zu einem Bereichsüberlauf kommen. 

```
   35567        $8AEF
 + 46123      + $B42B
=========    =========
   81690       $13F1A
```

Dieser Überlaufswert wird bei `addc A, val` (addiere mit carry/Überlauf) im B Register gespeichert und kann in einem zweiten Rechenschritt berücksichtigt werden.



### Aufgabe 1: PDP-13 Monitor ROM

Um das Tape für das PDP-13 Monitor ROM zu erhalten, musst du folgende Aufgabe lösen:

*Berechne die Summe zweier 32-Bit Zahlen ohne Vorzeichen.*

Die Zahlen sind so gewählt, dass es zu keinem 32-Bit Überlauf kommt. Die zwei Zahlen müssen über `sys #$300` anfordern und am Ende das Ergebnis wieder über `sys #$301` ausgeben werden. 

```assembly
; nach sys #$300 stehen die Zahlen wie folgt im Speicher
addr+0  number 1 low word (niederwertige Anteil)
addr+1  number 1 high word (höherwertige Anteil)
addr+2  number 2 low word
addr+3  number 2 high word

; vor sys #$301 muss das Ergebnis so im Speicher stehen
addr+0  result low word
addr+1  result high word
```

Wenn die Berechnung passt und im "Telewriter Operator" befindet sich ein leeres Tape, dann wird bei passendem Ergebnis das Tape geschrieben. In jedem Falle erfolgt eine Chat-Ausgabe über die berechneten Werte. Hier der Rahmen des Programms:

```assembly
2010 0100  ; move A, #$100  (Zieladresse für die Zahlen laden)
0B00       ; sys #$300      (die 4 Werte anfordern, diese stehen dann in $100-$103)
....
2010 0100  ; move A, #$100  (Adresse mit den Ergebnissen laden)
0B01       ; sys #$301      (das Rechenergebnis muss zuvor in $100 und $101 gespeichert sein)
1C00       ; halt           (wichtig, sonst läuft das Programm unkontrolliert weiter)
```



### Aufgabe 2: PDP-13 BIOS ROM

Um das Tape für das PDP-13 BIOS ROM zu erhalten, musst du folgende Aufgabe lösen:

*Berechne den Abstand zwischen zwei Punkten im Raum, wobei der Abstand in Blöcken berechnet werden soll, also wie wenn eine Hyperloop-Strecke von pos1 zu pos2 gebaut werden müsste. Die Blöcke für pos1 und pos2 zählen mit. pos1 und pos2 bestehen aus x, y, z Koordinaten, wobei sich alle Werte im Bereich von 0 bis 1000 bewegen, Wenn man bspw. von (0,0,0) nach (1000,1000,1000) eine Strecke bauen müsste, würde man 3001 Blöcke benötigen.*

Das Programm muss zuerst die 6 Werte (x1, y1, z1, x2, y2, z2) über `sys #$302` anfordern und am Ende das Ergebnis wieder über `sys #$303` ausgeben. Wenn die Berechnung passt und im "Telewriter Operator" befindet sich ein leeres Tape, dann wird bei passendem Ergebnis das Tape geschrieben. In jedem Falle erfolgt eine Chat-Ausgabe über die berechneten Werte. Hier der Rahmen des Programms:

```assembly
move  A, #$100  ; Zieladresse laden
sys   #$302     ; die 6 Werte anfordern, diese stehen dann in $100-$105
....
sys   #$303     ; das Rechenergebnis muss zuvor in A gespeichert sein
halt            ; wichtig, sonst läuft das Programm unkontrolliert weiter
```



### Aufgabe 3: PDP-13 OS Install Tape

Um das OS Install Tape zu erhalten, musst du folgende Aufgabe lösen:

*Wandle die übergebenen Wert (0..65535) um in einen String mit der dezimalen Darstellung der Zahl (das was bspw. auch die Lua-Funktion `tostring()` macht).*

Das Programm muss zuerst den Wert über `sys #$304` anfordern und am Ende das Ergebnis wieder über `sys #$305` ausgeben. Wenn die Umwandlung passt und im "Telewriter Operator" befindet sich ein leeres Tape, dann wird bei passendem Ergebnis das Tape geschrieben. In jedem Falle erfolgt eine Chat-Ausgabe mit den Strings. Hier der Rahmen des Programms:

```assembly
sys   #$304     ; den Werte anfordern, dieser stehen dann in A
....
move  A, #$nnn  ; A mit der String-Adresse laden
sys   #$305     ; Ergebnis übergeben
halt            ; wichtig, sonst läuft das Programm unkontrolliert weiter
```
