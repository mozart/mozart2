%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                      %%
%% QTk                                                                  %%
%%                                                                      %%
%%  (c) 2000 Université catholique de Louvain. All Rights Reserved.     %%
%%  The development of QTk is supported by the PIRATES project at       %%
%%  the Université catholique de Louvain.  This file is subject to the  %%
%%  general Mozart license.                                             %%
%%                                                                      %%
%%  Author: Donatien Grolaux                                            %%
%%                                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

functor

import
   QTkDevel(execTk:    ExecTk
            returnTk:  ReturnTk
            subtracts: Subtracts
            assert:    Assert
            setGet:    SetGet)
   Pickle
   Open
   Tk
   Module

export
   NewImage
   NewImageLibrary
   LoadImageLibrary
   SaveImageLibrary
   BuildImageLibrary
define

   CArray={NewArray 0 63 0}
   {List.forAllInd "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    proc{$ I C}
       {Array.put CArray I-1 C}
    end}

   fun{Encode File}
      Handler Dump
   in
      Handler={New Open.file init(url:File
                                  flags:[read])}
      local T in
         T={Handler read(list:$ size:all)}
         case ({Length T} mod 3)
         of 0 then Dump=T
         [] 1 then Dump={List.append T [255 255]}
         [] 2 then Dump={List.append T [255]}
         end
      end
      {Handler close}
      local
         proc{ByteToBit B B0 B1 B2 B3 B4 B5 B6 B7}
            fun {GetBit V B}
               B=V mod 2
               V div 2
            end
         in
            _={List.foldL [B0 B1 B2 B3 B4 B5 B6 B7] GetBit B}
         end
         fun{TB A0 A1 A2 A3 A4 A5}
            {Array.get CArray A5*32+A4*16+A3*8+A2*4+A1*2+A0}
         end
         fun{Loop X N}
            case X of A|B|C|Xs then
               local
                  A0 A1 A2 A3 A4 A5 A6 A7
                  B0 B1 B2 B3 B4 B5 B6 B7
                  C0 C1 C2 C3 C4 C5 C6 C7
               in
                  {ByteToBit A A0 A1 A2 A3 A4 A5 A6 A7}
                  {ByteToBit B B0 B1 B2 B3 B4 B5 B6 B7}
                  {ByteToBit C C0 C1 C2 C3 C4 C5 C6 C7}
                  if N>=68 then
                     {TB A2 A3 A4 A5 A6 A7}|{TB B4 B5 B6 B7 A0 A1}|{TB C6 C7 B0 B1 B2 B3}|{TB C0 C1 C2 C3 C4 C5}|10|32|32|32|32|{Loop Xs 0}
                  else
                     {TB A2 A3 A4 A5 A6 A7}|{TB B4 B5 B6 B7 A0 A1}|{TB C6 C7 B0 B1 B2 B3}|{TB C0 C1 C2 C3 C4 C5}|{Loop Xs N+4}
                  end
               end
            else if N>0 then 10|nil else nil end
            end
         end
      in
         32|32|32|32|{Loop Dump 0}
      end
   end

   fun{Insert File}
      Handler Dump
   in
      Handler={New Open.file init(url:File
                                  flags:[read])}
      Dump={Handler read(list:$ size:all)}
      {Handler close}
      Dump
   end

   fun{EncodeRec M}
      R1=if {HasFeature M file} then
            {Record.adjoin r(name:{VirtualString.toAtom M.file}
                             data:if M.type==photo then {Encode M.file}
                                  else {Insert M.file} end
                            )
             {Record.subtract M file}}
         elseif {HasFeature M url} then
            {Record.adjoin r(name:{VirtualString.toAtom M.url}
                             data:if M.type==photo then {Encode M.file}
                                  else {Insert M.file} end
                            )
             {Record.subtract M url}}
         elseif {HasFeature M name}==false then
            {Exception.raiseError qtk(missingParameter name image M)}
            nil
         else
            M
         end
   in
      if {HasFeature M maskfile} then
         {Record.adjoinAt {Record.subtract R1 maskfile}
          maskdata {Encode M.maskfile}}
      elseif {HasFeature M maskurl} then
         {Record.adjoinAt {Record.subtract R1 maskurl}
          maskdata {Encode M.maskurl}}
      else R1 end
   end

   class QTkImage

      from Tk.image SetGet

      feat
         widgetType:image
         typeInfo:r(all:r(type:[bitmap photo]
                          background:color
                          data:vs
                          file:vs
                          url:vs
                          foreground:color
                          maskdata:vs
                          maskfile:vs
                          maskurl:vs
                          channel:no
                          format:vs
                          gamma:float
                          height:natural
                          palette:vs
                          width:natural)
                    uninit:r
                    unset:r
                    unget:r
                   )

      meth init(...)=M
         lock
            {Assert self.widgetType self.typeInfo M}
            Tk.image,{Record.adjoin M tkInit}
         end
      end

      meth blank(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth set(...)=M
         lock
            {Assert self.widgetType self.typeInfo M}
            SetGet,M
         end
      end

      meth get(...)=M
         lock
            {Assert self.widgetType self.typeInfo M}
            SetGet,M
         end
      end

      meth copy(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth getColor(...)=M
         lock
            {ReturnTk self M listInt}
         end
      end

      meth put(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth read(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth redither(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth write(...)=M
         lock
            {ExecTk self M}
         end
      end
   end

   fun{NewImage R}
      {New QTkImage {Record.adjoin R init(type:{Label R})}}
   end

   class QTkImageLibrary
      prop locking
      feat data image

      meth init
         lock
            self.data={NewDictionary}
            self.image={NewDictionary}
         end
      end

      meth newPhoto(...)=M
         {self {Record.adjoin M NewImage(type:photo)}}
      end

      meth newBitmap(...)=M
         {self {Record.adjoin M NewImage(type:bitmap)}}
      end

      meth NewImage(...)=M
         lock
            R={EncodeRec M}
            I
            Self=self
            {Dictionary.put self.data R.name R}
            class LibImage
               from QTkImage
               prop locking
               meth set(...)=M
                  lock
                     {Dictionary.put Self.data R.name
                      {Record.adjoin {Dictionary.condGet Self.data R.name nil} M}}
                     {Dictionary.put Self.image R.name self}
                     QTkImage,M
                  end
               end
            end
         in
            I={New LibImage {Record.adjoin {Subtracts R [image name]} init}}
            {Dictionary.put self.image R.name I}
            if {HasFeature M image} then M.image=I else skip end
         end
      end

      meth get(name:N image:I<=_ data:D<=_)=M
         lock
            Name={VirtualString.toAtom N}
            Data={Dictionary.condGet self.data Name nil}
         in
            I={Dictionary.condGet self.image Name nil}
            D={Record.subtract
               {Record.adjoin Data if Data.type==bitmap then newBitmap else newPhoto end}
               type}
            if I==nil then
               {Exception.raiseError qtk(custom "Can't get image" "Image not in library" M)}
            else skip end
         end
      end

      meth getNames(N)
         lock
            N={Dictionary.keys self.data}
         end
      end

      meth remove(name:N)
         lock
            Name={VirtualString.toAtom N}
         in
            {Dictionary.remove self.data Name}
            {Dictionary.remove self.image Name}
         end
      end

   end

   fun{NewImageLibrary}
      {New QTkImageLibrary init}
   end

   fun{LoadImageLibrary File}
      M
   in
      [M]={Module.link [File]}
      {M.buildLibrary QTkImageLibrary}
   end

   proc{SaveImageLibrary L File}
      PrepList={List.map {L getNames($)}
                fun{$ Name}
                   Name#{L get(name:Name data:$)}
                end}
      F=functor
        export BuildLibrary
        define
           fun{BuildLibrary QTkImageLibrary}
              Library={New QTkImageLibrary init}
              {ForAll PrepList
               proc{$ R}
                  Data
               in
                  _#Data=R
                  {Library Data}
               end}
           in
              Library
           end
        end
   in
      {Pickle.saveCompressed F File 9}
   end

   fun{BuildImageLibrary BL} {BL QTkImageLibrary} end

end
