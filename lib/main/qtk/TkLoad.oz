%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
%
% Last change:
%   $Date$
%   $Revision$
%
% This file is part of Mozart, an implementation
% of Oz 3:
%   http://www.mozart-oz.org
%
% See the file "LICENSE" or
%   http://www.mozart-oz.org/LICENSE.html
% for information on usage and redistribution
% of this file, and for a DISCLAIMER OF ALL
% WARRANTIES.
%
%  The development of QTk is supported by the PIRATES project at
%  the Université catholique de Louvain.

functor
require
   BootObject at 'x-oz://boot/Object'
   BootName   at 'x-oz://boot/Name'
prepare
   GetClass = BootObject.getClass
   OoFeat   = {BootName.newUnique 'ooFeat'}
import
   Tk
   Property(get)
export
   Load
   LoadPI
define
   TkClass =
   {List.last
    {Arity
     {GetClass
      {New class $ from Tk.frame meth init skip end end init}}
     . OoFeat}}

   fun{Load FileName TkName}
      {Tk.send load(FileName)}
      class $
         from Tk.frame
         feat !TkClass:TkName
      end
   end

   fun{LoadPI FileName TkName}
      P={Property.get 'platform'}.os
   in
      {Load
       FileName#"-"#P#if P==win32 then ".dll" else ".so" end
       TkName}
   end

end
