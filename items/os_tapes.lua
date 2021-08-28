--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	Compile/copy all kind of asm files

]]--

pdp13.tape.register_tape("pdp13:tape_install", "J/OS Installation Tape",
[[; J/OS Installation Tape v1.0

; Write tape to RAM and start program at address 0
]], [[:20000010000019B
:800000008102010005D08142010006F08142010
:80008000070081416000043201005000805202D
:800100054100052201000DF08142030000F1600
:8001800004A2010009508141600004320100500
:800200008052030000254100052201000DF0814
:80028002030000F1600004A201000BA08141600
:800300000432010050008052030000354100052
:8003800201000DF08142030000F1600004A2010
:800400000ED08141C0020100500081700005410
:800480000431800080600000000000000007430
:8005000004A180020100102081320012030000A
:800580008122010006F08141C00004A002F004F
:8006000005300200049006E007300740061006C
:8006800006C002000760030002E003100000000
:80070000049006E007300650072007400200053
:80078000079007300740065006D002000540061
:8008000007000650020003100200061006E0064
:800880000200070007200650073007300200065
:8009000006E00740065007200000049006E0073
:800980000650072007400200053007900730074
:800A0000065006D002000540061007000650020
:800A800003200200061006E0064002000700072
:800B00000650073007300200065006E00740065
:800B800007200000049006E0073006500720074
:800C000002000530079007300740065006D0020
:800C80000540061007000650020003300200061
:800D000006E0064002000700072006500730073
:800D80000200065006E00740065007200000063
:800E000006F00700079002000660069006C0065
:800E8000073002E002E002E0000005200650061
:800F00000640079002E00200042006F006F0074
:800F80000200079006F007500720020004F0053
:8010000002E0000005400610070006500200065
:801080000720072006F007200200000201000C0
:8011000222000BE16000162222000BD201000C0
:80118002030002016000134222000BF18006820
:80120002E2000BF201100BF50120003200C6C20
:80128001800201100BE203100BD160001552220
:801300000BE200D6C20180068802080200C1600
:8013800014C5510014228001600014455100142
:8014000120001376C801800551001548C281200
:801480001542880120001445510015490281200
:80150000154214C1200014C1800688020803081
:8015800210C20805150015A5550015C2C802004
:80160006C80180068802080200C5550016A2800
:8016800120001656C801800688068A068402080
:801700020A12C40214B5530017774500172210C
:801780020026C40240234026CA06C8018006880
:801800068A0684020A12C402080160001623080
:801880034405850018F200C6C4012000199214B
:8019000553001947450018F210C20026C402402
:401980034026CA06C801800
:00000FF
]], true)
