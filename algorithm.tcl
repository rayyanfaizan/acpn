Class Pan_Sim
Class Pan_node

#==================================

Pan_Sim instproc init {} {
	global rng
   $self instvar nd_c  nd_list
   set nd_c 0
   set rng [new RNG]
   set nd_list [list]
}


Pan_Sim instproc Node {} {
   	$self instvar nd_c  nd_list
   	set nn [new Pan_node $nd_c]
   	lappend nd_list $nd_c 
  	incr nd_c  
	return $nn
}


Pan_Sim instproc Send_info {cov p} {
	global node_ ns_ rng nd_ PS  RTA 
   	$self instvar nd_c  nd_list
   	set src [lindex $p 0]
   	set dst [lindex $p 1]
   	set typ [lindex $p 2]
   	set frw [lindex $p 3]
   	set nxt [lindex $p 4]
	$node_($frw) log-movement
	set xf [$node_($frw) set X_]
	set yf [$node_($frw) set Y_]
    #we assume that the packet wont be loss due the collusion and random delay to reach the receiver
	set clr 0
	if {$nxt == -1} {
		$ns_ advertise_ $frw $typ $cov $clr
		foreach nx $nd_list {
			if {$nx !=$RTA} {
				$node_($nx) log-movement
				set xn [$node_($nx) set X_]
				set yn [$node_($nx) set Y_]
				set dist [expr sqrt(pow($xf-$xn,2)+pow($yf-$yn,2))]
				set rcov [$nd_($nx) set cov] 
				set fcov [expr ($rcov>$cov)?"$rcov":"$cov"]
				if {$dist<=$fcov && $src != $nx && $frw !=$nx} {
					$ns_ at [expr [$ns_ now]+[$rng uniform 0.0085 0.010]] "$nd_($nx) recv \"$p\""
				}
			}
		}
	} else {
			$node_($nxt) log-movement
			set xn [$node_($nxt) set X_]
			set yn [$node_($nxt) set Y_]
			set dist [expr sqrt(pow($xf-$xn,2)+pow($yf-$yn,2))]
			set rcov [$nd_($nxt) set cov] 
			set fcov [expr ($rcov>$cov)?"$rcov":"$cov"]
			if {$dist<=$fcov} {

				$ns_ at [expr [$ns_ now]+[$rng uniform 0.0085 0.010]] "$nd_($nxt) recv \"$p\""
				$ns_ commun_trace $frw $nxt $typ
			}
	}
}

#===================================

Pan_node instproc init {n} {
    $self instvar nd_id ran orc  activ cov Ngl_ Rq_idl_ rqid rpid nd_typ  RSU_id Rrqid Did_ Waitt RRq_idl_ AID Tlist PList OFFline rrsu Rrpid
    set nd_id 		$n
puts $n
    set ran 		[new RNG]
	set cov			300
	set rqid        0
	set rpid 		0
	set activ 		1
    set nd_typ      0
	set RSU_id      x
	set  Rrqid		0
	set Did_		0
set Rrpid 0
	set Waitt		0
	set rrsu		x
	set Tlist 		[list]
	set PList		[list]
    set mess 		[expr int([$ran uniform 2 9])]
	set OFFline		[list]
	set AID 		$mess
	set orc 		black
}
Pan_node instproc set-RTA {} {
	global RTA
    $self instvar nd_id ran orc  activ cov Ngl_ Rq_idl_ rqid rpid nd_typ 
	set nd_typ      2
	set RTA $nd_id
	set cov 10000
}

Pan_node instproc set-RSU {} {
	global ns_ RTA
    $self instvar nd_id ran orc  activ cov Ngl_ Rq_idl_ rqid rpid nd_typ 
	set nd_typ      1
	set cov			500
	set  Ngl_($RTA) $RTA
    $self send_adv 
}
Pan_node instproc send_adv  {} {
	global ns_ PS
    $self instvar nd_id ran orc  activ cov Ngl_ Rq_idl_ rqid rpid nd_typ  RSU_id PList
   set pkt "$nd_id -1 Adv $nd_id -1 0 \{$PList\}"

   $PS  Send_info $cov "$pkt"
   $ns_ at [expr [$ns_ now]+0.02] "$self send_adv"
}


