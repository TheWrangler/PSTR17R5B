	set fp [open F:/PSTR17R5B/synplify/ise2syntmp/version.out w ]
	set par_msg  [open "|par" r]
	while {[gets $par_msg cur_line] >= 0} {
		if {[regexp -nocase {^Release (.*) - .*} $cur_line match ise_ver]} {
			puts $fp $ise_ver
		}
    }
	close $fp
