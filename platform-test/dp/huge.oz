/*
% This test sends a number of large data structures to remote managers and
% expects them to be returned.
% The goal is to test the suspendable marshaler.
% If the size is set large enough gc of continuations will happen and cause
% more problems than using just fragmented messages
*/

functor
import
   TestMisc
   Compiler
export
   Return
define
   Size=20000
   Sites=1

   proc {Start}
      % Create large values:
   
      % List
      L = {List.number 1 Size 1}
      % VirtualString
      V = {Value.toVirtualString L 1 100000}
      % String
      St = {VirtualString.toString V}
      % Atom
      % HAtom = {VirtualString.toAtom V}
      % Tuple
      Tup = {List.toTuple '#' L}
      % Record
      L2 = {List.make Size}
      {List.forAllInd L2 proc {$ I X} X=I#I end}
      Rec = {List.toRecord rec L2}
      % Array
      % A = {Array.new 1 Size 1}
      % Procedure
      fun {CodeGen N Size}
	 if N=<Size then
	    "{Exchange C _ "#N#"}"#thread{CodeGen N+1 Size}end
	 else "" end
      end
      ProcString="proc{$}"#"C={NewCell 0} in"#{CodeGen 1
					       {Float.toInt
						{Int.toFloat Size}/
						100.0}}#"end"
      Proc={Compiler.evalExpression ProcString env _}
      % Class
      fun {CodeGenClass N Size}
	 if N=<Size then
	    {VirtualString.toAtom "a"#N}#":"#N#" "#thread
						      {CodeGenClass
						       N+1 Size}
						   end
	 else "meth init skip end" end
      end
      ClassString="class $ attr "#{CodeGenClass 1 {Float.toInt
						   {Int.toFloat Size}/
						   100.0}}#" end"
      Cl={Compiler.evalExpression ClassString env _}
      % Object
      Obj={New Cl init}
      % ByteString
      ByteS = {ByteString.make V}
      
      TestValues = [test#test 
		    list#L
		    virtualstring#V
		    string#St
		    %% atom#HAtom
		    tuple#Tup
		    record#Rec
		    %% array#A
		    procedure#Proc 
		    'class'#Cl
		    object#Obj
		    bytestring#ByteS]
      
      Managers
      InP InSCell={NewCell {NewPort $ InP}}
      OutS OutP={NewPort OutS}
      proc {CheckStream S Value Times}
	 if Times > 0 then
	    case S of !Value|Rest then
	       {CheckStream Rest Value (Times-1)}
	    else
	       raise equality_test_failed(S.1 Value) end
	    end
	 else
	    {Assign InSCell S} % Store away where to start with next value...
	 end
      end
   in
      try Hosts in
	 {TestMisc.getHostNames Hosts}
	 {TestMisc.getRemoteManagers Sites Hosts Managers}
	 {ForAll Managers proc {$ RemMan}
			     {StartRemSite RemMan OutS InP}
			  end}
	 {ForAll TestValues proc {$ Lable#X}
			       try
				  {Send OutP X}			       
				  {CheckStream {Access InSCell}
				   X {List.length Managers}}
			       catch Ex then
				  raise failed(Lable Ex) end
			       end
			    end}
      catch X then
	 {TestMisc.gcAll Managers}
	 {TestMisc.listApply Managers close}
	 raise X end
      end
      {TestMisc.gcAll Managers}
      {TestMisc.listApply Managers close}
   end

   proc {StartRemSite Manager InS OutP}
      {Manager apply(url:'' functor
			    import
			       Property(put)
			       System(gcDo)
			    define
			       {Property.put 'close.time' 1000}
			       thread
				  for X in InS do {Wait X} {Send OutP X} end
			       end
			       %% kost@ : keep that idiot doing also GC;
			       thread P in
				  proc {P} {System.gcDo} {Delay 500} {P} end
				  {P}
			       end
			    end)}
   end

   Return = dp([huge(Start keys:[remote])])
end
