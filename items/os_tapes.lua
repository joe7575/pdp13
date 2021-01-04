--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Punch Tapes

]]--

pdp13.tape.register_tape("pdp13:tape_install", "System File 1: OS install",
[[; J/OS Install Tape v1.0
; Write tape to RAM and start
; program at address 0
]], [[:200000100000304
:8000000120001002010001E08141C00201000C0
:8000800203001EF20500040160002D5201000C0
:80010002030026820500040160002E816000277
:8001800201000C0087520EC1200010000520065
:5002000006100640079002E0000
:801000008102010018108142010019308142010
:801080001940814160001500803202D54100176
:8011000201001BE160001622010000A16000172
:8011800201001C3081416000150080320300002
:801200054100176201001EF160001622010000A
:801280016000172201001FA0814160001500803
:801300020300003541001762010022616000162
:80138002010000A160001722010023108141600
:80140000150080320300004541001762010025D
:8014800160001622010000A1600017212000006
:8015000201000C00817222000BD000054100150
:8015800280054100150201100C09010001A1200
:801600001501800203000770850203000145410
:801680001762040085420300015541001762002
:801700008511800000074100172180020100270
:8017800081320012030000A0812201001930814
:80180001C00004A002F004F005300200049006E
:8018800007300740061006C006C002000760030
:8019000002E0031000000000049006E00730065
:801980000720074002000530079007300740065
:801A000006D0020005400610070006500200027
:801A8000062006F006F0074002700200061006E
:801B00000640020007000720065007300730020
:801B8000065006E00740065007200000062006F
:801C000006F007400000049006E007300650072
:801C8000074002000530079007300740065006D
:801D00000200054006100700065002000270068
:801D800003100360063006F006D002700200061
:801E000006E0064002000700072006500730073
:801E80000200065006E00740065007200000068
:801F000003100360063006F006D002E00680031
:801F800003600000049006E0073006500720074
:8020000002000530079007300740065006D0020
:802080000540061007000650020002700730068
:80210000065006C006C0031002700200061006E
:802180000640020007000720065007300730020
:80220000065006E007400650072000000730068
:80228000065006C006C0031002E006800310036
:802300000000049006E00730065007200740020
:802380000530079007300740065006D00200054
:802400000610070006500200027007300680065
:8024800006C006C0032002700200061006E0064
:802500000200070007200650073007300200065
:8025800006E0074006500720000007300680065
:8026000006C006C0032002E0068003100360000
:80268000020007300680065006C006C00320000
:8027000004500720072006F0072002000002010
:802780000C0222000BE160002CB222000BD2010
:802800000C0203000201600029D222000BF1800
:802880068202E2000BF201100BF50120003200C
:80290006C201800201100BE203100BD160002BE
:8029800222000BE200D6C20180068802080200C
:802A000160002B5551002AB2800160002AD5510
:802A80002AB120002A06C801800551002BD8C28
:802B000120002BD2880120002AD551002BD9028
:802B800120002BD214C120002B5180068802080
:802C0003081210C2080515002C3555002C52C80
:802C80020046C80180068802080200C555002D3
:802D0002800120002CE6C801800688068A06840
:802D800208020A12C40214B553002E0745002DB
:802E000210C20026C40240234026CA06C801800
:802E800688068A0684020A12C402080160002CB
:802F00030803440585002F8200C6C4012000302
:802F800214B553002FD745002F8210C20026C40
:5030000240234026CA06C801800
:00000FF
]], true)


pdp13.tape.register_tape("pdp13:tape_boot", "System File 2: boot",
[[
]], [[t/shell1.h16
]], true)


pdp13.tape.register_tape("pdp13:tape_h16com", "System File 3: h16com",
[[; h16com v1.0
; .h16 to .com conversion tool
; File name: h16com.h16
]], [[:20000010100FF89
:20100001200FE80
:8FE80002010FEC20814201100BF2C005410FEB8
:8FE88001600FF20201100BE1600FF63301100BE
:8FE90002220FE7F201100BE2030FF0A20500040
:8FE98001600FF6D201100BE08775410FEBD2220
:8FEA000FE7E201100BE08752091FE7F210C2011
:8FEA80000BE2030FF05205000401600FF6D2011
:8FEB00000BE2031FE7E087A2010FEF508140871
:8FEB8002010FEDC08141200FEB72010FEE90814
:8FEC0001200FEB70063006F006D002D0074006F
:8FEC800002D00680031003600200063006F006E
:8FED00000760065007200740065007200200076
:8FED8000031002E003000000050006100720061
:8FEE000006D0020006500720072006F00720021
:8FEE800000000460069006C0065002000650072
:8FEF0000072006F00720021000000460069006C
:8FEF800006500200063006F006E007600650072
:8FF0000007400650064002E0000002E0063006F
:8FF0800006D0000002E00680031003600002010
:8FF100000C0222000BE1600FF63222000BD2010
:8FF180000C0203000201600FF35222000BF1800
:8FF200068202E2000BF201100BF50120003200C
:8FF28006C201800201100BE203100BD1600FF56
:8FF3000222000BE200D6C20180068802080200C
:8FF38001600FF4D5510FF4328001600FF455510
:8FF4000FF431200FF386C8018005510FF558C28
:8FF48001200FF5528801200FF455510FF559028
:8FF50001200FF55214C1200FF4D180068802080
:8FF58003081210C20805150FF5B5550FF5D2C80
:8FF600020046C80180068802080200C5550FF6B
:8FF680028001200FF666C801800688068A06840
:8FF700020A12C4020801600FF63308034405850
:8FF7800FF7D200C6C401200FF87214B5530FF82
:8FF80007450FF7D210C20026C40240234026CA0
:2FF88006C801800
:00000FF
]], true)


