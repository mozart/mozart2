%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Contributor:
%%%
%%% Copyright:
%%%   Denys Duchier, 2000
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
   GTK at 'x-oz://system/GTK.ozf'
export
   Make gtk:GTK
define

   WindowType  = o(toplevel:0 dialog:1 popup:2)
   ReliefStyle = o(normal:0 half:1 none:2)
   ShadowType  = o(none:0 'in':1 out:2 etchedIn:3 etchedOut:4
                   flat:0 sunken:1 raised:2 groove:3 ridge:4)
   SignalsEditable =
   [changed 'insert-text' 'delete-text' activate 'set-editable'
    'move-cursor' 'move-word' 'move-page' 'move-to-row' 'move-to-column'
    'kill-char' 'kill-word' 'kill-line' 'cut-clipboard' 'copy-clipboard'
    'paste-clipboard']

   fun {MakeChildren D I}
      if {HasFeature D I} then
         ({Make D.I}#D)|{MakeChildren D I+1}
      else
         nil
      end
   end

   fun {HasFeatureN D Fs}
      case Fs of nil then false
      [] H|T then {HasFeature D H} orelse {HasFeatureN D T}
      end
   end

   fun {CondSelectN D Fs V}
      case Fs of nil then V
      [] F|Fs then
         if {HasFeature D F} then D.F else {CondSelectN D Fs V} end
      end
   end

   fun {RowLength Row N}
      case Row
      of nil then N
      [] H|T then {RowLength T N+{CondSelect H span 1}}
      end
   end

   fun {HTableSize T}
      %% [Row1 Row2 ...]
      Rows = {CondSelectN T [1 rows] nil}
   in
      {Length Rows}#
      {FoldL Rows
       fun {$ N Row}
          {Max N {RowLength Row 0}}
       end 0}
   end

   proc {HTableAddRow Table Row Nrow Ncol}
      case Row
      of nil then skip
      [] H|T then
         W = {Make H}
         S = {CondSelect H span 1}
      in
         {Table attachDefaults(W Ncol Ncol+S Nrow Nrow+1)}
         {HTableAddRow Table T Nrow Ncol+S}
      end
   end

   proc {HTableAddRows Table Rows Nrow}
      case Rows
      of nil then skip
      [] H|T then
         {HTableAddRow  Table H Nrow 0}
         {HTableAddRows Table T Nrow+1}
      end
   end

   fun {ToAlign X}
      case X
      of left   then 0.0
      [] right  then 1.0
      [] center then 0.5
      [] middle then 0.5
      elseif {IsFloat X} then X end
   end

   proc {Make D W}
      case D

      of window(...) then
         W = {New GTK.window new(WindowType.{CondSelect D type toplevel})}
         if {HasFeature D title} then {W setTitle(D.title)} end
         if {HasFeature D 1} then {W add({Make D.1})} end

      [] hbox(...) then
         W = {New GTK.hBox new({CondSelect D homogeneous false}
                               {CondSelect D spacing 0})}
         for X in {MakeChildren D 1} do
            case X of Child#ChildDesc then
               if {CondSelect ChildDesc atEnd false} then
                  {W packEnd(Child
                             {CondSelect ChildDesc expand  false}
                             {CondSelect ChildDesc fill    false}
                             {CondSelect ChildDesc padding     0})}
               else
                  {W packStart(Child
                               {CondSelect ChildDesc expand  false}
                               {CondSelect ChildDesc fill    false}
                               {CondSelect ChildDesc padding     0})}
               end
            end
         end

      [] vbox(...) then
         W = {New GTK.vBox new({CondSelect D homogeneous false}
                               {CondSelect D spacing 0})}
         for X in {MakeChildren D 1} do
            case X of Child#ChildDesc then
               if {CondSelect ChildDesc atEnd false} then
                  {W packEnd(Child
                             {CondSelect ChildDesc expand  false}
                             {CondSelect ChildDesc fill    false}
                             {CondSelect ChildDesc padding     0})}
               else
                  {W packStart(Child
                               {CondSelect ChildDesc expand  false}
                               {CondSelect ChildDesc fill    false}
                               {CondSelect ChildDesc padding     0})}
               end
            end
         end

      [] label(...) then
         W = {New GTK.label new({CondSelectN D [text 1] ""})}
         if {HasFeature D pattern} then {W setPattern(D.pattern)} end
         if {HasFeature D justify} then {W setJustify(D.justify)} end
         if {HasFeature D lineWrap} then {W setLineWrap(D.lineWrap)} end

      [] button(...) then
         W = {New GTK.button newWithLabel({CondSelectN D [text 1] ""})}
         if {HasFeature D relief} then {W setRelief(ReliefStyle.(D.relief))} end
         if {HasFeature D signal} then S=D.signal in
            for F in [pressed released clicked enter leave] do
               if {HasFeature S F} then {W signalConnect(F S.F _)} end
            end
         end
         if {HasFeature D action} then {W signalConnect(clicked D.action _)} end

      [] htable(...) then
         Nrows#Ncols = {HTableSize D}
      in
         W = {New GTK.table new(Nrows Ncols {CondSelect D homogeneous false})}
         if {HasFeature D rowSpacings} then {W setRowSpacings(D.rowSpacings)} end
         if {HasFeature D colSpacings} then {W setColSpacings(D.colSpacings)} end
         {HTableAddRows W {CondSelectN D [1 rows] nil} 0}

      [] frame(...) then
         W = {New GTK.frame new(nil)}
         if {HasFeatureN D [label text title]} then
            {W setLabel({CondSelectN D [label text title] nil})}
         end
         if {HasFeatureN D [labelAlign textAlign titleAlign align]} then
            {W setLabelAlign({ToAlign {CondSelectN D [labelAlign textAlign titleAlign align] nil}} 0.0)}
         end
         if {HasFeatureN D [shadowType relief]} then
            {W setShadowType(ShadowType.{CondSelectN D [shadowType relief] nil})}
         end
         for X in {MakeChildren D 1} do
            case X of Child#_ then {W add(Child)} end
         end

      [] entry(...) then
         W = {New GTK.entry new}
         if {HasFeatureN D [text 1]} then
            {W setText({CondSelectN D [text 1] nil})}
         end
         if {HasFeatureN D [visibility visible]} then
            {W setVisibility({CondSelectN D [visibility visible] true})}
         end
         if {HasFeature D editable} then
            {W setEditable(D.editable)}
         end
         if {HasFeature D maxLength} then
            {W setMaxLength(D.maxLength)}
         end
         if {HasFeature D signal} then S=D.signal in
            for F in SignalsEditable do
               if {HasFeature S F} then
                  {W signalConnect(F S.F _)}
               end
            end
         end
      end

      if {HasFeature D handle} then D.handle=W end
   end
end
