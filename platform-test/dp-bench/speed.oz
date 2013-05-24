functor
import
   Run(bench) at 'run.ozf'
define
   Options = ['width'(   single type:int default:2)
	      'depth'(   single type:int default:0)
	      'messages'(single type:int default:1)]

   Help =
   'measures the speed of message exchange between sites.\n'#
   'there is a local consumer and a remote producer.  they\n'#
   'communicate though a stream.  The consumer requests the\n'#
   'next message and the producer then produces it and waits\n'#
   'for the next request.\n\n'#
   '--width=N\n'#
   '\tcontrols the width of records in the message\n\n'#
   '--depth=N\n'#
   '\tcontrols the nesting depth of records in the message\n\n'#
   '--messages=N\n'#
   '\tN messages will be produced\n\n'

   proc {Consumer N L}
      if N>0 then H T in
	 L = H|T
	 {Wait H}
	 {Consumer N-1 T}
      else
	 L=nil
      end
   end

   proc {WHAT Args MSG LocalDO RemoteFUNCTOR}
      {MSG 'Computing message value'}
      Dummy = {List.number 1 Args.width 1}
      fun {MakeValue Depth}
	 if Depth==0 then unit else
	    {List.toTuple msg
	     {Map Dummy fun {$ _} {MakeValue Depth-1} end}}
	 end
      end
      Message = {MakeValue Args.width}
      proc {Producer L}
	 {ForAll L proc {$ X} X=Message end}
      end
   in
      proc {LocalDO Stream}
	 {Consumer Args.messages Stream}
      end

      functor RemoteFUNCTOR
      export Do
      define Do=Producer
      end
   end

   {Run.bench Options Help WHAT}
end