Pan_node instproc recv {p} {
	global GS ns_ node_ PS  RTA
    $self instvar nd_id ran orc Neigh_ activ  cov Ngl_ Rq_idl_  rpid  RSU_id RRq_idl_ Tlist PList AID VAID_  PLP OFFline rrsu Rrpid

   	set src [lindex $p 0]
   	set dst [lindex $p 1]
   	set typ [lindex $p 2]
   	set frw [lindex $p 3]
   	set nxt [lindex $p 4]
    set pid_ [lindex $p 5]

	$node_($nd_id) color green
	$ns_ at [expr [$ns_ now]+0.001] "$node_($nd_id) color $orc"
    $node_($nd_id) label "$typ-$frw"
    if {$typ =="req"} {
        if {[info exist  Rq_idl_($src)] && $Rq_idl_($src) >= $pid_} { return }
		set Rq_idl_($src) $pid_
        set Ngl_($src)  $frw
        set mes [lindex $p 8]
		if {$dst==$nd_id} {
    		set RSi [lindex $p 6]
			set gf [open RSU_server/$RSi r]
			if {[info exist VAID_($mes)]  && $VAID_($mes) != $src } {
  				set pkt "$nd_id $src Rrej $nd_id $frw 0 $mes"
   				$PS  Send_info $cov "$pkt"
			}
			set idd 1
            while {![eof $gf]} {
				gets $gf mnm
				if {[lindex $mnm 0]== $src} {
				  set idd 0
			      set ky [lindex $mnm 1] 
                  set ems [lindex $p 7]
                  set dms [expr int(pow($ems,$ky))%33]

				  if {$mes ==$dms} { 
                     break 
                  } else {
                     return
                  }
				}
			}
			close $gf
			if {$idd == 1} {return}
			incr rpid
  			set pkt "$nd_id $src rep $nd_id $frw $rpid $ky $mes"
   			$PS  Send_info $cov "$pkt"
		} else {
			set fb [lsearch $Tlist $mes]
			if {$fb==-1} {
    			$node_($nd_id) label "$typ-$frw-a($mes)"
				lappend Tlist $mes
				$self forward "$p"
			} else {
  				set pkt "$nd_id $src rej $nd_id $frw 0 $mes"
   				$PS  Send_info $cov "$pkt"
			}
		}
    } elseif {$typ =="rep"} {
		set ky 	[lindex $p 6]
		set aid [lindex $p 7]
		if {$dst!=$nd_id} {
			if {[info exist PLP($aid)]} {
				set PList [lreplace $PList $PLP($aid) $PLP($aid)]
			} 
			set PLP($aid) [llength  $PList]
			lappend PList "$aid $ky"
        	set Ngl_($src)  $frw
			$self forward "$p"
 		} else {
        	set Ngl_($src)  $frw
			set rrsu  $frw
		}
	}  elseif {$typ =="Adv"} {
		if {$RSU_id == "x"} {
			set RSU_id $src
			$self send_req $RTA
		} elseif {$RSU_id != $src } {
			set od [tr_range $nd_id $RSU_id]
			set nd [tr_range $nd_id $src]

			if {$od>$nd} {
				set RSU_id 		$src
    			set mess 		[$self Gen_AID]
				set AID 		$mess
				$self send_req 	$RTA 
			}

		} elseif {$RSU_id == $rrsu} {
			set plst [lindex $p 6]
			$ns_ tr-annim "$nd_id recv $plst"
			set PList $plst
		}
	} elseif {$typ =="Rreq"} {
        if {[info exist  RRq_idl_($src)] && $RRq_idl_($src) >= $pid_} { return }
		set RRq_idl_($src) $pid_

		if {$dst==$nd_id} {

			incr Rrpid
			set enm 	[lindex $p 6]
			set aid_ 	[lindex $p 7]
			set vall 	0
			puts "$enm $aid_"

			foreach pll $PList {
				set kl [lindex $pll 0]
				if {$kl == $aid_} {
					set vall 1
					break
				}
			}
			if {$vall ==1} {
				set ky 	[lindex $pll 1]
            	set dms [expr int(pow($enm,$ky))%33]
				if {$dms == $aid_} {
					set ems [expr int(pow($AID,7))%33]
					set pkt "$nd_id $src Rrep $nd_id $frw $rpid $ems $AID"
   					$PS  Send_info $cov "$pkt"
				} else {
					return
				}
				set Ngl_($src)  $frw
			}
		} else {
			set Ngl_($src)  $frw
			$self forward "$p"
		}
    } elseif {$typ =="Rrep"} {
		set enm 	[lindex $p 6]
		set aid_ 	[lindex $p 7]
		set vall 	0
		foreach pll $PList {
			set kl [lindex $pll 0]
			if {$kl == $aid_} {
				set vall 1
				break
			}
		}
		if {$vall ==1} {
			set ky 	[lindex $pll 1]
           	set dms [expr int(pow($enm,$ky))%33]
			if {$dms != $aid_} {
				return
			}
		} else {
			return
		}
       	set Ngl_($src)  $frw		
		if {$dst!=$nd_id} {
			$self forward "$p"
 		}
	} elseif {$typ =="rej"} { 
        set RID [lindex $p 6]
		set mess [$self Gen_AID]
		while {$mess == $RID} {
			set mess [$self Gen_AID]
		}
        set AID $mess
		$self send_req $RTA 
	} elseif {$typ == "Rrej"} {
			set fb [lsearch $Tlist $mes]
        	set RID [lindex $p 6]
			if  {$fb !=-1} {
				set Tlist [lreplace $Tlist $fb $fb]
  				set pkt "$nd_id $src rej $nd_id $frw 0 $RID"
   				$PS  Send_info $cov "$pkt"
			}
   	} elseif {$typ =="Data"} {
		if {$dst!=$nd_id} {
			$self forward "$p"
 		}
	}
 
}
Pan_node instproc Gen_AID {} {
    $self instvar nd_id ran orc  activ cov Ngl_ Rq_idl_ rqid rpid nd_typ  RSU_id Rrqid Did_ Waitt RRq_idl_ AID Tlist PList
    	set mess 		[expr int([$ran uniform 2 9])]
		return 		$mess

}
Pan_node instproc  forward {p} {
 	global GS ns_ node_ PS 
    $self instvar nd_id ran orc Neigh_ activ  cov Ngl_ Rq_idl_
   	set src  [lindex $p 0]
   	set dst  [lindex $p 1]
   	set typ  [lindex $p 2]
   	set frw  [lindex $p 3]
   	set nxt  [lindex $p 4]
    set pid_ [lindex $p 5]

	set pkt [lreplace $p 3 3 $nd_id]
    if {$nxt != -1 && [info exist Ngl_($dst)]} {
		set pkt [lreplace $pkt 4 4 $Ngl_($dst)]
    } else {
		set pkt [lreplace $pkt 4 4 -1]
	}

   $PS  Send_info $cov "$pkt"
}

