%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {$ IMPORT}
   \insert '../lib/import.oz'
in

   space([nomosim(equal(fun {$}
                           proc {SolveLine Ls Ps}
                              thread
                                 dis Ls=nil Ps=nil
                                 [] Lr Pr in Ps=(Ls=_|_)#Lr|Pr then
                                    {SolveLine Lr Pr}
                                 [] Lr in Ls='o'|Lr then {SolveLine Lr Ps}
                                 end
                              end
                           end

                           proc {SolveAll LPs}
                              thread
                                 dis Ls#Ps|LPr=!LPs in {SolveLine Ls Ps} then
                                    {SolveAll LPr}
                                 [] LPs=nil
                                 end
                              end
                           end

                           proc {DoIt Board}
                              [[X11 X12 X13 X14 X15 X16 X17 X18]
                               [X21 X22 X23 X24 X25 X26 X27 X28]
                               [X31 X32 X33 X34 X35 X36 X37 X38]
                               [X41 X42 X43 X44 X45 X46 X47 X48]
                               [X51 X52 X53 X54 X55 X56 X57 X58]
                               [X61 X62 X63 X64 X65 X66 X67 X68]
                               [X71 X72 X73 X74 X75 X76 X77 X78]
                               [X81 X82 X83 X84 X85 X86 X87 X88]
                               [X91 X92 X93 X94 X95 X96 X97 X98]
                              ] = !Board
                              LineS
                              [[X11 X12 X13 X14 X15 X16 X17 X18]#
                               [(x|x|x|T)#T]
                               [X21 X22 X23 X24 X25 X26 X27 X28]#
                               [(x|x|T1)#T1
                                ('o'|x|T2)#T2]
                               [X31 X32 X33 X34 X35 X36 X37 X38]#
                               [(x|x|x|T3)#T3
                                ('o'|x|x|T4)#T4]
                               [X41 X42 X43 X44 X45 X46 X47 X48]#
                               [(x|x|T5)#T5
                                ('o'|x|x|T6)#T6]
                               [X51 X52 X53 X54 X55 X56 X57 X58]#
                               [(x|x|x|x|x|x|T7)#T7]
                               [X61 X62 X63 X64 X65 X66 X67 X68]#
                               [(x|T8)#T8
                                ('o'|x|x|x|x|x|T9)#T9]
                               [X71 X72 X73 X74 X75 X76 X77 X78]#
                               [(x|x|x|x|x|x|T10)#T10]
                               [X81 X82 X83 X84 X85 X86 X87 X88]#
                               [(x|T11)#T11]
                               [X91 X92 X93 X94 X95 X96 X97 X98]#
                               [(x|x|T12)#T12]
                               [X11 X21 X31 X41 X51 X61 X71 X81 X91]#
                               [(x|T13)#T13
                                ('o'|x|x|T14)#T14]
                               [X12 X22 X32 X42 X52 X62 X72 X82 X92]#
                               [(x|x|x|T15)#T15
                                ('o'|x|T16)#T16]
                               [X13 X23 X33 X43 X53 X63 X73 X83 X93]#
                               [(x|T17)#T17
                                ('o'|x|x|x|x|x|T18)#T18]
                               [X14 X24 X34 X44 X54 X64 X74 X84 X94]#
                               [(x|x|x|x|x|x|x|T19)#T19
                                ('o'|x|T20)#T20]
                               [X15 X25 X35 X45 X55 X65 X75 X85 X95]#
                               [(x|x|x|x|x|T21)#T21]
                               [X16 X26 X36 X46 X56 X66 X76 X86 X96]#
                               [(x|x|x|T22)#T22]
                               [X17 X27 X37 X47 X57 X67 X77 X87 X97]#
                               [(x|x|x|x|T23)#T23]
                               [X18 X28 X38 X48 X58 X68 X78 X88 X98]#
                               [(x|x|x|T24)#T24]
                              ]
                              = !LineS
                           in
                              {SolveAll {Reverse LineS}}
                           end
                        in
                           {SearchOne DoIt}
                        end

                        [[[o x x x o o o o]
                          [x x o x o o o o]
                          [o x x x o o x x]
                          [o o x x o o x x]
                          [o o x x x x x x]
                          [x o x x x x x o]
                          [x x x x x x o o]
                          [o o o o x o o o]
                          [o o o x x o o o]]])

                  keys: [space search 'dis' 'thread' list])])
end
