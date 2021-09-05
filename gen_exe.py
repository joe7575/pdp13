import os
import sys
import shutil

Header = """--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	Compile/copy all kind of asm files

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


def generate_file(path, file_type, file_name, item_name, item_desc, hidden):
    if file_type == "h16":
        asm_file = path + file_name + ".asm"
        dst_file = path + file_name + ".h16"
        lst_file = path + file_name + ".lst"
        if os.system("vm16asm %s --lst" % asm_file) != 0:
            sys.exit(0)
    elif file_type == "com":
        asm_file = path + file_name + ".asm"
        dst_file = path + file_name + ".com"
        lst_file = path + file_name + ".lst"
        if os.system("vm16asm %s --com --lst" % asm_file) != 0:
            sys.exit(0)
    elif file_type == "":
        asm_file = path + file_name
        dst_file = path + file_name
        lst_file = path + file_name
        
    desc = isolate_description(open(asm_file).read())
    if not desc:
        desc = isolate_codeblock(open(lst_file).read()) or ""
    txt = open(dst_file).read()
    
    s = Templ % (item_name, item_desc, desc, txt, hidden)
    return s

def compile_file(path, file_type, file_name):
    if file_type == "h16":
        asm_file = path + file_name + ".asm"
        dst_file = path + file_name + ".h16"
        lst_file = path + file_name + ".lst"
        if os.system("vm16asm %s --lst" % asm_file) != 0:
            sys.exit(0)
    elif file_type == "com":
        asm_file = path + file_name + ".asm"
        dst_file = path + file_name + ".com"
        lst_file = path + file_name + ".lst"
        if os.system("vm16asm %s --com --lst" % asm_file) != 0:
            sys.exit(0)

def copy_file(src_path, dst_path, file_type, file_name, uid):
    print("copy " + file_name + "." + file_type)
    if file_type == "":
        src_file = src_path + file_name
        dst_file = dst_path + uid + "_" + file_name
        shutil.copy(src_file, dst_file)
    elif file_type == "com":
        asm_file = src_path + file_name + ".asm"
        src_file = src_path + file_name + ".com"
        dst_file = dst_path + uid + "_" + file_name + ".com"
        if os.system("vm16asm %s --com --lst" % asm_file) != 0:
            sys.exit(0)
        shutil.copy(src_file, dst_file)
    elif file_type == "h16":
        asm_file = src_path + file_name + ".asm"
        src_file = src_path + file_name + ".h16"
        dst_file = dst_path + uid + "_" + file_name + ".h16"
        if os.system("vm16asm %s --lst" % asm_file) != 0:
            sys.exit(0)
        shutil.copy(src_file, dst_file)
    else:
        src_file = src_path + file_name + "." + file_type
        dst_file = dst_path + uid + "_" + file_name + "." + file_type
        shutil.copy(src_file, dst_file)

################################################################################
## Files for os_tapes.lua
################################################################################
OsFiles = [
    ("h16", "install",   "pdp13:tape_install",   "J/OS Installation Tape"),
]

lOut = []
for file_type, file_name, item_name, item_desc in OsFiles:
    lOut.append(generate_file("./system/", file_type, file_name, item_name, item_desc, "true"))
open("./items/os_tapes.lua", "w").write(Header + "\n\n".join(lOut))

################################################################################
## System files to be build
################################################################################
SystemFiles = [
    ("",    "boot"),
    ("h16", "h16com"),
    ("h16", "shell1"),
    ("com", "shell2"),
    ("com", "cat"),
    ("com", "ptrd"),
    ("com", "ptwr"),
    ("com", "asm"),
    ("com", "disk"),
    ("com", "format"),
]

for file_type, file_name in SystemFiles:
    compile_file("./system/", file_type, file_name)

################################################################################
## Demo files for demo_tapes.lua
################################################################################
DemoFiles = [
    ("h16", "7segment",    "pdp13:tape_7seg",      "Demo: 7-Segment"),
    ("h16", "color_lamp",  "pdp13:tape_color",     "Demo: Color Lamp"),
    ("h16", "telewriter",  "pdp13:tape_tele",      "Demo: Telewriter Output"),
    ("h16", "inp_number",  "pdp13:tape_inp_num",   "Demo: Telewriter Input Number"),
    ("h16", "inp_string",  "pdp13:tape_inp_str",   "Demo: Telewriter Input String"),
    ("h16", "terminal",    "pdp13:tape_terminal",  "Demo: Terminal"),
    ("h16", "signaltower", "pdp13:tape_signaltower", "Demo: Signal Tower"),
]

lOut = []
for file_type, file_name, item_name, item_desc in DemoFiles:
    lOut.append(generate_file("./examples/", file_type, file_name, item_name, item_desc, "false"))
open("./items/demo_tapes.lua", "w").write(Header + "\n\n".join(lOut))

################################################################################
## System files to copy to files system for testing
################################################################################
CopyFiles = [
    ("",    "boot",),
    ("",    "help.txt",),
    ("h16", "shell1"),
    ("com", "shell2"),
    ("h16", "h16com"),
    ("com", "asm"),
    ("com", "cat"),
]

lOut = []
for file_type, file_name in CopyFiles:
    #copy_file("./system/", "../../worlds/pdp13_test/pdp13/", file_type, file_name, "00000004")
    pass

################################################################################
## ASM files to copy to world files system for testing
################################################################################
CopyFiles = [
    ("asm", "hellow"),
    ("asm", "h16com"),
    ("asm", "shell1"),
    ("asm", "shell2"),
    ("asm", "cat"),
    ("asm", "ptrd"),
    ("asm", "ptwr"),
    ("asm", "asm"),
    ("asm", "disk"),
    ("asm", "format"),
]

lOut = []
for file_type, file_name in CopyFiles:
    #copy_file("./system/", "../../worlds/pdp13_test/pdp13/", file_type, file_name, "00000004")
    pass


################################################################################
## ASM files to copy to test/asm/pdp13 for Lua ASM testing
################################################################################
CopyFiles = [
    ("asm", "asm"),
    ("asm", "cat"),
    ("asm", "cmdstr"),
    ("asm", "h16com"),
    ("asm", "hellow"),
    ("asm", "less"),
    ("asm", "nextstr"),
    ("asm", "shell1"),
    ("asm", "shell2"),
    ("asm", "strcat"),
    ("asm", "strcmp"),
    ("asm", "strcpy"),
    ("asm", "strlen"),
    ("asm", "strrstr"),
    ("asm", "strsplit"),
    ("asm", "strstrip"),
    ("asm", "ptrd"),
    ("asm", "ptwr"),
    ("asm", "cpyfiles"),
    ("asm", "disk"),
    ("asm", "format"),
]

lOut = []
for file_type, file_name in CopyFiles:
    #copy_file("./system/", "./test/asm/pdp13/", file_type, file_name, "00000004")
    compile_file("./system/", "h16", file_name)
    pass

################################################################################
## ASM files as Templates for the Exams
################################################################################
CopyFiles = [
    ("asm", "exam1_fahrenheit"),
    ("asm", "exam2_addition"),
    ("asm", "exam3_distance"),
    ("asm", "exam4_tostring"),
    ("asm", "exam5_collatz"),
]

lOut = []
for file_type, file_name in CopyFiles:
    compile_file("./examples/", "h16", file_name)
    pass
