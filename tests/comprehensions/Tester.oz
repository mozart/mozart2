functor
import
   System
   OS
export
   test:              TestSeveral
   testLazy:          TestLazy
   browse:            Browse1
   memory:            MemoryTaken
define
   Browse1 = System.show
   Browse2 = System.print
   %% prints final result of test
   proc {PrintResult G B}
      if B \= 0 then
         {Browse1 {VirtualString.toAtom G#' tests successfully passed.'}}
         {Browse1 {VirtualString.toAtom B#' tests failed.'}}
      else
         {Browse1 {VirtualString.toAtom 'All tests ('#G#') successfully passed.'}}
      end
   end
   %% test all the elements of the list using SimpleAssert
   proc {TestSeveral List}
      proc {Aux L G B}
         case L
         of nil then {PrintResult G B}
         [] TR#Ex|T then
            if {SimpleAssert TR Ex G+B+1} then
               {Aux T G+1 B}
            else
               {Aux T G B+1}
            end
         end
      end
   in
      {Aux List 0 0}
   end
   %% test the equality of its first two arguments
   %% displays error message if not equal
   %% return true iff equal
   fun {SimpleAssert TestResult Expected Index}
      if TestResult \= Expected then
         {Browse1 {VirtualString.toAtom '----------------------------'}}
         {Browse1 {VirtualString.toAtom 'Error in test '#Index}}
         {Browse2 'Expecting: '}{Browse1 Expected}
         {Browse2 'Getting:   '}{Browse1 TestResult}
         {Browse1 {VirtualString.toAtom '----------------------------'}}
         false
      else
         true
      end
   end
   %% test all the elements of the list for lazy input
   proc {TestLazy List}
      proc {Aux L G B}
         case L
         of nil then {PrintResult G B}
         [] TR#Ex#N|T then Good in
            for I in 1 ; I=<{Length Ex} ; I+N do
               if {LazyAssert TR Ex G+B+1 I N} then
                  skip
               else
                  Good = unit
               end
            end
            if {IsDet Good} then
               {Aux T G B+1}
            else
               {Aux T G+1 B}
            end
         end
      end
   in
      {Aux List 0 0}
   end
   %% lazy assert
   fun {LazyAssert TestResult Expected Index B N}
      if {IsDet {Nth TestResult B}} then {Browse1 'Lazy error'} false
      else
         local
            Bad
         in
            for I in B..B+N-1 do
               if {Nth TestResult I} \= {Nth Expected I} then
                  {Browse1 {VirtualString.toAtom '----------------------------'}}
                  {Browse1 {VirtualString.toAtom 'Error in lazy test '#Index}}
                  {Browse2 'Expecting: '}{Browse1 Expected}
                  {Browse2 'Getting:   '}{Browse1 TestResult}
                  {Browse1 {VirtualString.toAtom '----------------------------'}}
                  Bad = unit
               end
            end
            {Not {IsDet Bad}}
         end
      end
   end
   %% Returns the memory taken by process Pid in Bytes
   fun {MemoryTaken Pid}
      Pipe
      Read
      {OS.pipe "top" ["-pid" ""#Pid  "-l" "1" "-stats" "mem"] _ Pipe}
      {OS.read Pipe.1 1000 Read nil _}
      proc {Aux List NL ?Next}
         if NL < 12 then
            case List
            of &\n|Tail then
               {Aux Tail NL+1 Next}
            [] _|Tail then
               {Aux Tail NL Next}
            end
         else
            case List
            of &\n|_ then
               Next = nil
            [] H|Tail then N in
               Next = H|N
               {Aux Tail NL N}
            end
         end
      end
      fun {Clean Mem}
         M = {Reverse Mem}
         fun {Aux L Mul Acc}
            case L
            of nil then Acc
            [] H|T then
               case H
               of &+ then
                  {Aux T Mul Acc}
               [] &K then
                  {Aux T 1000 Acc}
               [] &M then
                  {Aux T 1000000 Acc}
               [] &G then
                  {Aux T 1000000000 Acc}
               else
                  {Aux T Mul*10 Acc+Mul*(H-&0)}
               end
            end
         end
      in
         {Aux M 1 0}
      end
   in
      {Clean {Aux Read 0}}
   end
end