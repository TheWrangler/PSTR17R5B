# Open ISE project
project open F:/PSTR17R5B/PSTR17R5B.xise -wd F:/PSTR17R5B
# Open output file to dump project options
set fp [open F:/PSTR17R5B/synplify/ise2syntmp/ise_options.out w ]
	# Get the processes that are applicable for this project
	set processes [project get_processes -instance top]
		# Get synthesis options
	if { [string first "synthesize - xst" [string tolower $processes]] != -1 } {
		set family [project get family -process "Synthesize - XST" -instance top]
		puts $fp family=$family
		set device [project get device -process "Synthesize - XST" -instance top]
		puts $fp device=$device
		set package [project get package -process "Synthesize - XST" -instance top]
		puts $fp package=$package
		set speed [project get speed -process "Synthesize - XST" -instance top]
		puts $fp speed=$speed
		set top____level__source__type [project get "top-level source type" -process "Synthesize - XST" -instance top]
		puts $fp top____level__source__type=$top____level__source__type
		set top [project get top -process "Synthesize - XST" -instance top]
		puts $fp top=$top
		set verilog__2001 [project get "verilog 2001"]
		puts $fp verilog__2001=$verilog__2001
		set generics [project get generics -process "Synthesize - XST" -instance top]
		puts $fp generics=$generics
		set verilog__macros [project get "verilog macros" -process "Synthesize - XST" -instance top]
		puts $fp verilog__macros=$verilog__macros
		set verilog__include__directories [project get "verilog include directories" -process "Synthesize - XST" -instance top]
		puts $fp verilog__include__directories=$verilog__include__directories
		set preferred__language [project get "preferred language" -process "Synthesize - XST" -instance top]
		puts $fp preferred__language=$preferred__language
		set register__balancing [project get "register balancing" -process "Synthesize - XST" -instance top]
		puts $fp register__balancing=$register__balancing
		set lut__combining [project get "lut combining" -process "Synthesize - XST" -instance top]
		puts $fp lut__combining=$lut__combining
		set max__fanout [project get "max fanout" -process "Synthesize - XST" -instance top]
		puts $fp max__fanout=$max__fanout
		set resource__sharing [project get "resource sharing" -process "Synthesize - XST" -instance top]
		puts $fp resource__sharing=$resource__sharing
		set netlist__hierarchy [project get "netlist hierarchy" -process "Synthesize - XST" -instance top]
		puts $fp netlist__hierarchy=$netlist__hierarchy
		set bus__delimiter [project get "bus delimiter" -process "Synthesize - XST" -instance top]
		puts $fp bus__delimiter=$bus__delimiter
		set dsp__utilization__ratio [project get "dsp utilization ratio" -process "Synthesize - XST" -instance top]
		puts $fp dsp__utilization__ratio=$dsp__utilization__ratio
		set bram__utilization__ratio [project get "bram utilization ratio" -process "Synthesize - XST" -instance top]
		puts $fp bram__utilization__ratio=$bram__utilization__ratio
		set safe__implementation [project get "safe implementation" -process "Synthesize - XST" -instance top]
		puts $fp safe__implementation=$safe__implementation
		set fsm__encoding__algorithm [project get "fsm encoding algorithm" -process "Synthesize - XST" -instance top]
		puts $fp fsm__encoding__algorithm=$fsm__encoding__algorithm
		set ram__style [project get "ram style" -process "Synthesize - XST" -instance top]
		puts $fp ram__style=$ram__style
		set rom__style [project get "rom style" -process "Synthesize - XST" -instance top]
		puts $fp rom__style=$rom__style
		set use__dsp__block [project get "use dsp block" -process "Synthesize - XST" -instance top]
		puts $fp use__dsp__block=$use__dsp__block
		set add__i___o__buffers [project get "add i/o buffers" -process "Synthesize - XST" -instance top]
		puts $fp add__i___o__buffers=$add__i___o__buffers
		set pack__i___o__registers__into__iob [project get "pack i/o registers into iob" -process "Synthesize - XST" -instance top]
		puts $fp pack__i___o__registers__into__iob=$pack__i___o__registers__into__iob
		set number__of__clock__buffers [project get "number of clock buffers" -process "Synthesize - XST" -instance top]
		puts $fp number__of__clock__buffers=$number__of__clock__buffers
		set register__duplication [project get "register duplication" -process "Synthesize - XST" -instance top]
		puts $fp register__duplication=$register__duplication
	} else {
		puts stderr "Top module of the project not synthesizable"
		exit 1
	}
	# Get design implementation options
	puts $fp "#Design Implementation Options"
	puts $fp "#Map Options"
	if { [string first "map" [string tolower $processes]] != -1 } {
		set properties [project properties -process "Map" -instance top]
		set property_list [split $properties "{}"]
		foreach property $property_list {
			set property [string trim $property]
			set length [string length $property]
			if {$length != 0} {
				set property_value [project get "$property" -process "Map" -instance top]
				puts $fp $property=$property_value
			}
		}
	}
	puts $fp "#Translate Options"
	if { [string first "translate" [string tolower $processes]] != -1 } {
		set properties [project properties -process "Translate" -instance top]
		set property_list [split $properties "{}"]
		foreach property $property_list {
			set property [string trim $property]
			set length [string length $property]
			if {$length != 0} {
				set property_value [project get "$property" -process "Translate" -instance top]
				puts $fp $property=$property_value
			}
		}
	}
	puts $fp "#Place & Route Options"
	if { [string first "place & route" [string tolower $processes]] != -1 } {
		set properties [project properties -process "Place & Route" -instance top]
		set property_list [split $properties "{}"]
		foreach property $property_list {
			set property [string trim $property]
			set length [string length $property]
			if {$length != 0} {
				set property_value [project get "$property" -process "Place & Route" -instance top]
				puts $fp $property=$property_value
			}
		}
	}

close $fp
project close
