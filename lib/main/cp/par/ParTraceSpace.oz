%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org/
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

export
   plain: PlainSpace
   best:  BestSpace

prepare

   local

      proc {DoUpdate S Fs Hs ?NHs}
         case Fs of nil then NHs=Hs
         [] F|Fr then
            NHs=F|{DoUpdate S Fr Hs}
            {Space.commit S F}
         end
      end

   in

      class PlainSpace
         attr
            history: nil
            future:  nil
            space:   nil

         meth new(P)
            space   <- {Space.new P}
            history <- nil
            future  <- nil
         end

         meth Update
            history <- {DoUpdate @space @future @history}
            future  <- nil
         end

         meth ask($)
            PlainSpace,Update
            {Space.ask @space}
         end

         meth Clone(S H)
            space   <- S
            future  <- nil
            history <- H
         end

         meth clone($)
            PlainSpace,Update
            {New PlainSpace Clone({Space.clone @space} @history)}
         end

         meth merge($)
            PlainSpace,Update
         {Space.merge @space $}
         end

         meth commit(I)
            future <- case I of N#M then
                         if N==M then N else I end
                      else I
                   end|@future
         end

         meth externalize($)
            {Append @future @history}
         end

         meth internalize(Hs)
            history <- nil
            future  <- Hs
            PlainSpace,Update
         end
      end

   end


   local

      proc {DoUpdate S O Fs Hs ?NHs}
         case Fs of nil then NHs=Hs
         [] F|Fr then
            NHs=F|{DoUpdate S O Fr Hs}
            case F
            of commit(I)     then
               {Space.commit S I}
            [] constrain(Sol) then
               {Space.ask S _}
               {Space.inject S proc {$ R}
                                  {O Sol R}
                               end}
            end
         end
      end

   in

      class BestSpace
         feat
            order
         attr
            history: nil
            future:  nil
            space:   nil

         meth new(P O)
            space   <- {Space.new P}
            self.order = O
            history <- nil
            future  <- nil
         end

         meth Update
            history <- {DoUpdate @space self.order @future @history}
            future  <- nil
         end

         meth ask($)
            BestSpace,Update
            {Space.ask @space}
         end

         meth constrain(S)
            future <- constrain(S)|@future
         end

         meth Clone(S O H)
            space   <- S
            self.order = O
            future  <- nil
            history <- H
         end

         meth clone($)
            BestSpace,Update
            {New BestSpace Clone({Space.clone @space}
                                      self.order @history)}
         end

         meth merge($)
            BestSpace,Update
            {Space.merge @space $}
         end

         meth commit(I)
            future <- commit(case I of N#M then
                                if N==M then N else I end
                             else I
                             end)|@future
         end

         meth externalize($)
            {Append @future @history}
         end

         meth internalize(Hs)
            history <- nil
            future  <- Hs
            BestSpace,Update
         end
      end

   end

end
