%%
%% CgiParser (Christian Schulte)
%%

local
   local
      OpenFile = Open.file
      class StdIn
         from OpenFile
         prop final
         meth init
            OpenFile,dOpen(0 1)
         end
         meth get(N ?Is)
            Ir M=StdIn,read(list:?Is tail:?Ir size:N len:$)
         in
            Ir = case M<N then StdIn,get(N-M $)
                 else nil
                 end
         end
      end
   in
      fun {CgiGet}
         case {String.toAtom {Getenv 'REQUEST_METHOD'}}
         of 'GET' then {Getenv 'QUERY_STRING'}
         [] 'POST' then F in
            try
               F={New StdIn init}
               {F get({String.toInt {Getenv 'CONTENT_LENGTH'}} $)}
            finally
               {F close}
            end
         end
      end
   end

   local
      fun {Replace Is C1 C2}
         case Is of nil then nil
         [] I|Ir then
            case I==C1 then C2|{Replace Ir C1 C2}
            else I|{Replace Ir C1 C2}
            end
         end
      end

      local
         fun {HexDigit D}
            case {Char.isUpper D} then D-&A+10
            elsecase {Char.isLower D} then D-&a+10
            else D-&0
            end
         end
      in
         fun {HexReplace Is}
            case Is of nil then nil
            [] I|Ir then
               case I==&% then
                  case Ir
                  of D1|D2|Ir then NewI={HexDigit D1}*16+{HexDigit D2} in
                     case NewI>255 then 0 else NewI end|{HexReplace Ir}
                  else I|{HexReplace Ir}
                  end
               else I|{HexReplace Ir}
               end
            end
         end
      end
   in
      fun {CgiParse Is}
         {Map {String.tokens Is &&}
          fun {$ S}
             S1 S2
          in
             {String.token {HexReplace {Replace S &+ & }} &= ?S1 ?S2}
             {String.toAtom S1}#S2
          end}
      end
   end

   fun {ToSingle AVs}
      D={Dictionary.new}
   in
      {ForAll AVs proc {$ A#V}
                     {Dictionary.put D A V}
                  end}
      {Dictionary.toRecord args D}
   end

   fun {ToMultiple AVs}
      D={Dictionary.new}
   in
      {ForAll AVs proc {$ A#V}
                     {Dictionary.put D A V|{Dictionary.condGet D A nil}}
                  end}
      {Dictionary.toRecord args D}
   end

in


   fun {MakeCgiParser Kind}
      case Kind
      of plain then
         CgiGet
      [] single then
         fun {$}
            {ToSingle {CgiParse {CgiGet}}}
         end
      [] multiple then
         fun {$}
            {ToMultiple {CgiParse {CgiGet}}}
         end
      [] list then
         fun {$}
            {CgiParse {CgiGet}}
         end
      end
   end
end
