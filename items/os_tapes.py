import os

Header = """--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Punch Tapes

]]--

"""

Templ = """pdp13.tape.register_tape("%s", "%s",
[[%s
]], [[%s
]], %s)
"""

def isolate_description(text):
    lOut = []
    for line in text.split("\n"):
        if ";----" in line.strip():
            return "\n".join(lOut)
        lOut.append(line)
    
def isolate_codeblock(text):
    lOut = []
    add = False
    for line in text.split("\n"):
        if add:
            lOut.append(line)
        elif ";##########" in line.strip():
            add = True
    return "\n".join(lOut)


def generate_h16(path, file_name, item_name, item_desc, hidden):
    asm_file = path + file_name + ".asm"
    h16_file = path + file_name + ".h16"
    lst_file = path + file_name + ".lst"
    os.system("vm16asm %s" % asm_file)
    desc = isolate_description(open(asm_file).read())
    if not desc:
        desc = isolate_codeblock(open(lst_file).read())
    h16 = open(h16_file).read()
    s = Templ % (item_name, item_desc, desc, h16, hidden)
    return s

################################################################################
## System Files
################################################################################
SystemFiles = [
    ("install",     "pdp13:tape_install",   "System File 1: OS install"),
    ("boot",        "pdp13:tape_boot",      "System File 2: boot"),
    ("shell1",      "pdp13:tape_shell1",    "System File 3: shell1"),
    ("shell2",      "pdp13:tape_shell2",    "System File 4: shell2"),
]

lOut = []
for file_name, item_name, item_desc in SystemFiles:
    lOut.append(generate_h16("../system/", file_name, item_name, item_desc, "false"))
open("os_tapes.lua", "w").write(Header + "\n\n".join(lOut))

################################################################################
## Demo Files
################################################################################
DemoFiles = [
    ("7segment",    "pdp13:tape_7seg",      "Demo: 7-Segment"),
    ("color_lamp",  "pdp13:tape_color",     "Demo: Color Lamp"),
    ("telewriter",  "pdp13:tape_tele",      "Demo: Telewriter Output"),
    ("inp_number",  "pdp13:tape_inp_num",   "Demo: Telewriter Input Number"),
    ("inp_string",  "pdp13:tape_inp_str",   "Demo: Telewriter Input String"),
    ("terminal",    "pdp13:tape_terminal",  "Demo: Terminal"),
    ("udp_send",    "pdp13:tape_udp_send",  "Demo: Comm Send"),
    ("udp_recv",    "pdp13:tape_udp_recv",  "Demo: Comm Receive"),
]

lOut = []
for file_name, item_name, item_desc in DemoFiles:
    lOut.append(generate_h16("../examples/", file_name, item_name, item_desc, "false"))
open("demo_tapes.lua", "w").write(Header + "\n\n".join(lOut))
