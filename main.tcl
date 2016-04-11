#
#===================================
#     Simulation parameters setup
#===================================
set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(ant)    Antenna/OmniAntenna        ;# antenna model

set val(ll)     LL                         ;# link layer type
set val(mac)    Mac/802_11                 ;# MAC type

set val(rp)     AODV                       ;# routing protocol

set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ifqlen) 50                         ;# max packet in ifq


#===================================
#        Initialization        
#===================================
#Create a ns simulator


set val(nn)     7                        ;# number of mobilenodes
set val(x)      5100                      ;# X dimension of topography
set val(y)      2000                      ;# Y dimension of topography
set val(stop)   50.0                         ;# time of simulation end


set ns [new Simulator]
set ns_ $ns

#Open the NS trace file
set tracefile [open out.tr w]
#Open the NAM trace file
set namfile [open out.nam w]

$ns trace-all $tracefile
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)


#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)



set chan [new $val(chan)];#Create wireless channel


#===================================
#     Mobile node parameter setup
#===================================
$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON

#===================================
#        Nodes Definition        
#===================================
source trace
source algorithm.tcl
set PS [new Pan_Sim]
set rsu_c 3
set vlc 3

for {set i 0 } {$i <$val(nn) } {incr i } {
	set n($i) [$ns node]
    set node_($i) $n($i) 
	set nd_($i) [$PS Node]
	$n($i) color black

}



$n(0) set X_ 987
$n(0) set Y_ 754
$n(1) set X_ 900
$n(1) set Y_ 100
$n(2) set X_ 1800
$n(2) set Y_ 100
$n(3) set X_ 10
$n(3) set Y_ 100
$n(4) set X_ 1
$n(4) set Y_ 1

$n(5) set X_ 200
$n(5) set Y_ 1
$n(6) set X_ 350
$n(6) set Y_ 1

$nd_(0) set-RTA
$nd_(3) set-RSU
$nd_(1) set-RSU
$nd_(2) set-RSU

$ns_ at 1 "$nd_(4) send_Data 6"
#$ns_ at 1 "$nd_(0) send_req 3"
#$ns_ at 1.5 "$nd_(0) send_req 3"

$ns initial_node_pos $n(0) 40
for {set i 1} {$i<[expr $rsu_c+1]} { incr i} {
$ns initial_node_pos $n($i) 30
}
for {set i [expr $rsu_c+1]} {$i<[expr $rsu_c+$vlc+1]} { incr i} {
$ns initial_node_pos $n($i) 10
}
$ns_ at 2 "$n(5) setdest 1530.61000000000 50.000000000000 80.000000000000" 
$ns_ at 2 "$n(4) setdest 1530.61000000000 50.000000000000 80.000000000000" 
$ns_ at 2 "$n(6) setdest 1530.61000000000 50.000000000000 80.000000000000"
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam out.nam &
 
    exit 0
}

for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$n($i) reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"



$ns run
