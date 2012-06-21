functor

prepare

   FunctorMap = {Dictionary.new}

   class BootModuleManager
      feat Lock ModuleMap

      meth init
         self.Lock = {NewLock}
         self.ModuleMap = {Dictionary.new}
      end

      meth link(URL ?Module)
         {LockIn self.Lock proc {$}
            ModMap = self.ModuleMap
         in
            if {Dictionary.member ModMap URL} then
               % The module is already in the dictionary
               Module = {Dictionary.get ModMap URL}
            else
               % Add a new lazy linking
               Module = {ByNeedFuture fun {$} {self load(URL $)} end}
               {Dictionary.put ModMap URL Module}
            end
         end}
      end

      meth load(URL ?Module)
         Func
      in
         try
            Func = {Dictionary.get FunctorMap URL}
         catch dictKeyNotFound(_ _) then
            raise system(module(notFound URL)) end
         end

         {self apply(URL Func Module)}
      end

      meth apply(URL Func ?Module)
         LinkedImports = {Record.mapInd Func.'import'
            fun {$ ModName Info}
               EmbedURL = Info.'from'
            in
               {self link(EmbedURL $)}
            end}
      in
         Module = {Func.apply LinkedImports}
      end

      meth enter(URL Module)
         {Dictionary.put self.ModuleMap URL Module}
      end
   end

   BootMM = {New BootModuleManager init}

in

   proc {`Boot:RegisterModule` URL Mod}
      {BootMM enter(URL Mod)}
   end

   proc {`Boot:RegisterFunctor` URL Func}
      {Dictionary.put FunctorMap URL Func}
   end

   proc {`Boot:Run` MainURL}
      MainModule = {BootMM link(MainURL $)}
   in
      {Wait MainModule}
   end

end
