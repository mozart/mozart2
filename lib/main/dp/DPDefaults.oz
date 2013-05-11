%%%
%%% Authors:
%%%   Yves Jaradin (yves.jaradin@uclouvain.be)
%%%
%%% Contributors:
%%%   Raphael Collet (raphael.collet@uclouvain.be)
%%%
%%% Copyright:
%%%   Yves Jaradin, 2008
%%%
%%% Last change:
%%%   $Date: 2008-03-06 13:33:44 +0100 (Thu, 06 Mar 2008) $ by $Author: yjaradin $
%%%   $Revision: 16860 $
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

functor
import
   Finalize
   Open
   OS
   Property
   Pickle
   Site

export
   Init
   Listen

define
   %% a small abstraction for caching sessions and resolutions
   fun {NewCache Generate}
      Cache={NewCell nil}
      proc {Take K L ?Lout ?Res}
         case L of X|T then
            if X.1==K then Lout=T Res=[X.2] else Lout=X|{Take K T $ Res} end
         else Lout=nil Res=nil end
      end
   in
      {Finalize.everyGC proc {$} Cache:=nil end}
      cache(get: fun {$ K}
                    L T in L=Cache:=T
                    case {Take K L T} of [X] then X else {Generate K} end
                 end
            put: proc {$ K X}
                    T in T=Cache:=(K#X)|T
                 end)
   end

   %% format/parse messages in Session
   fun{BuildMsg M Tail}
      case M
      of nil then &<|&>|Tail
      [] _|_ then &<|{FoldL M fun {$ Acc X} {BuildMsg X $ Acc} end $ &>|Tail}
      [] &< then {Exception.raiseError dp(line badChar &<)} unit
      [] &> then {Exception.raiseError dp(line badChar &>)} unit
      else M|Tail
      end
   end
   proc{ParseMsg T S}
      case T
      of nil then S.1=nil S.2=nil
      [] &<|T then X Y in S.1=X|Y {ParseMsg T X|Y|S.2}
      [] &>|T then S.1=nil {ParseMsg T S.2}
      [] H|T then X in S.1=H|X {ParseMsg T X|S.2}
      end
   end

   %% A Session wraps a socket connection to communicate with a site
   class Session from Open.socket
      attr
         id
         owner: true     % whether the session owns its file descriptors

      meth init(U)
         Ip#PortNum#Id={DecomposeURI U}
      in
         Open.socket,init()
         id:=Id
         {self connect(host:Ip port:{String.toInt PortNum})}
         {Finalize.register self proc {$ C} {C close} end}
      end
      meth dOpen(X Y)
         Open.socket,dOpen(X Y)
         {Finalize.register self proc {$ C} {C close} end}
      end
      meth close(...)=M
         %% don't close if the session has been unhooked
         if @owner then Open.socket,M end
      end
      meth unHook()
         owner:=false
      end

      meth getId($)
         @id
      end

      meth sendMsg(M)
         {self send(vs:{BuildMsg M nil})}
      end
      meth receiveMsg($)
         {self Receive("" $)}
      end
      meth Receive(I $)
         L Str={Append I Open.socket,read(list:$ len:L)}
      in
         try
            {ParseMsg Str [$]|nil}
         catch _ then
            if L>0 then
               {self Receive(Str $)}
            else
               {Exception.raiseError dp(line dropped)} unit
            end
         end
      end
      meth ReceiveN(N $)
         L T Str=Open.socket,read(list:$ tail:T size:N len:L)
      in
         if N<L then
            T={self ReceiveN(N-L $)}
         else
            T=nil
         end
         Str
      end
      meth receiveMsgForce(M $)
         Expected={BuildMsg M nil}
         LL={Length Expected}
         Str={self ReceiveN(LL $)}
      in
         Str==Expected
      end
   end

   %% cache wrappers
   SessionCache={NewCache fun {$ URI} {New Session init(URI)} end}
   fun {GetSession URI} {SessionCache.get URI} end
   proc {PutSession URI Sess} {SessionCache.put URI Sess} end

   %% define default settings for DP module
   proc{Init}
      Resolvers={NewDictionary}
   in
      Resolvers.'oz-site':=Resolve
      {Property.put 'dp.firewalled' false}
      {Property.put 'dp.resolver' Resolvers}
      {Property.put 'dp.listenerParams'
       default(id: 'h'#(({OS.time} mod 257)*65536+{OS.getPID}) )}
   end

   %% resolve a site URI; this returns a record s(site:S connect:C),
   %% where S is the site corresponding to the URI, and C is a unary
   %% function that returns a valid connection to that site
   proc {Resolve URI ?Res}
      Res={ResolveCache.get URI}
      {ResolveCache.put URI Res}     % keep that stuff in the cache
   end

   ResolveCache={NewCache DoResolve}
   fun {DoResolve URI}
      try
         Sess={GetSession URI}
      in
         {Sess sendMsg(["get" URI])}     % send request: <get URI>
         case {Sess receiveMsg($)}
         of ["ok" !URI PSite Meths] then S in     % successful reply
            {PutSession URI Sess}
            S={Pickle.unpack {Decode PSite}}
            s(site:S connect:{MakeConnect URI S Meths})
         [] ["dead" !URI PSite] then     % site is dead, cannot connect
            {PutSession URI Sess}
            s(site:{Pickle.unpack {Decode PSite}} connect:FailConnect)
         end
      catch system(os(os "connect" ...) ...) andthen {IsCritical URI} then
         s(site:{Value.failed siteIsDead} connect:FailConnect)
      [] _ then
         s(site:{Value.failed siteNotReachable} connect:NoConnect)
      end
   end

   %% make a connect function for the given site and connection methods
   fun {MakeConnect URI S Meths}
      fun {$ Preferences}
         %% currently ignore user preferences
         for M in Meths   return:Return   default:none do
            try
               case M
               of ["uri" OtherURI] then
                  raise success({ConnectToURI OtherURI Preferences}) end
               [] ["direct"] then
                  raise success({ConnectDirect URI}) end
               [] ["reverse"] then
                  raise success({ConnectReverse URI}) end
               end
            catch success(X) then
               %% this turnaround is necessary because Return is
               %% implemented by raising an exception...
               {Return X}
            [] _ then
               skip          % try next method
            end
         end
      end
   end

   %% "connects" to a failed site
   fun {FailConnect _}
      permFail
   end

   %% "connects" to an unreachable site
   fun {NoConnect _}
      none
   end

   %% connect with a given URI
   fun {ConnectToURI URI Preferences}
      Scheme={String.toAtom {String.token URI &: $ _}}
      Connect={{Property.get 'dp.resolver'}.Scheme URI}.connect
   in
      {Connect Preferences}
   end

   %% ask for a direct connection to the URI
   fun {ConnectDirect URI}
      Sess={GetSession URI} FD0 FD1
   in
      {Sess sendMsg(["connect"])}     % send request: <connect>
      {Sess receiveMsgForce("accept" true)}
      %% accepted: the session can be used as a connection
      {Sess unHook()}
      {Sess getDesc(FD0 FD1)}
      fd(FD0 FD1)
   end

   %% ask for a reverse connection
   fun {ConnectReverse URI}
      if {Property.get 'dp.firewalled'} then ignore else
         Sess={GetSession URI}
      in
         {Sess sendMsg(["reverseConnect" {Site.allURIs {Site.this}}])}
         none
      end
   end

   %% launch site connection server on the current site
   fun {Listen IncomingP}
      Server={New Open.socket init()}
      Params={Property.get 'dp.listenerParams'}
      IP={DoGetIp {Value.condSelect Params ip best}}
      PN={DoBind Server {Value.condSelect Params port 'from'(9000)}}
      ID={Value.condSelect Params id 0}
      Uri={ComposeURI IP PN ID}
      proc {Serve Sess}
         proc {Loop}
            case {Sess receiveMsg($)}
            of ["get" !Uri] then     % receive request <get Uri>
               PSite={Encode {ByteString.toString {Pickle.pack {Site.this}}}}
               Meths=[["direct"] ["reverse"]]
            in
               {Sess sendMsg(["ok" Uri PSite Meths])}     % reply with data
               {Loop}     % ready for next request

            [] ["connect"] then FD0 FD1 in
               {Sess sendMsg("accept")}
               {Sess unHook()}
               {Sess getDesc(FD0 FD1)}
               {Send IncomingP fd(FD0 FD1)}

            [] ["reverseConnect" Uris] then
               for U in Uris   break:Break do
                  try S={Site.resolve U} in
                     {Wait S}
                     {Site.allURIs S _}     % Force connect
                     raise success end
                  catch success then
                     %% this turnaround is necessary because Break
                     %% is implemented by raising an exception...
                     {Break}
                  [] _ then
                     skip          % try next Uri
                  end
               end
            end
         end
      in
         thread
            try
               {Loop}
            catch _ then
               {Sess close}     % protocol error: we simply drop the session
            end
         end
      end
   in
      {Server listen()}
      thread
         %% infinite loop; create a Session for every incoming connection
         for do {Serve {Server accept(accepted:$ acceptClass:Session)}} end
      end
      [Uri]
   end

   %% bind Socket S to a port, following the specification D
   fun{DoBind S D}
      case D
      of 'from'(X) then
         try
            {S bind(takePort:X)} X
         catch _ then
            {DoBind S 'from'(X+1)}
         end
      [] free then
         {S bind(port:$)}
      [] exact(X) then
         {S bind(takePort:X)} X
      end
   end

   %% extract an IP address, following specification D
   fun{DoGetIp D}
      if {String.is D} then D else
         case D
         of exact(Ip) then
            Ip
         [] dns(N) then
            {OS.getHostByName N}.addrList.1
         [] best then
            {BestIp {OS.getHostByName {OS.uName}.nodename}.addrList}
         end
      end
   end

   %% return the best IP address to connect in the list
   fun {BestIp IPs}
      X|T={Map IPs CategorizeIP}
   in
      {FoldL T Best2 X}.2
   end
   fun {Best2 (C1#_)=CIP1 (C2#_)=CIP2}
      if (C2=='global' andthen C1\='global') orelse
         (C2=='private' andthen C1\='global' andthen C1\='private') orelse
         (C2=='local' andthen C1\='global' andthen
          C1\='private' andthen C1\='local') orelse
         (C2=='loopback' andthen C1=='reserved')
      then CIP2 else CIP1 end
   end

   %% adjoin a category to the given IP address, following RFC3330
   fun {CategorizeIP IP}
      (case IP
       of &1|&0|&.|_ then 'private'
       [] &1|&2|&7|&.|_ then 'loopback'
       [] &1|&6|&9|&.|&2|&5|&4|_ then 'local'
       [] &1|&7|&2|&.|T then
          case T
          of &1|&6|&.|_ then 'private'
          [] &1|&7|&.|_ then 'private'
          [] &1|&8|&.|_ then 'private'
          [] &1|&9|&.|_ then 'private'
          [] &2|_|&.|_ then 'private'
          [] &3|&0|&.|_ then 'private'
          [] &3|&1|&.|_ then 'private'
          end
       [] &1|&9|&2|&.|&1|&6|&8|&.|_ then 'private'
       [] &2|&2|&4|&.|_ then 'multicast'
       [] &2|&2|&5|&.|_ then 'multicast'
       [] &2|&2|&6|&.|_ then 'multicast'
       [] &2|&2|&7|&.|_ then 'multicast'
       [] &2|&2|&8|&.|_ then 'multicast'
       [] &2|&2|&9|&.|_ then 'multicast'
       [] &2|&3|_|&.|_ then 'multicast'
       [] &2|&4|_|&.|_ then 'reserved'
       [] &2|&5|_|&.|_ then 'reserved'
       else
          'global'
       end)#IP
   end

   %% compose/decompose a site URI
   fun {ComposeURI IP PN ID}
      {VirtualString.toString 'oz-site://'#IP#':'#PN#'/'#ID}
   end
   fun {DecomposeURI URI}
      IP PN ID in
      {String.token {String.token {List.drop URI PrefixLen} &: IP} &/ PN ID}
      IP#PN#ID
   end
   PrefixLen={Length "oz-site://"}

   %% tell whether the Uri is critical to connect to the site
   fun {IsCritical URI}
      %% it is the case when the site id starts with letter 'h'
      case {DecomposeURI URI}.3 of &h|_ then true else false end
   end

   %% encode/decode a string of bytes
   fun{Encode Xs}
      case Xs
      of nil then nil
      [] H|T then &A+(H div 16)|&a+(H mod 16)|{Encode T}
      end
   end
   fun{Decode Xs}
      case Xs
      of nil then nil
      [] A|B|T then (A-&A)*16+(B-&a)|{Decode T}
      end
   end
end
