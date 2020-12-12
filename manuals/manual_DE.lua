techage.add_to_manual('DE', {
  "1,PDP13 Minicomputer (TA3)",
  "2,Anleitung",
  "2,I/O Rack",
  "2,PDP-13 CPU",
  "3,Performance",
  "2,PDP-13 Telewriter",
  "2,PDP13 Tape",
  "2,PDP13 7-Segment",
  "2,PDP13 Color Lamp",
  "2,Minimal Beipiel",
}, {
  "PDP13 ist ein 16-Bit-Minicomputer\\, inspiriert von DEC\\, IBM und anderen Computer aus den 60er und 70er Jahren. \"Mini\" deshalb\\, weil die Rechnenanlagen bis dahin nicht nur Schränke\\, sondern ganze Räume oder Hallen gefüllt hatten. Erst mit der Erfindung der ersten integrierten Schaltkreisen ließen sich die Rechner auf Kleiderschrankgröße reduzieren. Damit passt dieser Computer ideal in das Ölzeitalter. Dadurch dass dieser Computer nur in Maschinencode programmiert werden kann (wie die Originale damals auch)\\, setzt dies einiges an Computerwissen voraus\\, was nicht in dieser Anleitung vermittelt werden kann.\n"..
  "\n"..
  "Voraussetzungen sind damit:\n"..
  "\n"..
  "  - Grundkenntnisse in Englisch (weitere Dokumente nur in englisch)\n"..
  "  - Rechnen mit HEX-Zahlen (16 Bit System)\n"..
  "  - Grundkenntnisse im Aufbau einer CPU (Register\\, Speicheraddressierung) und Assemblerprogrammierung\n"..
  "  - Ausdauer und Lernbereitschaft\\, denn PDP13 ist anders\\, als alles\\, was du evtl. schon kennst\n"..
  "\n"..
  "Der PDP13 Minicomputer wird aber im Spiel auch nicht benötigt\\, sondern dient eher als Lehrmaterial in Computergrundlagen und Computergeschichte. Er kann aber wie die anderen Controller zur Steuerung von Maschinen eingesetzt werden. Die PDP13 Mod bringt auch eigene Ausgabeblöcke mit\\, so dass sich viele Möglichkeiten zur Anwendung bieten.\n"..
  "\n"..
  "Aufgrund der Länge empfiehlt sich\\, diese Anleitung direkt auf GitHub zu lesen. Über den Link 'github.com/joe7575/pdp13/wiki' kommt ihr direkt zu der Seite mit Anleitungen und weiteren Links.\n"..
  "\n"..
  "\n"..
  "\n",
  "  - Crafte die 3 Blöcke \"PDP-13 Power Module\"\\, \"PDP-13 CPU\" und \"PDP-13 I/O Rack\".\n"..
  "  - Das Rack gibt es in 2 Varianten\\, die sich aber nur vom Frontdesign unterschieden\n"..
  "  - Setzte den CPU Block auf den Power Block und das I/O-Rack direkt neben den Power Block\n"..
  "  - Diese Reihenfolge muss eingehalten werden\\, sonst können sich die I/O-Racks nicht mit der CPU verbinden. Der maximale Abstand zwischen einem Erweiterungsblock und der CPU beträgt 2 Blöcke\n"..
  "  - Über den Power Block wird die CPU und die weiteren Blöcke eingeschaltet\n"..
  "  - Das I/O-Rack kann nur konfiguriert werden\\, wenn der Power Block ausgeschaltet ist\n"..
  "  - Die CPU kann nur programmiert werden\\, wenn der Power Block eingeschaltet ist (logisch)\n"..
  "\n"..
  "\n"..
  "\n",
  "Das I/O-Rack verbindet die CPU mit der Welt\\, also anderen Blöcken und Maschinen. Es können mehrere I/O-Blöcke pro CPU genutzt werden\n"..
  "\n"..
  "  - Das erste I/O-Rack belegt die I/O-Adressen #0 bis #7. Diesen Adressen können über das Menü des I/O-Racks Blocknummern zugeordnet werden\n"..
  "  - Kommandow\\, welche an Adresse #0 bis #7 ausgegeben werden\\, werden dann vom I/O-Rack an den entsprechenden Block weitergegeben\n"..
  "  - Kommandos\\, die an die CPU bzw. an die Nummer der CPU gesendet werden (bspw. von einem Schalter) können so wieder eingelesen werden\n"..
  "  - Das Description Feld ist optional und muss nicht beschrieben werden\n"..
  "  - Das \"OUT\" Feld zeigt den zuletzt ausgegebenen Wert/das zuletzt ausgegebene Kommando\n"..
  "  - Das \"IN\" Feld zeigt entweder das empfangene Kommando oder die Antwort auf ein gesendetes Kommando. Wird 65535 ausgegeben\\, wurde kein Antwort empfangen (viele Blöcke senden keine Anwort auf ein \"on\"/\"off\" Kommando)\n"..
  "  - Das \"help\" Register zeigt eine Tabelle mit Informationen zur Umsetzung von Ein/Ausgabe Werten der CPU zu Techage Kommandos\n"..
  "\n"..
  "\n"..
  "\n",
  "Der CPU Block ist der Rechenkern der Anlage. Der Block besitzt ein Menü\\, das echten Minicomputern nachempfunden ist. Über die Schalterreihe mussten bei echten Rechnern die Maschinenbefehle eingegeben werden\\, über die Lampenreihen wurden Speicherinhalte ausgegeben.\n"..
  "\n"..
  "Hier werden Kommandos aber über die 6 Tasten links und Maschinenbefehle über das Eingabefeld unten eingegeben. Der obere Bereich dient nur zur Ausgabe.\n"..
  "\n"..
  "  - Über die Taste \"start\" wird die CPU gestartet. Sie startet dabei immer an der aktuellen Adresse des Program Counters (PC)\\, welche bspw. auch oben über die Lampenreihe angezeigt wird.\n"..
  "  - Über die Taste \"stop\" wird eine gestartete CPU wieder gestoppt. Ob die CPU gestartet oder gestoppt ist\\, sieht man bspw. oben an der \"run\" Lampe.\n"..
  "  - Über die Taste \"reset\" wird der Program Counter auf Null gesetzt (CPU muss dazu gestoppt sein)\n"..
  "  - Über die Taste \"step\" führt die CPU genau einen Befehl aus. Im Ausgabefeld sieht man dann die Registerwerte\\, den ausgeführten Maschinencode sowie den Maschinencode\\, der mit dem nächsten \"step\" ausgeführt wird.\n"..
  "  - Über die Taste \"address\" kann der Program Counter auf einen Wert gesetzt werden.\n"..
  "  - Über die Taste \"dump\" wird ein Speicherbereich ausgegeben. Die Startadresse muss zuvor über die Taste \"address\" eingegeben worden sein.\n"..
  "\n"..
  "Das \"help\" Register zeigt die wichtgsten Assemblerbefehle und jeweils den Maschinencode dazu. Mit diesem Subset an Befehlen kann man bereits arbeiten. Weitere Informationen zum Befehlssatz findest du  und .\n"..
  "\n"..
  "Am Ende der Tabelle werden die System Kommandos aufgeführt. Dies sind quasi Betriebssystemsaufrufe\\, welche zusätzliche Befehle ausführen\\, die sonst nicht möglich wären\\, wie bspw. einen Text auf dem Telewriter ausgeben. \n"..
  "\n",
  "Die CPU ist in der Lage\\, bis zu 100.000 Befehle pro Sekunde (0.1 MIPS) auszuführen. Dies gilt\\, solange nur interne CPU-Befehle ausgeführt werden. Dabei gibt es folgende Ausnahmen:\n"..
  "\n"..
  "  - Der 'sys' und der 'in' Befehl \"kosten\" pauschal 1000 Zyklen\\, da hier externer Code ausgeführt wird.\n"..
  "  - Der 'out' Befehl unterbricht die Ausführung für 100 ms\\, sofern sich der Wert am Ausgang ändert und eine externe Aktionen in der Spielewelt durchgeführt werden muss. Anderenfalls sind es auch nur die 1000 Zyklen.\n"..
  "  - Der 'nop' Befehl\\, der für Pausen genutzt werden kann\\, unterbricht die Ausführung auch für 100 ms.\n"..
  "\n"..
  "Ansonsten läuft die CPU \"full speed\"\\, aber nur solange der Bereich der Welt geladen ist. Damit ist die CPU fast so schnell wie ihr großen Vorbild\\, die DEC PDP-11/70 (0.4 MIPS). \n"..
  "\n"..
  "TODO:\n"..
  "\n"..
  "  - Speichererweiterungenüber ein Memory-Rack.\n"..
  "  - ROM Erweiterung über den ROM Block und ROM Chips\\, bspw. das Monitor-ROM mit asm/disasm\n"..
  "\n"..
  "\n"..
  "\n",
  "Der Telewriter war das Terminal an einem Minicomputer. Ausgaben erfolgten nur auf Papier\\, Eingaben über die Tastatur. Eingegebene Zeichen konnten an den Rechner gesendet\\, oder auch auf ein Band (tape) geschrieben werden. Dabei wurden Löcher in das Tape gestanzt. Diese Tapes konnten dann wieder eingelegt und abgespielt werden\\, so dass gespeicherte Programme wieder an den Computer übertragen werden konnten.\n"..
  "\n"..
  "Auch hier dient  das Terminal zur Ein-/Ausgabe und zum Schreiben und Lesen von Tapes. \n"..
  "\n"..
  "Es gibt bereits mehrere Demo Tapes\\, die über das \"tape\" Menü-Register in den Telewriter eingelegt und über die Schalter an die PDP13 CPU gesendet werden können. Die CPU muss dazu aber eingeschaltet (power) und gestoppt sein. Ob die Übertragung geklappt hat\\, wird auf Papier ausgegeben (\"main\" Menü-Register). \n"..
  "\n"..
  "Eigene Programme können so auch auf Tape gespeichert und später wieder wieder eingelesen und abgearbeitet werden. \n"..
  "\n"..
  "\n"..
  "\n",
  "Neben den Demo Tapes mit festen\\, kleinen Programmen gibt es ach die beschreibbaren und editierbaren Tapes. Diese können (im Gegensatz zum Original) mehrfach geschrieben/geändert werden.\n"..
  "\n"..
  "Die Tapes besitzen ein Menü so dass diese uch von Hand beschrieben werden können. Dies dient dazu:\n"..
  "\n"..
  "  - dem Tape einen eindeutigen Namen zu geben\n"..
  "  - zu beschreiben\\, wie das Programm genutzt werden kann (Description)\n"..
  "  - direkt ein H16 File in das Code-Fenster zu kopieren\\, welches bspw. am eigenen PC erstellt wurde (vm16asm).\n"..
  "\n"..
  "\n"..
  "\n",
  "Über diesen Block kann eine HEX-Ziffer\\, also 0-9 und A-F ausgegeben werden\\, indem Werte von 0 bis 15 über das Kommando 'value' an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Werte größer 15 löschen die Ausgabe.\n"..
  "\n"..
  "Lua: '$send_cmnd(num\\, \"value\"\\, 0..16)'\n"..
  "\n"..
  "Asm:\n"..
  "\n"..
  "    move A\\, #$80    \\; 'value' command\n"..
  "    move B\\, #8      \\; value 0..16 in B\n"..
  "    out #00\\, A      \\; output on port #0\n"..
  "\n"..
  "\n"..
  "\n",
  "Dieser Lampenblock kann in verschiedenen Farben leuchten. Dazu müssen Werte von 1-64 über das Kommando 'value'an den Block gesendet werden. Der Block muss dazu über ein I/O-Rack mit der CPU verbunden sein. Der Werte 0 schaltet die Lampe aus.\n"..
  "\n"..
  "Lua: '$send_cmnd(num\\, \"value\"\\, 0..64)'\n"..
  "\n"..
  "Asm:\n"..
  "\n"..
  "    move A\\, #$80    \\; 'value' command\n"..
  "    move B\\, #8      \\; value 0..64 in B\n"..
  "    out #00\\, A      \\; output on port #0\n"..
  "\n"..
  "\n"..
  "\n",
  "Hier ein konkretes Beispiel\\, das den Umgang mit der Mod zeigt. Ziel ist es\\, die TechAge Signallampe (nicht die PDP13 Color Lamp!) einzuschalten. Dazu muss man den Wert 1 über ein 'out' Befehl an dem Port ausgeben\\, wo die Lampe \"angeschlossen\" ist. Das Assembler-Programm dazu sieht aus wie folgt:\n"..
  "\n"..
  "    mov A\\, #1   \\; Lade das A-Register mit den Wert 1\n"..
  "    out #0\\, A   \\; Gebe den Wert aus dem A-Register auf I/O-Adresse 0 aus\n"..
  "    halt        \\; Stoppe die CPU nach der Ausgabe\n"..
  "\n"..
  "Da der Rechner diese Asemblerbefehle nicht direkt versteht\\, muss das Programm in Maschinencode übersetzt werden. Dazu dient die Hilfeseite im Menü des CPU-Blocks. Das Ergebnis sieht dann so aus:\n"..
  "\n"..
  "    2010 0001\n"..
  "    6600 0000\n"..
  "    1C00\n"..
  "\n"..
  "Diese Maschinenbefehle müssen bei der CPU eingegeben werden\\, wobei für '0000' auch nur '0' eingegeben werden darf (führende Nullen sind nicht relevant).\n"..
  "\n"..
  "Dazu sind die folgenden Schritte notwendig:\n"..
  "\n"..
  "  - Rechner mit Power\\, CPU\\, und IO-Rack aufbauen wie oben beschrieben\n"..
  "  - 7-Segement Bock in die Nähe setzen und die Nummer des Blockes im Menü des I/O-Racks in der obersten Zeile bei Adresse #0 eingeben\n"..
  "  - Den Rechner am Power Block einschalten\n"..
  "  - Die CPU gegebenenfalls stoppen und mit \"reset\" auf die Adresse 0 setzen\n"..
  "  - Den 1. Befehl eingeben und mit \"enter\" bestätigen: '2010 1'\n"..
  "  - Den 2. Befehl eingeben und mit \"enter\" bestätigen: '6600 0'\n"..
  "  - Den 3. Befehl eingeben und mit \"enter\" bestätigen: '1C00'\n"..
  "  - Die Tasten \"reset\" und \"dump\" drücken und die Eingaben überprüfen\n"..
  "  - Nochmals die Taste \"reset\" und dann die Taste \"start\" drücken\n"..
  "\n"..
  "Wenn du alles richtig gemacht hast\\, leuchtet danach die Lampe. Das \"OUT\" Feld im Menü des I/O-Racks zeigt die ausgegebene 1\\, das \"IN\" Feld zeigt eine 65535\\, da von der Lampe keine Antwort gesendet wird.\n"..
  "\n"..
  "\n"..
  "\n",
}, {
  "pdp13_cpu",
  "pdp13_cpu",
  "pdp13_iorack",
  "",
  "pdp13_cpu",
  "pdp13_telewriter",
  "pdp13_tape",
  "pdp13_7segment",
  "pdp13_lamp",
  "pdp13_cpu",
}, {
  "",
  "",
  "",
  "",
  "",
  "",
  "",
  "",
  "",
  "",
})
