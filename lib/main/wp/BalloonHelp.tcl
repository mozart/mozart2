##
## Author:
##   John Stump <iliad@doitnow.com>
##
## Copyright:
##   John Stump <iliad@doitnow.com>
##
## Last change:
##   $Date$ by $Author$
##   $Revision$
##
## This file is part of Mozart, an implementation of Oz 3
##   $MOZARTURL$
##
## See the file "LICENSE" or
##   $LICENSEURL$
## for information on usage and redistribution
## of this file, and for a DISCLAIMER OF ALL WARRANTIES.
##
##
## Balloon Help Routines
##
##------------------------------------------------------------------------
## PROCEDURE
##      balloonhelp
##
## DESCRIPTION
##      Implements a balloon help system
##
## ARGUMENTS
##      balloonhelp <widget> ?text?
##
## If ?text? is {}, then the balloon help for that widget is removed.
## The widget must exist prior to calling balloonhelp.
##
## RETURNS: the balloon help text for <widget>
##
## NAMESPACE & STATE
##      The global array BalloonHelp is used.  Procs begin with BalloonHelp.
## The overrideredirected toplevel is named .__balloonhelp.
##
## EXAMPLE USAGE:
##      balloonhelp .button "A Button"
##
## Modification by John Stump:
##      if the text begins with "exec", then it will execute the command
##      and make the results the balloon text; i.e.
##         balloonhelp .l "exec from"
##
##------------------------------------------------------------------------

## An alternative to binding to all would be to bind to BalloonHelp
## and add that to the bindtags of each widget registered.

bind all <Enter> {
  if [info exists BalloonHelp(%W)] {
    if { $BalloonHelp(enabled) } {
      set BalloonHelp(afterid) [after 800 {BalloonHelp:show %W}]
    }
  }
}
bind all <Leave>        { BalloonHelp:hide %W }
bind all <Any-KeyPress> { BalloonHelp:hide %W }
bind all <Any-Button>   { BalloonHelp:hide %W }
set BalloonHelp(enabled) 1

proc balloonhelp {w {txt NULL}} {
  global BalloonHelp
  if [string match clear $w] {
    foreach i [array names BalloonHelp .*] { unset BalloonHelp($i) }
  }
  if ![winfo exists $w] {
    return -code error "bad window path name \"$w\""
  }
  if [string comp NULL $txt] {
      if {[string match {} $txt]} {
        catch {unset BalloonHelp($w)}
        return
      } else {
        set BalloonHelp($w) $txt
      }
  }
  if [info exists BalloonHelp($w)] { return $BalloonHelp($w) }
}

;proc BalloonHelp:show {w} {
  global BalloonHelp
  if ![info exists BalloonHelp($w)] return
  if {[string match $w [eval winfo contain [winfo pointerxy $w]]]} {
    set b .__balloonhelp
    if ![winfo exists $b] {
      toplevel $b
      wm override $b 1
      wm withdraw $b
      pack [label $b.l -highlightt 0 -relief raised -bd 1 -background #f0f000]
    }
    if { [lindex $BalloonHelp($w) 0] == "exec" } {
      set txt [eval $BalloonHelp($w)]
    } else {
      set txt $BalloonHelp($w)
    }
    #$b.l configure -text $BalloonHelp($w)
    $b.l configure -text $txt
    update idle
    set x [expr [winfo rootx $w]+(([winfo width $w]-[winfo reqwidth $b])/2)]
    set y [expr [winfo rooty $w]+[winfo height $w]+6]
    if {$x<0} {
      set x 0
    } elseif {($x+[winfo reqwidth $b])>[winfo screenwidth $w]} {
      set x [expr [winfo screenwidth $w]-[winfo reqwidth $b]]
    }
    if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
      set y [expr [winfo rooty $w]-[winfo reqheight $b]-6]
    }
    wm geometry $b +$x+$y
    wm deiconify $b
    raise $b
  }
}

;proc BalloonHelp:hide {w} {
  global BalloonHelp
  catch {after cancel $BalloonHelp(afterid)}
  catch {wm withdraw .__balloonhelp}
}
