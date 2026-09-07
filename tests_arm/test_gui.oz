functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Application
define
   WindowObj
   LabelHandle
   
   %% Description de l'interface
   Description = td(
      title: "Test ARM64 Natif"
      label(text:"Bonjour depuis macOS Apple Silicon !" handle:LabelHandle)
      button(text:"Cliquez-moi" 
             action:proc {$} {LabelHandle set(text:"Tcl/Tk fonctionne parfaitement !")} end)
      button(text:"Quitter" 
             action:proc {$} {Application.exit 0} end)
   )
in
   %% Construction et affichage de la fenêtre
   WindowObj = {QTk.build Description}
   {WindowObj show}
end