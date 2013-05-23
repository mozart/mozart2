functor
import
   Run(bench) at 'run.ozf'
   Open(file)
define
   Options = ['file'( single type:string)
	      'chunk'(single type:int default:1024)]
   Help =
   'measures the speed of copying a file across site.\n\n'#
   '--file=PATH\n'#
   '\tfile to be copied\n\n'#
   '--chunk=N\n'#
   '\tread and send in chunks of N bytes\n\n'

   proc {WHAT Args MSG LocalDO RemoteFUNCTOR}
      File = Args.file
      Size = Args.chunk
   in
      proc {LocalDO Stream}
	 P = {NewPort Stream}
	 F = {New Open.file init(name:File flags:[read])}
	 Done
	 proc {AllDone L}
	    case L
	    of eof|_ then Done=unit
	    [] ok |L then {AllDone L} end
	 end
	 P2
	 thread {AllDone {NewPort $ P2}} end
	 proc {Loop}
	    Bytes = {F read(list:$ size:Size)}
	    OK
	 in
	    {Send P {ByteString.make Bytes}#OK}
	    {Send P2 OK}
	    if Bytes\=nil then {Loop} end
	 end
      in
	 try {Loop} finally {F close} end
	 {Wait Done}
      end

      functor RemoteFUNCTOR
      import OS(tmpnam unlink) Open(file)
      export Do
      define
	 {Wait OS.tmpnam}
	 {Wait Open.file}
	 proc {Do Stream}
	    Path = {OS.tmpnam}
	    File = {New Open.file init(name:Path flags:[create write])}
	    proc {Process Bytes#OK}
	       if {ByteString.width Bytes}==0 then
		  OK=eof
		  raise eof end
	       else
		  {File write(vs:Bytes)}
		  thread OK=ok end
	       end
	    end
	 in
	    try
	       {ForAll Stream Process}
	    catch eof then skip
	    finally
	       {File close}
	       {OS.unlink Path}
	    end
	 end
      end
   end

   {Run.bench Options Help WHAT}
end
