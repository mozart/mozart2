functor
export
   CompressedFile
import
   ZLIBIO(
      is             : ZIs
      new            : ZNew
      close          : ZClose
      readByteString : ZReadByteString
      read           : ZRead
      write          : ZWrite
      flush          : ZFlush
      )
   at 'x-oz://boot/ZlibIO.so{native}'
   Open(file:File)
prepare
   NoArg = {NewName}
   RaiseError = Exception.raiseError
   ListToRecord = List.toRecord
   ReadSize    = 1024
   ReadSizeAll = 4096
define

   proc {DoReadAll ZFile Head Tail LenSofar LenTotal}
      Mid N
   in
      {ZRead ZFile ReadSize Head Mid N}
      if N==0 then
         Mid=Tail LenTotal=LenSofar {ZClose ZFile}
      else
         {DoReadAll ZFile Mid Tail LenSofar+N LenTotal}
      end
   end

   proc {DoWrite ZFile VS Sofar Total}
      case {ZWrite ZFile VS}
      of suspend(N S V) then {Wait S} {DoWrite ZFile V Sofar+N Total}
      elseof N then Total=Sofar+N end
   end

   class CompressedFile
      prop locking
      attr ZFile
      meth init(name : Name  <= NoArg
                url  : Url   <= NoArg
                flags: Flags <= nil
                mode : Mode  <= NoArg)
         ReadFlag WriteFlag CompressionFlag FilteredFlag HuffmanFlag
         OpenFlags =
         for X in Flags collect:Collect do
            if {IsInt X} then
               if {IsDet CompressionFlag} then
                  if X\=CompressionFlag then
                     {RaiseError zlib(compression:clash(CompressionFlag X))}
                  end
               elseif X<0 orelse X>9 then
                  {RaiseError zlib(compression:bad(X))}
               else CompressionFlag=X end
            elsecase X
            of filtered then
               if {IsDet HuffmanFlag} then
                  {RaiseError zlib(strategy:clash(huffman filtered))}
               else FilteredFlag=true end
            [] huffman  then
               if {IsDet FilteredFlag} then
                  {RaiseError zlib(strategy:clash(filtered huffman))}
               else HuffmanFlag=true end
            [] read   then
               if {IsDet WriteFlag} then
                  {RaiseError zlib(readwrite)}
               else {Collect X} ReadFlag=true end
            [] write  then
               if {IsDet ReadFlag} then
                  {RaiseError zlib(readwrite)}
               else {Collect X} WriteFlag=true end
            [] append then
               if {IsDet ReadFlag} then
                  {RaiseError zlib(readwrite)}
               else {Collect X} WriteFlag=true end
            else {Collect X} end
         end
         ZMode =
         if {IsDet WriteFlag} then "wb" else "rb" end #
         if {IsDet CompressionFlag} then CompressionFlag else nil end #
         if {IsDet FilteredFlag} then "f"
         elseif {IsDet HuffmanFlag} then "h" else nil end
         L0 = nil
         L1 = if Name==NoArg then L0 else (name#Name)|L0 end
         L2 = if Url==NoArg then L1 else (url#Url)|L1 end
         L3 = if OpenFlags==nil then L2 else (flags#OpenFlags)|L2 end
         L4 = if Mode==NoArg then L3 else (mode#Mode)|L3 end
         InitMsg = {ListToRecord 'init' L4}
         FileObj = {New File InitMsg}
         FileFD = if {IsDet WriteFlag} then
                     {FileObj getDesc(_ $)}
                  else
                     {FileObj getDesc($ _)}
                  end
      in
         ZFile <- {ZNew FileFD ZMode}
      end

      meth close()
         {ZClose @ZFile}
      end

      meth read(size:Size <= ReadSize
                list:Head
                tail:Tail <= nil
                len :Len  <= _)
         lock
            case Size of 'all' then
               {DoReadAll @ZFile Head Tail 0 Len}
            else
               {ZRead @ZFile Size Head Tail Len}
            end
         end
      end

      meth readByteString(size:Size <= ReadSize $)
         {ZReadByteString @ZFile Size $ _}
      end

      meth write(vs:VS len:I<=_)
         lock
            {DoWrite @ZFile VS 0 I}
         end
      end

      meth flush(V<=full)
         {ZFlush @ZFile
          case V
          of none   then 0
          [] sync   then 2
          [] full   then 3
          [] finish then 4
          end}
      end
   end
end
