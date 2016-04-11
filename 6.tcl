#! /usr/bin/wish -f
#set vv [lindex $argv 0]
#puts $vv


proc finish {} {
destroy .l
 destroy .e
 destroy .b
 label .l -text "Registration completed"
 button .b -text "<< finish >>" -bd 5 -command exit
 grid .l -row 0 -column 0 -columnspan 30
 grid .b -row 1 -column 0 -columnspan 30


}


proc anim {v} {
 destroy .l
 destroy .e
 destroy .b
proc moveit {object x y} {
  .c coords $object [expr $x-5] [expr $y-5] [expr $x+5] [expr $y+5]
}

canvas .c -width 300 -height 150 


set myoval [ .c create oval 100 200 110 210 -fill black ]
set points  [ list 100 205 120 205 120 185  100 185 ]
set myp [.c create polygon $points -outline black -fill orange]
set point  [ list 500 205 520 205 520 185  500 185 ]
set myp [.c create polygon $point -outline black -fill orange]iob
label .c.s -text "$v"
 
 
 for { set j 0 } {$j < 50 } { incr j } {
  for {set i 100} { $i <  500} { set i [expr $i+0.2]  } {
   moveit $myoval $i 200
   update
   grid .c  location 100 200
  
   grid .c.s -ipadx 250 -ipady 220
  }
 }
  
}
proc exit_ {} { 
 global usr pass ct  name D_r vv
  set D_r $name
  
  if { [file exist RSU_server/$D_r] } { 
   set vv_ [open RSU_server/$D_r r]
   set i 0
   
   while { ! [eof $vv_] } {
   gets   $vv_ v($i)
   
   incr i 
   }
  close $vv_
  }
 set i 0
 set mm [open RSU_server/$D_r w]
 while {[info exist v($i)]} {
 puts $mm "$v($i)"
 incr i
 }

 puts $mm "$usr $pass" 
 close $mm
 finish
# anim $D_r
 #exit
}
proc rsu {} {
global name vv usr pass ct D_r
 set pass $name
 destroy .l
 destroy .b
 label .l -text "Default RSU"
 button .b -text "<< submit & exit >>" -bd 5 -command exit_
 grid .l -row 0 -column 0 -sticky n
 grid .e -row 0 -column 1 -sticky n
 grid .b -row 1 -column 0 -columnspan 30

#puts stdout $name
set name ""
}



proc pswd {} {
 global name vv password ct pass

 set pass $name
 destroy .l
 destroy .b
 label .l -text "City "
 button .b -text "<< submit >>" -bd 5 -command rsu


 grid .l -row 0 -column 0 -sticky n
 grid .e -row 0 -column 1 -sticky n
 grid .b -row 1 -column 0 -columnspan 30
 
 set name ""

}


proc kks {} {
global name usr vv pass
 set usr $name
 #puts $user($vv)
 destroy .l
 destroy .b
 label .l -text "Password "
 button .b -text "<< submit >>" -bd 5 -command rsu
 

 grid .l -row 0 -column 0 -sticky n
 grid .e -row 0 -column 1 -sticky n
 grid .b -row 1 -column 0 -columnspan 30
#puts stdout $name
set name ""
}

proc reg {} {
  global name usr
  destroy .b
  label .l -text "User Name "
  button .b -text "<< submit >>" -bd 5 -command kks
  grid .l -row 0 -column 0 -sticky n
  grid .e -row 0 -column 1 -sticky n
  grid .b -row 1 -column 0 -columnspan 30
}


entry .e -width 60 -relief sunken -bd 5 -textvariable name
focus .e
button .b -text "<< start reg... >>" -bd 5 -command reg

grid .b -row 1 -column 0 -columnspan 30