pdp13.tape.register_tape("pdp13:tape_shell1", "System File 4: shell1",
[[; J/OS Shell1 v1.0
; First part of the cmnd shell
; File name: shell1.h16
]], [[:2000001000000B8
:80000001200001212000027087620EC12000100
:4000C00201000C0087520EC
:80010001200010008102010003208142010004D
:8001800081408732030000A0812201000440813
:800200008722030000A08122010004908142010
:8002800004E08765410002E120001002010003D
:800300008141C004A2F4F532076302E3120436F
:80038006C6420426F6F007400004C6F61642065
:800400072726F7200210000204B2052414D2020
:80048000000204B20524F4D000000000074002F
:8005000007300680065006C006C0032002E0063
:8005800006F006D0000201000C0222000BE1600
:800600000AF222000BD201000C0203000201600
:80068000081222000BF180068202E2000BF2011
:800700000BF50120003200C6C201800201100BE
:8007800203100BD160000A2222000BE200D6C20
:8008000180068802080200C160000995510008F
:80088002800160000915510008F120000846C80
:80090001800551000A18C28120000A128801200
:80098000091551000A19028120000A1214C1200
:800A00000991800688020803081210C20805150
:800A80000A7555000A92C8020046C8018006880
:800B0002080200C555000B72800120000B26C80
:100B8001800
:00000FF
]], true)


pdp13.tape.register_tape("pdp13:tape_shell2", "System File 5: shell2",
[[; J/OS Shell2 v1.0
; Second part of the cmnd shell
; File name: shell2.com
]], [[:200000101000348
:8010000081A201000C00817222000BD00005410
:80108000101280054100101201100C034100020
:801100058100119222C00C0201000C008141200
:80118000100201000C0081416000274201000C0
:801200020300211160002E95010013416000285
:80128005012000420100214222000BE201100BE
:80130000857081812000100201000C020300216
:8013800160002E95010014D1600028554100207
:8014000201100BE202C08502060085220030851
:8014800201100BE081612000101201000C02030
:80150000219160002E950100158081012000100
:8015800201000C02030021D160002E950100177
:8016000201100BF901000031200020716000285
:8016800205100BE16000285203100BE2002085A
:80170005410020C201002430814120001002010
:801780000C020300220160002E9501001962011
:801800000BF9010000312000207160002852051
:801880000BE16000285203100BE200208595410
:8019000020C2010025E081412000100201000C0
:801980020300223160002E9501001B0201100BF
:801A000901000021200020716000285201100BE
:801A80008585410020C2010024E081412000100
:801B000201000C020300226160002E9501001C8
:801B800201100BF901000021200020716000285
:801C000209100BE2008085B5410020C12000100
:801C80020100F00203000C0205100BD28401600
:801D000031920100F002030026A2050000D1600
:801D800032C20100F000856541001EF20100F00
:801E0002030007208502020085C242008518C10
:801E8002001120001EF20100F00120000042010
:801F00000C02030026A160002F9900D120001FC
:801F800201000C012000004201000C02030026F
:8020000160002F9900D120002071200000C2010
:802080002290814120001002010023708141200
:80210000100006C00730000002A000000650064
:802180000000063006C00730000006D00760000
:80220000063007000000072006D000000630064
:8022800000000530079006E0074006100780020
:8023000006500720072006F0072002100000046
:80238000069006C00650020006500720072006F
:802400000720021000000460069006C00650020
:8024800006D006F007600650064000000460069
:8025000006C0065002800730029002000720065
:8025800006D006F007600650064000000460069
:8026000006C006500200063006F007000690065
:802680000640000002E0063006F006D0000002E
:80270000068003100360000201000C0222000BE
:8027800160002C8222000BD201000C020300020
:80280001600029A222000BF180068202E2000BF
:8028800201100BF50120003200C6C2018002011
:802900000BE203100BD160002BB222000BE200D
:80298006C20180068802080200C160002B25510
:802A00002A82800160002AA551002A81200029D
:802A8006C801800551002BA8C28120002BA2880
:802B000120002AA551002BA9028120002BA214C
:802B800120002B21800688020803081210C2080
:802C000515002C0555002C22C8020046C801800
:802C80068802080200C555002D02800120002CB
:802D0006C801800688020808D500020120002D4
:802D8002C802004914C120002DA2C802C809110
:802E0000020120002E7210C2C80120002DF6C80
:802E8001800688068A0208020A1551002F48D4B
:802F000120002ED2C802CA0200834096CA06C80
:802F8001800688068A0208020A1914C120002FD
:80300002C802C80916C120003022CA02CA09109
:8030800120003118C25120003152C802CA01200
:80310000307200C6CA06C801800200D6CA06C80
:80318001800688068A06840208020A12C40214B
:8032000553003247450031F210C20026C402402
:803280034026CA06C801800688068A0684020A1
:80330002C402080160002C8308034405850033C
:8033800200C6C4012000346214B553003417450
:8034000033C210C20026C40240234026CA06C80
:10348001800
:00000FF
]], true)
