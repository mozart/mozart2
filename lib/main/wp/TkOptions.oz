%%%
%%% Author:
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Benjamin Lorenz, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL WARRANTIES.
%%%

local

   BorderWidth = 1
   BorderOptionsList =
   ['*OzTools*Label*borderWidth'
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
    '*TkFDialog*selectBorderWidth']

in

   {TkBatch {Map BorderOptionsList
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

   {TkBatch {Map BooleanOptionsList
             fun {$ Option}
                Pattern # Value = Option
             in
                option(add Pattern Value widgetDefault)
             end}}

end


local

   Select = if IsColor then 2 else 3 end
   ColorOptionsList =
   [
    '*OzTools*NumberEntry*Entry*background' # wheat # white
   ]

in

   {TkBatch {Map ColorOptionsList
             fun {$ Option}
                Pattern = Option.1
                Value   = Option.Select
             in
                option(add Pattern Value widgetDefault)
             end}}

end


class OptionsManager
   attr Resources Window
   meth tkInit(Res Class<='OzTools')
      Resources <- Res
      Window <- {New TkToplevel tkInit(withdraw: true
                                       'class':  Class)}
   end
   meth get(Name $)
      Return # Class # Default = @Resources.Name
   in
      case {case Return
            of return     then TkReturnString
            [] returnAtom then TkReturnAtom
            [] returnInt  then TkReturnInt
            end option(get @Window Name Class)}
      of nil       then Default
      [] false     then Default
      elseof Value then Value
      end
   end
end


%% change some class bindings
{TkBatch [bind('Checkbutton' '<Return>' '')
          bind('Radiobutton' '<Return>' '')
          bind('Entry' '<Control-u>' '%W delete 0 end')]}


%% Read user's config file
local
   File = local
             UserHome = {OS.getEnv 'HOME'}
          in
             if UserHome \= false then
                F = {Property.get 'oz.dotoz'} # '/wishrc'
             in
                try {OS.stat F _} F
                catch system(...) then unit end
             else unit end
          end
in
   if File \= unit then
      {TkSend option(readfile File widgetDefault)}
   end
end
