%%%
%%% Author:
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

   local
      \insert 'HtmlTable.oz'

      fun {GetOptions As N ?M}
         case As of nil then M=N nil
         [] A|Ar then
            if {IsInt A} then {GetOptions Ar N+1 M}
            else M=N As
            end
         end
      end

      fun {BuildOptions As Tag}
         case As of nil then ''
         [] A|Ar then ' '#A#'="'#Tag.A#'"'#{BuildOptions Ar Tag}
         end
      end

      fun {TagBody I Tag}
         if I>0 then {TagBody I-1 Tag}#{Tag2Vs Tag.I} else '' end
      end
   in
      fun {Tag2Vs Tag}
         if {IsTuple Tag} then L={Label Tag} in
            if {HtmlTable.isTag L} then
               '<'#L#'>'#{TagBody {Width Tag} Tag}#
               if {HtmlTable.isNonFinalTag L} then '' else
                  '</'#L#'>'
               end
            elseif L=='#' then {Record.map Tag Tag2Vs}
            else Tag
            end
         elseif {IsRecord Tag} then L={Label Tag} in
            if {HtmlTable.isTag L} then
               N As={GetOptions {Arity Tag} 0 ?N}
            in
               '<'#L#{BuildOptions As Tag}#'>' #
               {TagBody N Tag} #
               if {HtmlTable.isNonFinalTag L} then '' else
                  '</'#L#'>'
               end
            else Tag
            end
         elseif {IsProcedure Tag} then {Tag2Vs {Tag}}
         else Tag
         end
      end
   end


   ReadSize    = 1024
   ReadSizeAll = 4096
   KillTime    = 500

   %%
   %% Attributes and Methods common to all open classes
   %%
   InitLocks   = {NewName}
   CloseDescs  = {NewName}
   ReadLock    = {NewName}
   WriteLock   = {NewName}
   ReadDesc    = {NewName}
   WriteDesc   = {NewName}
   Buff        = {NewName}
   Last        = {NewName}
   AtEnd       = {NewName}
   TimeOut     = {NewName}
   Missing     = {NewName}
   NoArg = {NewName}

   local
      %% Some records for mapping various descriptions to OS specs
      ModeMap=map(owner:  access(read:    ['S_IRUSR']
                                 write:   ['S_IWUSR']
                                 execute: ['S_IXUSR'])
                  group:  access(read:    ['S_IRGRP']
                                 write:   ['S_IWGRP']
                                 execute: ['S_IXGRP'])
                  others: access(read:    ['S_IROTH']
                                 write:   ['S_IWOTH']
                                 execute: ['S_IXOTH'])
                  all:    access(read:    ['S_IRUSR' 'S_IRGRP' 'S_IROTH']
                                 write:   ['S_IWUSR' 'S_IWGRP' 'S_IWOTH']
                                 execute: ['S_IXUSR' 'S_IXGRP' 'S_IXOTH']))
   in
      fun {ModeToOS Mode}
         {Record.foldLInd Mode
          fun {$ Cat In What}
             {FoldL What
              fun {$ In Access}
                 if In==false then false
                 elseif
                    {HasFeature ModeMap Cat} andthen
                    {HasFeature ModeMap.Cat Access}
                 then {Append ModeMap.Cat.Access In}
                 else false
                 end
              end In}
          end nil}
      end
   end

   local
      FlagMap = map(append:   'O_APPEND'
                    'create': 'O_CREAT'
                    truncate: 'O_TRUNC'
                    exclude:  'O_EXCL'
                    text:     'O_TEXT'
                    binary:   'O_BINARY')
   in
      fun {FlagsToOS FlagS}
         {FoldL FlagS
          fun {$ In Flag}
             if In==false then false
             elseif Flag==read orelse Flag==write then In
             elseif {HasFeature FlagMap Flag} then FlagMap.Flag|In
             else false
             end
          end
          [if {Member read FlagS} andthen {Member write FlagS} then
              'O_RDWR'
           elseif {Member write FlagS} then 'O_WRONLY'
           else 'O_RDONLY'
           end]}
      end
   end


