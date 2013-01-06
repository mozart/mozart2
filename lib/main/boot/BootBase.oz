functor

require
   Boot_Boot at 'x-oz://boot/Boot'
   Boot_Property at 'x-oz://boot/Property'

prepare

   BootVirtualFS = {Dictionary.new}
   {Boot_Property.get 'internal.boot.virtualfs' $ true} = BootVirtualFS

   /** Loads a functor located at a given URL
    *  This never goes to the file system, but looks up functors in the
    *  BootVirtualFS above instead.
    */
   fun {BootURLLoad URL}
      URLAtom = {VirtualString.toAtom URL}
   in
      try
         {Dictionary.get BootVirtualFS URLAtom}
      catch dictKeyNotFound(_ _) then
         raise system(module(notFound load URLAtom)) end
      end
   end

   /** Boot linker for the critical modules */
   proc {LinkCriticalModules CriticalModules}
      fun {Link URL}
         URLString = {VirtualString.toString URL}
      in
         if {List.isPrefix "x-oz://boot/" URLString} then
            {Boot_Boot.getInternal {List.drop URLString 12}}
         elsecase {CondSelect CriticalModules {VirtualString.toAtom URL} false}
         of false then
            raise system(module(notFound load URL)) end
         [] Mod then
            Mod
         end
      end

      fun lazy {Load URL}
         Func = {BootURLLoad URL}
         LinkedImports = {Record.mapInd Func.'import'
                          fun {$ ModName Info}
                             {Link Info.'from'}
                          end}
      in
         {Func.apply LinkedImports}
      end
   in
      {Record.forAllInd CriticalModules Load}
   end

   /** The magic Run routine
    *  Sets up all the necessary things to be able to launch Init.ozf out of
    *  nowhere.
    */
   proc {Run}
      % First link the critical modules
      OS Property System URL DefaultURL
      {LinkCriticalModules o('x-oz://system/OS.ozf':OS
                             'x-oz://system/Property.ozf':Property
                             'x-oz://system/System.ozf':System
                             'x-oz://system/URL.ozf':URL
                             'x-oz://system/DefaultURL.ozf':DefaultURL)}

      /** The boot URL module (stub version) */
      BURL = 'export'(
         localize: fun {$ U} U end
         open:     fun {$ U}
                      {OS.open U ['O_RDONLY'] nil}
                   end
         load:     BootURLLoad
      )

      % And finally load the Init.ozf functor and apply it
      InitFunctor = {BootURLLoad 'x-oz://system/Init.ozf'}
   in
      {InitFunctor.apply 'import'('URL':        URL
                                  'DefaultURL': DefaultURL
                                  'Boot':       Boot_Boot
                                  'BURL':       BURL
                                  'OS':         OS
                                  'Property':   Property
                                  'System':     System) _}
   end

   {Boot_Property.get 'internal.boot.run' $ true} = Run

end
