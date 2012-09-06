functor

require
   Boot_Property at 'x-oz://boot/Property'

prepare

   FunctorMap = {Dictionary.new}

   class BootModuleManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth link(URL ?Module)
         lock
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
         end
      end

      meth load(URL ?Module)
         Func
      in
         try
            Func = {Dictionary.get FunctorMap URL}
         catch dictKeyNotFound(_ _) then
            raise system(module(notFound load URL)) end
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

   proc {RegisterModule URLV Mod}
      {BootMM enter({VirtualString.toAtom URLV} Mod)}
   end

   proc {RegisterFunctor URLV Func}
      {Dictionary.put FunctorMap {VirtualString.toAtom URLV} Func}
   end

   /** The magic Run routine
    *  Sets up all the necessary things to be able to launch Init.ozf out of
    *  nowhere.
    */
   proc {Run}
      % First checkout the critical modules from the boot module manager
      OS         = {BootMM link('x-oz://system/OS.ozf' $)}
      Property   = {BootMM link('x-oz://system/Property.ozf' $)}
      System     = {BootMM link('x-oz://system/System.ozf' $)}
      URL        = {BootMM link('x-oz://system/URL.ozf' $)}
      DefaultURL = {BootMM link('x-oz://system/DefaultURL.ozf' $)}

      /** RemoveCWD - removes the prefix CWD from FileNameV if present */
      local
         CWD = {VirtualString.toString {OS.getCWD}}

         fun {StripPrefix Xs Ys Else}
            case Xs#Ys
            of (X|Xr)#nil then
               if X == &/ orelse X == &\\ then
                  Xr
               else
                  Xs
               end
            [] (X|Xr)#(Y|Yr) andthen X == Y then
               {StripPrefix Xr Yr Else}
            else
               Else
            end
         end
      in
         fun {RemoveCWD FileNameV}
            FileNameS = {VirtualString.toString FileNameV}
         in
            {StripPrefix FileNameS CWD FileNameS}
         end
      end

      /** Loads a functor located a given URL
       *  This never goes to the file system, but looks up functors in the
       *  global FunctorMap instead.
       *  Basically it uses FunctorMap as a virtual file system.
       */
      proc {URLLoad URL ?F}
         URLAtom = {VirtualString.toAtom {RemoveCWD URL}}
      in
         try
            F = {Dictionary.get FunctorMap URLAtom}
         catch dictKeyNotFound(_ _) then
            raise system(module(notFound load URLAtom)) end
         end
      end

      /** The boot URL module (stub version) */
      BURL = 'export'(
         localize: fun {$ U} U end
         open:     proc {$ U ?V}
                      {Exception.raiseError notImplemented('URL.open')}
                   end
         load:     URLLoad
      )

      /** The boot Pickle module (stub version) */
      Pickle = 'export'(
         load: proc {$ VI ?VO}
                  {Exception.raiseError notImplemented('Pickle.load')}
               end
      )

      /** The boot Boot module */
      local
         /** Loads a boot module from its name */
         fun {GetInternal Name}
            case Name
            of 'URL' then BURL
            [] 'OS' then OS
            [] 'Pickle' then Pickle
            [] 'Property' then Property
            [] 'System' then System
            else
               {BootMM link({VirtualString.toAtom 'x-oz://boot/'#Name} $)}
            end
         end

         /** Stub for Boot.getNative */
         proc {GetNative Name ?M}
            {Exception.raiseError notImplemented('Boot.getNative')}
         end
      in
         Boot = 'export'(
            getInternal: GetInternal
            getNative:   GetNative
         )
      end

      % And finally load the Init.ozf functor and apply it
      InitFunctor = {URLLoad 'x-oz://system/Init.ozf'}
   in
      {InitFunctor.apply 'import'('URL':        URL
                                  'DefaultURL': DefaultURL
                                  'Boot':       Boot) _}
   end

   ExportedBootMM = bootMM(registerModule:RegisterModule
                           registerFunctor:RegisterFunctor
                           run:Run)

   local
      BootMMProp
   in
      true = {Boot_Property.get 'internal.bootmm' ?BootMMProp}
      BootMMProp = ExportedBootMM
   end

end
