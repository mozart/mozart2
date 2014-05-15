%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   PanelTopClosed = {NewName}

   \insert configure.oz

   \insert runtime-bar.oz

   \insert load.oz

   \insert dialogs.oz

   \insert make-notes.oz

   \insert top.oz

   fun {PickClosest NT Ts}
      ST#_|Tr = Ts
   in
      {FoldL Tr
       fun {$ T#D TA#_}
	  ND = {Abs TA - NT}
       in
	  if ND<D then TA#ND else T#D end
       end
       ST#{Abs ST - NT}}.1
   end

in

   class PanelClass
      prop locking final
      feat Options
      attr ThisPanelTop:unit

      meth init
	 O = self.Options
      in
	 O = {Dictionary.new}
	 {Dictionary.put O config  false}
	 {Dictionary.put O time    DefaultUpdateTime}
	 {Dictionary.put O mouse   true}
	 {Dictionary.put O history DefaultHistoryRange}
      end

      meth open
	 lock
	    if @ThisPanelTop==unit then
	       ThisPanelTop <- thread
				  {Thread.setThisPriority high}
				  {New PanelTop init(manager:self
						     options:self.Options)}
			       end
	    end
	 end
      end

      meth close
	 lock
	    if @ThisPanelTop\=unit then
	       thread {@ThisPanelTop tkClose} end
	       ThisPanelTop <- unit
	    end
	 end
      end
      
      meth !PanelTopClosed
	 lock
	    ThisPanelTop <- unit
	 end
      end

      meth option(What ...) = OM
	 lock
	    O = self.Options
	 in
	    {Wait @ThisPanelTop}
	    if
	       if
		  What==update andthen {List.sub {Arity OM} [1 mouse time]}
	       then
		  if {HasFeature OM time} then T=OM.time in
		     if {IsNat T} then
			{Dictionary.put O time {PickClosest T UpdateTimes}}
			true
		     else false
		     end
		  else true
		  end
		  andthen
		  if {HasFeature OM mouse} then M=OM.mouse in
		     if {IsBool M} then {Dictionary.put O mouse M} true
		     else false
		     end
		  else true
		  end
	       elseif
		  What==history andthen {List.sub {Arity OM} [1 range]}
	       then
		  if {HasFeature OM range} then R=OM.range in
		     if {IsNat R} then
			{Dictionary.put O history {PickClosest R HistoryRanges}}
			true
		     else false
		     end
		  else true
		  end
	       elseif
		  What==configure andthen {List.sub {Arity OM} [1 2]}
	       then
		  if {HasFeature OM 2} then C=OM.2 in
		     if {IsBool C} then {Dictionary.put O config C} true
		     else false
		     end
		  else true
		  end
	       else false
	       end
	    then T=@ThisPanelTop in
	       if T\=unit then
		  {T updateAfterOption}
	       end
	    else
	       {Exception.raiseError panel(option OM)}
	    end
	 end
      end

   end

end