Pan_node instproc send_req {dst} {
   global PS  
   $self instvar nd_id ran orc Neigh_ activ  cov Ngl_ rqid RSU_id AID

	if {$RSU_id != "x"} {
		set nd_nxt $RSU_id
    } else {
		$ns_ at [expr [$ns_ now]+1] "$self send_req $dst"
		return
	}
    incr rqid
    puts $nd_id------------>$AID
    set BRS  1
    set ems [expr int(pow($AID,7))%33]
    set pkt "$nd_id $dst req $nd_id $nd_nxt $rqid $BRS $ems $AID"
    $PS  Send_info $cov "$pkt"
}


Pan_node instproc send_Rreq {dst} {
   global PS   ns_
   $self instvar nd_id ran orc Neigh_ activ  cov Ngl_ rqid RSU_id  Rrqid Did_ Waitt AID
    incr Rrqid
    set ems [expr int(pow($AID,7))%33]
#let make assumption the anonymous process done with the 7&8 fields remaining for NS2 simulator purpose we used
    set pkt "$nd_id $dst Rreq $nd_id -1 $Rrqid $ems $AID"
    $PS  Send_info $cov "$pkt"
}

Pan_node instproc send_Data  {dst} {
   global PS  ns_
   $self instvar nd_id ran orc Neigh_ activ  cov Ngl_ rqid RSU_id Did_ Waitt
    if {[info exist Ngl_($dst)]} {
		set pkt "$nd_id $dst Data $nd_id $Ngl_($dst) $Did_"
		$PS  Send_info $cov "$pkt"
    } elseif {$Waitt<[$ns_ now] } {
		$self send_Rreq $dst
		set Waitt [expr [$ns_ now]+0.1]
	}

   $ns_ at [expr [$ns_ now]+0.01] "$self send_Data $dst"
}


