functor
import WD(new put) at 'x-oz://boot/WeakDictionary'
export 'class' : Guardian
define
   class Guardian
      attr Table
      meth init(Proc) L in
         Table <- {WD.new L}
         thread {ForAll L Proc} end
      end
      meth register(V)
         {WD.put @Table {NewName} V}
      end
   end
end
