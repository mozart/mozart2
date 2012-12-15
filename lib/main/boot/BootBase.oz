functor

require
   Boot_Boot at 'x-oz://boot/Boot'
   Boot_Property at 'x-oz://boot/Property'

prepare

   FunctorMap = {Dictionary.new}
   {Boot_Property.get 'internal.boot.virtualfs' $ true} = FunctorMap

   class BootModuleManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth link(URL ?Module)
         URLString = {VirtualString.toString URL}
      in
         if {List.isPrefix "x-oz://boot/" URLString} then
            Module = {Boot_Boot.getInternal
                      {VirtualString.toAtom {List.drop URLString 12}}}
         else
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
   end

   BootMM = {New BootModuleManager init}

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
         open:     fun {$ U}
                      {OS.open U ['O_RDONLY'] nil}
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
               {Boot_Boot.getInternal Name}
            end
         end
      in
         Boot = 'export'(
            getInternal: GetInternal
            getNative:   Boot_Boot.getNative
         )
      end

      % And finally load the Init.ozf functor and apply it
      InitFunctor = {URLLoad 'x-oz://system/Init.ozf'}
   in
      {InitFunctor.apply 'import'('URL':        URL
                                  'DefaultURL': DefaultURL
                                  'Boot':       Boot) _}
   end

   {Boot_Property.get 'internal.boot.run' $ true} = Run

end
