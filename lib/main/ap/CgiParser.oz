%%
%% CgiParser (Christian Schulte)
%%

local
   local
      class StdIn
         from Open.file
         prop final
         meth init
            Open.file,dOpen(0 1)
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
         case {String.toAtom {OS.getEnv 'REQUEST_METHOD'}}
         of 'GET' then {OS.getEnv 'QUERY_STRING'}
         [] 'POST' then F in
            try
               F={New StdIn init}
               {F get({String.toInt {OS.getEnv 'CONTENT_LENGTH'}} $)}
            finally
               {F close}
            end
         end
      end
   end

   local
      local
         fun {Do Is C Js Jr F}
            case Is of nil then Jr=nil
               case Js of nil then nil else [{F Js}] end
            [] I|Ir then
               case I==C then NewJs in
                  Jr=nil {F Js}|{Do Ir C NewJs NewJs F}
               else NewJr in
                  Jr=I|NewJr {Do Ir C Js NewJr F}
               end
            end
         end
      in
         fun {Split S C F}
            Ss in {Do S C Ss Ss F}
         end
      end

      local
         fun {Do Is C Js Jr}
            case Is of nil then Jr=nil
               case Js of nil then nil else [Js] end
            [] I|Ir then
               case I==C then Jr=nil [Js Ir]
               else NewJr in
                  Jr=I|NewJr {Do Ir C Js NewJr}
               end
            end
         end
      in
         fun {SplitFirst S C}
            Ss in {Do S C Ss Ss}
         end
      end

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
         {Split Is &&
          fun {$ S}
             case {SplitFirst {HexReplace {Replace S &+ & }} &=}
             of L|S then
                {String.toAtom L}#case S of R|_ then R else unit end
             else
                raise cgi(parseError) end
             end
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
