%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Christian Schulte, 1997
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
   BILinkObjectFiles  = {`Builtin` linkObjectFiles  2}
   BIUnlinkObjectFile = {`Builtin` unlinkObjectFile 1}
   BIdlOpen           = {`Builtin` dlOpen  2}
   BIdlClose          = {`Builtin` dlClose 1}

   fun {ToAtom File}
      case {IsAtom File} then File
      else {String.toAtom {VirtualString.toString File}} end
   end

   BIFindFunction = {`Builtin` findFunction 3}

   proc {FindFunction AName Ar Handle}
      {Wait AName}
      {Wait Ar}
      case Handle==~1 then skip
      else {BIFindFunction AName Ar Handle}
      end
   end

   fun {LoadAux Spec Handle}
      ModuleLabel  = {Label Spec}
      ModuleString = {Atom.toString ModuleLabel}
      All          = {Arity Spec}
      Module       = {MakeRecord ModuleLabel All}
   in
      {ForAll All
       proc {$ AName}
          D = Spec.AName
          N = {String.toAtom
               {Append ModuleString
                &_|{Atom.toString AName}}}
       in
          {FindFunction N D Handle}
          Module.AName = {`Builtin` N D}
       end}
      Module
   end

   fun {LinkObjectFiles Files}
      NewFiles={Map Files ToAtom}
   in
      {BILinkObjectFiles NewFiles}
   end

   proc {UnlinkObjectFile File}
      F={ToAtom File}
   in
      {BIUnlinkObjectFile F}
   end
   fun {Load Files Spec}
      {LoadAux Spec {LinkObjectFiles Files}}
   end

   FindFile = {`Builtin` 'FindFile' 3}
   EnvToTuple = {`Builtin` 'EnvToTuple' 2}

in

   fun
      {NewForeign}
      SearchPath = {NewCell path}
      GetSearchPath SetSearchPath Require
      Spath = {EnvToTuple 'OZ_FOREIGN_LIBS'}
   in
      case Spath==false then
         OS#CPU = {System.get platform}
      in
         {Assign SearchPath
          path('/project/ps/soft/oz-devel/oz/platform/'#OS#'-'#CPU)}
      else
         {Assign SearchPath Spath}
      end

      fun {GetSearchPath} {Access SearchPath} end
      fun {SetSearchPath} {Assign SearchPath} end

      fun {Require File Spec}
         FullPath = {FindFile {Access SearchPath} File}
      in
         case FullPath==false then
            raise error(fileNotFound(File) debug:debug) with debug end
         else {LoadAux Spec {BIdlOpen FullPath}} end
      end

      foreign(reload:
                 fun {$ Files Spec}
                    {ForAll Files UnlinkObjectFile}
                    {Load Files Spec}
                 end
              dload:
                 fun {$ File Spec ?CloseF}
                    Handle = {BIdlOpen File}
                 in
                    CloseF = proc {$} {BIdlClose Handle} end
                    {LoadAux Spec Handle}
                 end
              load: Load
              getSearchPath: GetSearchPath
              setSearchPath: SetSearchPath
              require: Require
             )
   end

end
