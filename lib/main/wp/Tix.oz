%%%
%%% Authors:
%%%   Martin Homik <homik@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Martin Homik, 2000
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   Tk(send:Send newWidgetClass:NWC)

export
   balloon:  TixBalloon
   btnBox:   TixBtnBox
   cObjView: TixCObjView
   chkList:  TixChkList
   comboBox: TixComboBox
   control:  TixControl
   dialogS:  TixDialogS
   dirBox:   TixDirBox
   dirDlg:   TixDirDlg
   dirList:  TixDirList
   dirTree:  TixDirTree
   dragDrop: TixDragDrop
   dtlList:  TixDtlList
   eFileBox: TixEFileBox
   eFileDlg: TixEFileDlg
   fileBox:  TixFileBox
   fileCbx:  TixFileCbx
   fileDlg:  TixFileDlg
   fileEnt:  TixFileEnt
   floatEnt: TixFloatEnt
   iconView: TixIconView
   labEntry: TixLabEntry
   labFrame: TixLabFrame
   listNBk:  TixListNBk
   meter:    TixMeter
   multView: TixMultView
   noteBook: TixNoteBook
   optMenu:  TixOptMenu
   panedWin: TixPanedWin
   popMenu:  TixPopMenu
   primitiv: TixPrimitiv
   resizeH:  TixResizeH
   sGrid:    TixSGrid
   sHList:   TixSHList
   sListBox: TixSListBox
   sTList:   TixSTList
   sText:    TixSText
   sWidget:  TixSWidget
   sWindow:  TixSWindow
   select:   TixSelect
   shell:    TixShell
   simpDlg:  TixSimpDlg
   stackWin: TixStackWin
   statBar:  TixStatBar
   stdBBox:  TixStdBBox
   stdShell: TixStdShell
   tix:      TixTix
   tree:     TixTree
   vResize:  TixVResize
   vStack:   TixVStack
   vTree:    TixVTree

define

   {Send package('require' 'Tix')}

   TixBalloon  = {NWC noCommand tixBalloon}
   TixBtnBox   = {NWC noCommand tixBtnBox}
   TixCObjView = {NWC noCommand tixCObjView}
   TixChkList  = {NWC noCommand tixChkList}
   TixComboBox = {NWC command   tixComboBox}
   TixControl  = {NWC command   tixControl}
   TixDialogS  = {NWC noCommand tixDialogS}
   TixDirBox   = {NWC command   tixDirBox}
   TixDirDlg   = {NWC command   tixDirDlg}
   TixDirList  = {NWC command   tixDirList}
   TixDirTree  = {NWC command   tixDirTree}
   TixDragDrop = {NWC command   tixDragDrop}
   TixDtlList  = {NWC noCommand tixDtlList}
   TixEFileBox = {NWC command   tixEFileBox}
   TixEFileDlg = {NWC command   tixEFileDlg}
   TixFileBox  = {NWC command   tixFileBox}
   TixFileCbx  = {NWC command   tixFileCbx}
   TixFileDlg  = {NWC command   tixFileDlg}
   TixFileEnt  = {NWC command   tixFileEnt}
   TixFloatEnt = {NWC command   tixFloatEnt}
   TixIconView = {NWC noCommand tixIconView}
   TixLabEntry = {NWC noCommand tixLabEntry}
   TixLabFrame = {NWC noCommand tixLabFrame}
   TixListNBk  = {NWC noCommand tixListNBk}
   TixMeter    = {NWC noCommand tixMeter}
   TixMultView = {NWC command   tixMultView}
   TixNoteBook = {NWC noCommand tixNoteBook}
   TixOptMenu  = {NWC command   tixOptMenu}
   TixPanedWin = {NWC command   tixPanedWin}
   TixPopMenu  = {NWC noCommand tixPopMenu}
   TixPrimitiv = {NWC noCommand tixPrimitiv}
   TixResizeH  = {NWC command   tixResizeH}
   TixSGrid    = {NWC noCommand tixSGrid}
   TixSHList   = {NWC noCommand tixSHList}
   TixSListBox = {NWC command   tixSListBox}
   TixSTList   = {NWC noCommand tixSTList}
   TixSText    = {NWC noCommand tixSText}
   TixSWidget  = {NWC noCommand tixSWidget}
   TixSWindow  = {NWC noCommand tixSWindow}
   TixSelect   = {NWC command   tixSelect}
   TixShell    = {NWC noCommand tixShell}
   TixSimpDlg  = {NWC noCommand tixSimpDlg}
   TixStackWin = {NWC noCommand tixStackWin}
   TixStatBar  = {NWC noCommand tixStatBar}
   TixStdBBox  = {NWC noCommand tixStdBBox}
   TixStdShell = {NWC noCommand tixStdShell}
   TixTix      = {NWC noCommand tixTix}
   TixTree     = {NWC noCommand tixTree}
   TixVResize  = {NWC noCommand tixVResize}
   TixVStack   = {NWC noCommand tixVStack}
   TixVTree    = {NWC noCommand tixVTree}

end
