%%%
%%% Authors:
%%%   Benjamin Lorenz (lorenz@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Benjamin Lorenz, 1997
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

local

   BorderWidth = 1
   BorderOptionsList =
   [
    '*OzTools*Label*borderWidth'
    '*OzTools*Button*borderWidth'
    '*OzTools*Checkbutton*borderWidth'
    '*OzTools*Radiobutton*borderWidth'
    '*OzTools*Menubutton*borderWidth'
    '*OzTools*Menu*borderWidth'
    '*OzTools*Entry*borderWidth'
    '*OzTools*Text*borderWidth'
    '*OzTools*Scrollbar*borderWidth'
    '*OzTools*Scale*borderWidth'
    '*OzTools*Listbox*borderWidth'

    '*OzTools*Button*highlightThickness'
    '*OzTools*Checkbutton*highlightThickness'
    '*OzTools*Radiobutton*highlightThickness'
    '*OzTools*Menubutton*highlightThickness'
    '*OzTools*Entry*highlightThickness'
    '*OzTools*Text*highlightThickness'
    '*OzTools*Canvas*highlightThickness'
    '*OzTools*Scrollbar*highlightThickness'
    '*OzTools*Scale*highlightThickness'
    '*OzTools*Listbox*highlightThickness'

    '*OzTools*activeBorderWidth'
    '*OzTools*selectBorderWidth'

    '*OzTools*MenuFrame*borderWidth'

    '*TkFDialog*borderWidth'
    '*TkFDialog*activeBorderWidth'
    '*TkFDialog*selectBorderWidth'
   ]

in

   {Tk.batch {Map BorderOptionsList
              fun {$ Pattern}
                 option(add Pattern BorderWidth widgetDefault)
              end}}

end


local

   BooleanOptionsList =
   [
    '*OzTools*Menu*tearOff' # false
   ]

in

   {Tk.batch {Map BooleanOptionsList
              fun {$ Option}
                 Pattern # Value = Option
              in
                 option(add Pattern Value widgetDefault)
              end}}

end


local

   Select = case Tk.isColor then 2 else 3 end
   ColorOptionsList =
   [
    '*OzTools*NumberEntry*Entry*background' # wheat # white
   ]

in

   {Tk.batch {Map ColorOptionsList
              fun {$ Option}
                 Pattern = Option.1
                 Value   = Option.Select
              in
                 option(add Pattern Value widgetDefault)
              end}}

end


%% this removes some additional bindings which Motif doesn't
%% have. Unfortunately, it also disables some of the more useful key
%% bindings, see below...
{Tk.send set(tk_strictMotif 1)}

%% we don't need this if tk_strictMotif = 1
% {Tk.send bind('Checkbutton' '<Return>' '')}

%% this has to be redefined if tk_strictMotif = 1
{Tk.send bind('Entry' '<Control-f>'
              'tkEntrySetCursor %W [expr [%W index insert] + 1]')}
{Tk.send bind('Entry' '<Control-b>'
              'tkEntrySetCursor %W [expr [%W index insert] - 1]')}
{Tk.send bind('Entry' '<Control-a>' 'tkEntrySetCursor %W 0')}
{Tk.send bind('Entry' '<Control-e>' 'tkEntrySetCursor %W end')}

%% and some other handy stuff...
{Tk.send bind('Entry' '<Control-u>' '%W delete 0 end')}


%% Read user's config file
local
   File = local
             UserHome = {OS.getEnv 'HOME'}
          in
             case UserHome \= false then
                F = UserHome # '/.oz/wishrc'
             in
                try {OS.stat F _} F
                catch system(...) then unit end
             else unit end
          end
in
   case File \= unit then
      {Tk.send option(readfile File widgetDefault)}
   else skip end
end
