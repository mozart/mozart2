%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
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

\insert server

\insert agenda

local
   GateId={`Builtin` 'GateId' 1}
   OpenGate={`Builtin` 'OpenGate' 1}
   CloseGate={`Builtin` 'CloseGate' 0}
   SendGate={`Builtin` 'SendGate' 2}
in
   Gate = gate(id: GateId
               open: OpenGate
               close:CloseGate
               send:SendGate)
end

%\insert remote

\insert netscape

local
   Wget = {`Builtin` 'Wget' 2}
in

   Site = site(server:          Server
               newServer:       NewServer
%              computeServer:   ComputeServer
               runApplets:      RunApplets
               linkToNetscape:  LinkToNetscape
               wget:            Wget
               gate:            Gate
              )
end


%%

/*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Save/Load

% Save standard modules
{SmartSave Site.modules '/tmp/modules.ozc' unit unit nil nil}

% Load standard modules
declare M={Load 'file:/tmp/modules.ozc'}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compute Server

% start a ComputeServer on munchkin
declare S={New ComputeServer init(host:'munchkin.ps.uni-sb.de')}

declare S={New ComputeServer init(host:'norge.info.ucl.ac.be'
                                  rshCmd:ssh
                                  ozHome:'/nimitz/tools/Oz/oz-devel'
                                  showWindow:Tk
                                 )}

% execute
{S exec(proc {$} {Show test} end)}

{S exec(proc {$} {Show {Map [1 2 3] fun {$ X} X*X end}} end)}

declare Ret in
{S exec(proc {$} Ret = {Map [1 2 3] fun {$ X} X*X end} end)}

{Browse Ret}

declare
Ret
fun {MakeList N}
   case N>0 then N|{MakeList N-1} else nil end
end
L={MakeList 100000}
in
{Browse Ret}
{Browse {Reverse Ret}}

{S exec(proc {$} Ret = {Map L fun {$ X} X*X end} end)}

% terminate compute server
{S close}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Netscape plugin

declare S P={NewPort S}
{LinkToNetscape P}
{Browse S}


{RunApplets}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MakeExecComponent

declare
proc {Hello}
   {System.showInfo 'Hello World!'}
end

{Site.makeExecComponent Hello '/tmp/xx'}

*/