in

   functor

   import
      OS(open
         fileDesc
         close
         write
         read
         lSeek
         socket
         bind
         listen
         connect
         accept
         shutDown
         send
         sendTo
         receiveFrom
         receiveFromAnon
         getSockName
         acceptSelect
         deSelect
         pipe
         wait
         kill
        )

      Error(registerFormatter)
      ZlibIO(compressedFile:CompressedFile) at 'x-oz://system/ZlibIO.ozf'

      Resolve(open)

   export
      file:   File
      text:   Text
      socket: Socket
      pipe:   Pipe
      html:   Html
      compressedFile: CompressedFile

   define

      %%
      %% Exception handling
      %%
      proc {RaiseClosed S M}
         {Raise {Exception.system open(alreadyClosed S M)}}
      end

      %%
      %% The common base-class providing for descriptor manipulation
      %%
      fun {DoWrite D V M}
         case {OS.write D V}
         of suspend(N S V) then {Wait S} {DoWrite D V N+M}
         elseof N then N+M
         end
      end

      fun {DoReadAll Desc ?Xs Xt N}
         Ys Xr
      in
         case {OS.read Desc ReadSizeAll Ys Xr}
         of 0 then
            Xs = Ys
            Xr = Xt
            N
         elseof M then
            Xs = Ys
            {DoReadAll Desc Xr Xt N+M}
         end
      end

      class DescClass
         prop
            sited
         feat
            !ReadLock
            !WriteLock
         attr
            !ReadDesc:    false  % Not yet initialized (true = closed, int ...)
            !WriteDesc:   false  % Not yet initialized (true = closed, int ...)
            !Buff:        nil    % The buffer is empty
            !Last:        [0]    % The last char read is initialized to nul
            !AtEnd:       false  % Reading is not at end!

         meth !InitLocks(M)
            %% Initialize locks
            try
               self.ReadLock  = {NewLock}
               self.WriteLock = {NewLock}
            catch failure(debug:_) then
               {Raise {Exception.system open(alreadyInitialized self M)}}
            end
         end

         meth dOpen(RD WD)
            DescClass, InitLocks(dOpen(RD WD))
            ReadDesc  <- RD
            WriteDesc <- WD
         end

         meth getDesc(?RD ?WD)
            lock self.ReadLock then
               lock self.WriteLock then
                  RD = @ReadDesc
                  WD = @WriteDesc
               end
            end
         end

         meth !CloseDescs
            lock self.ReadLock then
               lock self.WriteLock then
                  RD=@ReadDesc WD=@WriteDesc
               in
                  if {IsInt RD} then
                     {OS.deSelect RD} {OS.close RD}
                     if RD\=WD then
                        {OS.deSelect WD} {OS.close WD}
                     end
                     ReadDesc  <- true
                     WriteDesc <- true
                  end
               end
            end
         end
      end


      %%
      %% The File Object
      %%

      class File from DescClass

         meth init(name:  Name  <= NoArg
                   url:   Url   <= NoArg
                   flags: FlagS <= [read]
                   mode:  Mode  <= mode(owner:[write] all:[read])) = M
            DescClass, InitLocks(M)
            %% Handle read&write flags
            case {FlagsToOS FlagS}
            of false then {Raise {Exception.system
                                  open(illegalFlags self M)}}
            elseof OSFlagS then
               %% Handle access modes
               case {ModeToOS Mode}
               of false then {Raise {Exception.system
                                     open(illegalModes self M)}}
               elseof OSModeS then
                  %% Handle special filenames
                  if
                     (Name==NoArg andthen Url==NoArg) orelse
                     (Name\=NoArg andthen Url\=NoArg)
                  then
                     {Raise {Exception.system
                             open(nameOrUrl self M)}}
                     else
                     D = case Name
                         of 'stdin'  then {OS.fileDesc 'STDIN_FILENO'}
                         [] 'stdout' then {OS.fileDesc 'STDOUT_FILENO'}
                         [] 'stderr' then {OS.fileDesc 'STDERR_FILENO'}
                         [] !NoArg then
                            if
                               {Member 'O_RDWR'   OSFlagS} orelse
                               {Member 'O_WRONLY' OSFlagS}
                            then
                               {Raise {Exception.system
                                       open(urlIsReadOnly self M)}}
                               _
                            else {Resolve.open Url}
                            end
                         else
                            {OS.open Name OSFlagS OSModeS}
                         end
                  in
                     ReadDesc  <- D
                     WriteDesc <- D
                  end
               end
            end
         end

         meth read(size:Size <=ReadSize
                   list:?Is  tail:It<=nil len:?N<=_)
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  if {IsInt D} then
                     case Size of all then
                        N = {DoReadAll D ?Is It 0}
                     else NL IsL in
                        NL = {OS.read D Size ?IsL It}
                        N = NL
                        Is = IsL
                     end
                  else
                     {RaiseClosed self
                      read(size:Size list:Is tail:It len:N)}
                  end
               end
            end
         end

         meth write(vs:V len:I<=_)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  if {IsInt D} then I={DoWrite D V 0}
                  else {RaiseClosed self write(vs:V len:I)}
                  end
               end
            end
         end

         meth seek(whence:W<='set' offset:O<=0)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  if {IsInt D} then
                     {OS.lSeek D O case W
                                   of 'set'     then 'SEEK_SET'
                                   [] 'current' then 'SEEK_CUR'
                                   [] 'end'     then 'SEEK_END'
                                   end _}
                  else {RaiseClosed self seek(whence:W offset:O)}
                  end
               end
            end
         end

         meth tell(offset:?O)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  if {IsInt D} then O={OS.lSeek D 0 'SEEK_CUR'}
                  else {RaiseClosed self tell(offset:O)}
                  end
               end
            end
         end

         meth close
            DescClass, CloseDescs
         end
      end


      %%
      %% Sockets and Pipes
      %%

      class SockAndPipe from DescClass
         meth read(size: Size <= ReadSize
                   len:  Len  <= _
                   list: List
                   tail: Tail <= nil)
            lock self.ReadLock then D=@ReadDesc in
               if {IsInt D} then
                  case Size of all then
                     Len = {DoReadAll D ?List Tail 0}
                  else ListL LenL in
                     LenL = {OS.read D Size ?ListL Tail}
                     Len = LenL
                     List = ListL
                  end
               else {RaiseClosed self
                     read(size:Size len:Len list:List tail:Tail)}
               end
            end
         end

         meth write(vs:V len:I<=_)
            lock self.WriteLock then D=@WriteDesc in
               if {IsInt D} then I={DoWrite D V 0}
               else {RaiseClosed self write(vs:V len:I)}
               end
            end
         end

         meth flush(how:How<=[receive send])
            R = {Member receive How}
            S = {Member send    How}
         in
            if R andthen S then
               lock self.ReadLock then
                  lock self.WriteLock then skip end
               end
            elseif R then
               lock self.ReadLock then skip end
            elseif S then
               lock self.WriteLock then skip end
            end
         end
      end

      local
         fun {DoSend D V M}
            case {OS.send D V nil}
            of suspend(N S V) then {Wait S} {DoSend D V N+M}
            elseof N then N+M
            end
         end

         fun {DoSendTo Desc V Host Port M}
            case {OS.sendTo Desc V nil Host Port}
            of suspend(N S V) then {Wait S} {DoSendTo Desc V Host Port N+M}
            elseof N then N+M
            end
         end
      in

         class Socket
            from SockAndPipe
               %% Implementation of socket
            feat !TimeOut

            meth init(type:T <=stream protocol:P <= nil time:Time <=~1) = M
               DescClass, InitLocks(M)
               D = {OS.socket 'PF_INET' case T
                                        of 'stream'   then 'SOCK_STREAM'
                                        [] 'datagram' then 'SOCK_DGRAM'
                                        end P}
            in
               self.TimeOut = Time
               ReadDesc  <- D
               WriteDesc <- D
            end

            meth server(port:OP<=_ host:H<=_ ...) = M
               P
            in
               Socket, init
               if {HasFeature M takePort} then
                  Socket, bind(port:P takePort:M.takePort)
               else
                  Socket, bind(port:P)
               end
               Socket, listen(backLog:1)
               P=OP
               Socket, accept(host:H)
            end

            meth client(host:H<='localhost' port:P)
               Socket, init
               Socket, connect(host:H port:P)
            end

            meth listen(backLog:Log<=5)
               lock self.ReadLock then
                  lock self.WriteLock then D=@ReadDesc in
                     if {IsInt D} then {OS.listen D Log}
                     else {RaiseClosed self listen(backLog:Log)}
                     end
                  end
               end
            end

            meth bind(port:P <= _ ...) = M
               lock self.ReadLock then
                  lock self.WriteLock then D=@ReadDesc in
                     if {IsInt D} then
                        P = if {HasFeature M takePort} then
                               {OS.bind D M.takePort}
                               M.takePort
                            else %% Generate port
                               {OS.bind D 0}
                               {OS.getSockName D}
                            end
                     else {RaiseClosed self M}
                     end
                  end
               end
            end

            meth accept(host:H <=_ port:P <=_ ...) = M
               lock self.ReadLock then
                  lock self.WriteLock then D=@ReadDesc in
                     if {IsInt D} then
                        TimeAcc = case self.TimeOut of ~1 then _
                                  elseof TO then {Alarm TO}
                                  end
                        WaitAcc = thread
                                     {OS.acceptSelect D}
                                     unit
                                  end
                     in
                        {WaitOr TimeAcc WaitAcc}
                        if {IsDet WaitAcc} then
                           AD={OS.accept D H P}
                        in
                           if {HasFeature M accepted} then
                              %% Create new Socket Object
                              M.accepted = {New M.acceptClass dOpen(AD AD)}
                           else
                              DescClass, CloseDescs
                              ReadDesc  <- AD
                              WriteDesc <- AD
                           end
                        else P=false H=false
                        end
                     else {RaiseClosed self M}
                     end
                  end
               end
            end

            meth connect(host:H<='localhost' port:P)
               lock self.ReadLock then
                  lock self.WriteLock then D=@ReadDesc in
                     if {IsInt D} then {OS.connect D H P}
                     else {RaiseClosed self connect(host:H port:P)}
                     end
                  end
               end
            end

            meth send(vs:V len:I<=_ port:P<=Missing host:H<='localhost')
               lock self.WriteLock then D=@WriteDesc in
                  if {IsInt D} then
                     I = if P\=Missing then {DoSendTo D V H P 0}
                         else {DoSend D V 0}
                         end
                  else {RaiseClosed self send(vs:V len:I port:P host:H)}
                  end
               end
            end

            meth receive(list:List  tail:Tail <= nil  len:Len<=_
                         size:Size<=ReadSize
                         host:Host<=Missing port:Port<=Missing)
               lock self.ReadLock then D=@ReadDesc in
                  if {IsInt D} then
                     if {IsDet Host} andthen Host==Missing andthen
                        {IsDet Port} andthen Port==Missing then
                        Len={OS.receiveFromAnon D Size nil List Tail}
                     else
                        RealHost = if {IsDet Host} andthen Host==Missing then _
                                   else Host
                                   end
                        RealPort = if {IsDet Port} andthen Port==Missing then _
                                   else Port
                                   end
                     in
                        Len={OS.receiveFrom D Size nil List Tail
                                            RealHost RealPort}
                     end
                  else {RaiseClosed self
                        receive(list:List tail:Tail len:Len
                                size:Size host:Host port:Port)}
                  end
               end
            end

            %% methods for closing a connection
            meth shutDown(how:How<=[receive send])
               R = {Member receive How}
               S = {Member send    How}
            in
               if R andthen S then
                  lock self.ReadLock then
                     lock self.WriteLock then
                        RD=@ReadDesc WD=@WriteDesc
                     in
                        if {IsInt RD} andthen {IsInt WD} then
                           if RD==WD then {OS.shutDown WD 2}
                           else
                              {OS.shutDown RD 0}
                              {OS.shutDown WD 1}
                           end
                        else {RaiseClosed self shutDown(how:How)}
                        end
                     end
                  end
               elseif R then
                  lock self.ReadLock then D=@ReadDesc in
                     if {IsInt D} then {OS.shutDown D 0}
                     else {RaiseClosed self shutDown(how:How)}
                     end
                  end
               elseif S then
                  lock self.WriteLock then D=@WriteDesc in
                     if {IsInt D} then {OS.shutDown D 1}
                     else {RaiseClosed self shutDown(how:How)}
                     end
                  end
               end
            end
            meth close
               DescClass, CloseDescs
            end
         end

      end


      %%
      %% Object for reading and writing of lines of text
      %%

      local
         fun {DoReadLine Is Desc ?UnusedIs ?AtEnd}
            case Is
            of I|Ir then
               case I of &\n then UnusedIs=Ir AtEnd=false nil
               else I|{DoReadLine Ir Desc ?UnusedIs ?AtEnd}
               end
            [] nil then Is in
               case {OS.read Desc ReadSize Is nil}
               of 0 then UnusedIs=nil AtEnd=true nil
               else {DoReadLine Is Desc ?UnusedIs ?AtEnd}
               end
            end
         end

         fun {DoReadOne Is Desc ?UnusedIs ?AtEnd}
            case Is
            of I|Ir then UnusedIs=Ir AtEnd=false I
            [] nil then Is in
               case {OS.read Desc ReadSize Is nil}
               of 0 then UnusedIs=nil AtEnd=true false
               else {DoReadOne Is Desc ?UnusedIs ?AtEnd}
               end
            end
         end

      in

         class Text from DescClass

            meth getC(?I)
               lock self.ReadLock then
                  YetEnd  = @AtEnd  NextEnd
                  YetBuff = @Buff   NextBuff
                  YetLast = @Last   NextLast
                  GetDesc = @ReadDesc
               in
                  if {IsInt GetDesc} then
                     AtEnd <- NextEnd
                     Buff  <- NextBuff
                     Last  <- NextLast
                     if YetEnd then
                        I=false
                        NextEnd=true NextBuff=nil NextLast=YetLast
                     else
                        I={DoReadOne YetBuff GetDesc NextBuff NextEnd}
                        NextLast=I
                     end
                  else {RaiseClosed self getC(I)}
                  end
               end
            end

            meth putC(I)
               {self write(vs:[I])}
            end

            meth getS(Result)
               lock self.ReadLock then
                  YetEnd  = @AtEnd  NextEnd
                  YetBuff = @Buff   NextBuff
                  GetDesc = @ReadDesc
               in
                  if {IsInt GetDesc} then
                     AtEnd <- NextEnd
                     Buff  <- NextBuff
                     Result = if YetEnd then
                                 NextEnd=true NextBuff=nil
                                 false
                              else
                                 It={DoReadLine YetBuff GetDesc
                                     NextBuff NextEnd}
                              in
                                 if NextEnd then
                                    case It of nil then false else It end
                                 else It
                                 end
                              end
                  else {RaiseClosed self getS(Result)}
                  end
               end
            end

            meth putS(Is)
               {self write(vs:Is#'\n')}
            end

            meth unGetC
               lock self.ReadLock then
                  Buff  <- @Last|@Buff
                  Last  <- [0]
                  AtEnd <- false
               end
            end

            meth atEnd($)
               lock self.ReadLock then
                  @Buff==nil andthen @AtEnd
               end
            end
         end
      end

      %%
      %% The pipe object
      %%


      class Pipe from SockAndPipe
         feat PID

         meth init(cmd:Cmd args:ArgS<=nil pid:Pid<=_) = M
            DescClass, InitLocks(M)
            RD#WD = {OS.pipe Cmd ArgS ?Pid}
         in
            self.PID = Pid
            ReadDesc  <- RD
            WriteDesc <- WD
         end

         meth Kill(SIG)
            {OS.kill self.PID SIG _}
            %% Ignore errors, since process may be killed anyway
            {Delay KillTime}
            {OS.wait _ _}
            {OS.wait _ _}
         end

         meth close(DoKill <= false)
            if DoKill then
               Pipe,Kill('SIGKILL')
            end
            lock self.ReadLock then
               lock self.WriteLock then
                  if DoKill then skip else
                     Pipe,Kill('SIGTERM')
                  end
                  DescClass, CloseDescs
               end
            end
         end
      end


      class Html
         meth header
            {self write(vs:'Content-type: text/html\n\n')}
         end

         meth tag(Tag)
            {self write(vs:{Tag2Vs Tag})}%
         end
      end

      %%
      %% Error formatting
      %%

      {Error.registerFormatter open
       fun {$ E}
          T = 'error in Open module'
       in
          case E
          of open(What O M) then
             %% expected What: atom, O: object
             error(kind: T
                   msg: case What
                        of alreadyClosed then
                           'Object already closed'
                        [] alreadyInitialized then
                           'Object already initialized'
                        [] illegalFlags then
                           'Illegal value for flags'
                        [] illegalModes then
                           'Illegal value for mode'
                        [] nameOrUrl then
                           'Exactly one of \'name\' or \'url\' feature needed'
                        [] urlIsReadOnly then
                           'Only reading access to url-files allowed'
                        else 'Unknown' end
                   items: [hint(l:'Object Application'
                                m:'{' # oz(O) # ' ' # oz(M) # '}')])
          else
             error(kind: T
                   items: [line(oz(E))])
          end
      end}

   end

end
