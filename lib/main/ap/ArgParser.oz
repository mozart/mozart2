%%
%% ArgParser (Christian Schulte)
%%

local
   CharToLower  = Char.toLower
   AtomToString = Atom.toString

   fun {NormalizeSpec ArgSpec}
      {List.toRecord m
       {Record.foldL ArgSpec
        fun {$ Ar AS}
           S={Map {AtomToString {Label AS}} CharToLower}
           A={String.toAtom S}
           N=case {IsAtom AS} then
                A(type:bool optional:false default:false)
             else
                TA={Adjoin
                    {Adjoin o(type:bool optional:false) AS} A}
             in
                {Adjoin o(default:case TA.type
                                  of float  then 0.0
                                  [] int    then 0
                                  [] string then ""
                                  [] atom   then ''
                                  [] bool   then false
                                  end) TA}
             end
        in
           case N.type==bool then
              NoA={String.toAtom &n|&o|S}
           in
              A#{Adjoin N A(real:A value:true)}|
              NoA#{Adjoin N NoA(real:A value:false)}|Ar
           else
              A#N|Ar
           end
        end nil}}
   end

   local
      local
         proc {SplitString Is ?I1s ?I2s}
            case Is of nil then I1s=nil I2s=nil
            [] I|Ir then
               case I==&= then I1s=nil I2s=Ir
               else I1s=I|{SplitString Ir $ I2s}
               end
            end
         end
      in
         fun {ParseOption Is ArgSpec ?O ?V}
            case Is of &-|Is then
               case Is of nil then false
               [] I|Ir then
                  FirstIsMinus = (I==&-)
               in
                  case FirstIsMinus andthen Ir==nil then false else
                     OS VS
                  in
                     {SplitString case FirstIsMinus then Ir else Is end
                      ?OS ?VS}
                     O={String.toAtom {Map OS CharToLower}}
                     V=VS
                     {HasFeature ArgSpec O}
                  end
               end
            else false
            end
         end
      end

      local
         fun {TidyMinus Is}
            case Is of nil then nil
            [] I|Ir then
               case I of &- then &~ else I end|{TidyMinus Ir}
            end
         end
      in
         fun {CheckInt S}
            {String.isInt {TidyMinus S}}
         end
         fun {CheckFloat S}
            TS={TidyMinus S}
         in
            {String.isInt TS} orelse {String.isFloat TS}
         end
         fun {ParseInt S}
            {String.toInt {TidyMinus S}}
         end
         fun {ParseFloat S}
            TS={TidyMinus S}
         in
            case {String.isInt TS} then {Int.toFloat {String.toInt TS}}
            else {String.toFloat TS}
            end
         end
      end
   in
      fun {ParseArgs As ArgSpec ?RAs}
         case As of nil then RAs=nil nil
         [] A|Ar then O V in
            case {ParseOption A ArgSpec ?O ?V} then
               %% O is a option!
               S = ArgSpec.O
               Cont # Value # NextAs =
               %% Check whether it has the right kind of value
               %% and determine
               case S.type==bool then
                  case V==nil then
                     true  # S.value # Ar
                  else
                     false # _ # As
                  end
               else
                  Arg#ArgR = case V==nil then
                                case Ar of A|Ar then A#Ar else nil#nil end
                             else V#Ar
                             end
               in
                  case {Not S.optional} andthen Arg==nil then
                     false#_#As
                  elsecase S.type
                  of int    then
                     case {CheckInt Arg} then
                        true  # {ParseInt Arg} # ArgR
                     elsecase S.optional then
                        true  # S.default # Ar
                     else
                        false # _ # As
                     end
                  [] float  then
                     case {CheckFloat Arg} then
                        true  # {ParseFloat Arg} # ArgR
                     elsecase S.optional then
                        true  # S.default # Ar
                     else
                        false # _ # As
                     end
                  elsecase S.optional andthen
                     V==nil andthen {ParseOption Arg ArgSpec _ _} then
                     true # S.default # Ar
                  else
                     true # case S.type
                            of atom   then {String.toAtom Arg}
                            [] string then Arg
                            end # ArgR
                  end
               end
            in
               case Cont then
                  {CondSelect S real O}#Value|{ParseArgs NextAs ArgSpec RAs}
               else RAs=NextAs nil
               end
            else
               RAs=As nil
            end
         end
      end
   end

   fun {ToSingle AVs Rest Args ArgSpec}
      D={Dictionary.new}
   in
      {ForAll Args proc {$ A}
                      {Dictionary.put D A ArgSpec.A.default}
                   end}
      {ForAll AVs proc {$ A#V}
                     {Dictionary.put D {CondSelect ArgSpec.A real A} V}
                  end}
      {Dictionary.put D 1 Rest}
      {Dictionary.toRecord argv D}
   end

   fun {ToMultiple AVs Rest Args ArgSpec}
      D={Dictionary.new}
   in
      {ForAll Args proc {$ A}
                      {Dictionary.put D A [ArgSpec.A.default]}
                   end}
      {ForAll AVs proc {$ A#V}
                     RA={CondSelect ArgSpec.A real A}
                  in
                     {Dictionary.put D RA V|{Dictionary.get D RA}}
                  end}
      {Dictionary.put D 1 Rest}
      {Dictionary.toRecord argv D}
   end

   SystemGet = System.get
   fun {GetArgs}
      {Map {SystemGet argv} AtomToString}
   end

in

   fun {MakeArgParser ArgSpec}
      Kind={Label ArgSpec}
   in
      case Kind
      of plain then
         GetArgs
      else
         Args = {Record.foldL ArgSpec fun {$ As R}
                                         {Label R}|As
                                      end nil}
         Spec = {NormalizeSpec ArgSpec}
      in
         case Kind
         of single   then
            fun {$}
               Ar
            in
               {ToSingle {ParseArgs {GetArgs} Spec ?Ar} Ar Args Spec}
            end
         [] multiple then
            fun {$}
               Ar
            in
               {ToMultiple {ParseArgs {GetArgs} Spec ?Ar} Ar Args Spec}
            end
         [] list     then
            fun {$}
               Ar in {Append {ParseArgs {GetArgs} Spec ?Ar} Ar}
            end
         end
      end
   end

end
