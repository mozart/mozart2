makefile(
   uri     : 'x-oz://system'
   mogul   : 'mogul:/mozart/qtk'
   lib     : ['QTk.ozf' 'QTkDevel.ozf']
   depends :
      o(
         'QTkDropdownbutton_bitmap.ozf'
         : ['QTkImageLibBoot.ozf' 'mini-down.xbm']
         'QTkNumberentry_bitmap.ozf'
         : ['QTkImageLibBoot.ozf' 'mini-inc.xbm' 'mini-dec.xbm']
         'QTkDropdownlistbox.ozf'
         : ['QTkBare.ozf' 'QTkImage.ozf' 'QTkDevel.ozf'
            'QTkDropdownbutton_bitmap.ozf' ]
         'QTkNumberentry.ozf'
         : ['QTkNumberentry_bitmap.ozf']
         'QTkBare.ozf'
         : ['QTk.oz' 'Frame.oz' 'QTkClipboard.oz' 'QTkFont.oz' 'QTkDialogbox.oz'
            'QTkFrame.oz']
         'QTk.ozf'
         : ['QTkBare.ozf' 'QTkDevel.ozf' 'QTkImage.ozf' 'QTkMenu.ozf'
            'QTkSpace.ozf' 'QTkLabel.ozf' 'QTkButton.ozf' 'QTkCheckbutton.ozf'
            'QTkRadiobutton.ozf' 'QTkScale.ozf' 'QTkScrollbar.ozf'
            'QTkEntry.ozf' 'QTkCanvas.ozf' 'QTkListbox.ozf' 'QTkText.ozf'
            'QTkPlaceholder.ozf' 'QTkPanel.ozf' 'QTkRubberframe.ozf'
            'QTkScrollframe.ozf' 'QTkToolbar.ozf' 'QTkDropdownlistbox.ozf'
            'QTkNumberentry.ozf' ]
         )
   rules   :
      o('QTk.ozf' : ozl('QTkBare.ozf'))
   )
