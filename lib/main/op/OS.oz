%%%
%%% Author:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\ifdef LILO

functor $

export
   %% Os IO common to both files and sockets
   getCWD:        GetCWD
   chDir:         ChDir
   uName:         UName
   stat:          Stat
   getDir:        GetDir
   open:          Open
   fileDesc:      FileDesc
   close:         Close
   write:         Write
   read:          Read

   %% OS IO for files
   lSeek:         LSeek
   unlink:        Unlink

   %% OS IO for sockets
   socket:        Socket
   bind:          Bind
   listen:        Listen
   connect:       Connect
   accept:        Accept
   shutDown:      ShutDown

   %% Data interchange for sockets
   send:          Send
   sendTo:        SendTo
   receiveFrom:   ReceiveFrom

   %% Socket related inquiry procedures
   getSockName:   GetSockName
   getHostByName: GetHostByName
   getServByName: GetServByName

   %% Turning OS-blocking to Oz-suspension
   readSelect:    ReadSelect
   writeSelect:   WriteSelect
   acceptSelect:  AcceptSelect
   deSelect:      DeSelect

   %% Misc stuff
   system:        System
   pipe:          Pipe
   wait:          Wait
   getEnv:        GetEnv
   putEnv:        PutEnv
   tmpnam:        Tmpnam

   %% Random numbers
   rand:          Rand
   srand:         Srand
   randLimits:    RandLimits

   %% Time inquiry
   time:          Time
   gmTime:        GmTime
   localTime:     LocalTime

body

   %% Os IO common to both files and sockets
   GetCWD =        {`Builtin` 'OS.getCWD'        1}
   ChDir =         {`Builtin` 'OS.chDir'         1}
   UName =         {`Builtin` 'OS.uName'         1}
   Stat =          {`Builtin` 'OS.stat'          2}
   GetDir =        {`Builtin` 'OS.getDir'        2}
   Open =          {`Builtin` 'OS.open'          4}
   FileDesc =      {`Builtin` 'OS.fileDesc'      2}
   Close =         {`Builtin` 'OS.close'         1}
   Write =         {`Builtin` 'OS.write'         3}
   Read =          {`Builtin` 'OS.read'          5}

   %% OS IO for files
   LSeek =         {`Builtin` 'OS.lSeek'         4}
   Unlink =        {`Builtin` 'OS.unlink'        1}

   %% OS IO for sockets
   Socket =        {`Builtin` 'OS.socket'        4}
   Bind =          {`Builtin` 'OS.bind'          2}
   Listen =        {`Builtin` 'OS.listen'        2}
   Connect =       {`Builtin` 'OS.connect'       3}
   Accept =        {`Builtin` 'OS.accept'        4}
   ShutDown =      {`Builtin` 'OS.shutDown'      2}

   %% Data interchange for sockets
   Send =          {`Builtin` 'OS.send'          4}
   SendTo =        {`Builtin` 'OS.sendTo'        6}
   ReceiveFrom =   {`Builtin` 'OS.receiveFrom'   8}

   %% Socket related inquiry procedures
   GetSockName =   {`Builtin` 'OS.getSockName'   2}
   GetHostByName = {`Builtin` 'OS.getHostByName' 2}
   GetServByName = {`Builtin` 'OS.getServByName' 3}

   %% Turning OS-blocking to Oz-suspension
   ReadSelect =    {`Builtin` 'OS.readSelect'    1}
   WriteSelect =   {`Builtin` 'OS.writeSelect'   1}
   AcceptSelect =  {`Builtin` 'OS.acceptSelect'  1}
   DeSelect =      {`Builtin` 'OS.deSelect'      1}

   %% Misc stuff
   System =        {`Builtin` 'OS.system'        2}
   Pipe =          {`Builtin` 'OS.pipe'          4}
   Wait =          {`Builtin` 'OS.wait'          2}
   GetEnv =        {`Builtin` 'OS.getEnv'        2}
   PutEnv =        {`Builtin` 'OS.putEnv'        2}
   Tmpnam =        {`Builtin` 'OS.tmpnam'        1}

   %% Random numbers
   Rand =          {`Builtin` 'OS.rand'          1}
   Srand =         {`Builtin` 'OS.srand'         1}
   RandLimits =    {`Builtin` 'OS.randLimits'    2}

   %% Time inquiry
   Time =          {`Builtin` 'OS.time'          1}
   GmTime =        {`Builtin` 'OS.gmTime'        1}
   LocalTime =     {`Builtin` 'OS.localTime'     1}

end

\else

OS = os(%% Os IO common to both files and sockets
        getCWD:        {`Builtin` 'OS.getCWD'        1}
        chDir:         {`Builtin` 'OS.chDir'         1}
        uName:         {`Builtin` 'OS.uName'         1}
        stat:          {`Builtin` 'OS.stat'          2}
        getDir:        {`Builtin` 'OS.getDir'        2}
        open:          {`Builtin` 'OS.open'          4}
        fileDesc:      {`Builtin` 'OS.fileDesc'      2}
        close:         {`Builtin` 'OS.close'         1}
        write:         {`Builtin` 'OS.write'         3}
        read:          {`Builtin` 'OS.read'          5}

        %% OS IO for files
        lSeek:         {`Builtin` 'OS.lSeek'         4}
        unlink:        {`Builtin` 'OS.unlink'        1}

        %% OS IO for sockets
        socket:        {`Builtin` 'OS.socket'        4}
        bind:          {`Builtin` 'OS.bind'          2}
        listen:        {`Builtin` 'OS.listen'        2}
        connect:       {`Builtin` 'OS.connect'       3}
        accept:        {`Builtin` 'OS.accept'        4}
        shutDown:      {`Builtin` 'OS.shutDown'      2}

        %% Data interchange for sockets
        send:          {`Builtin` 'OS.send'          4}
        sendTo:        {`Builtin` 'OS.sendTo'        6}
        receiveFrom:   {`Builtin` 'OS.receiveFrom'   8}

        %% Socket related inquiry procedures
        getSockName:   {`Builtin` 'OS.getSockName'   2}
        getHostByName: {`Builtin` 'OS.getHostByName' 2}
        getServByName: {`Builtin` 'OS.getServByName' 3}

        %% Turning OS-blocking to Oz-suspension
        readSelect:    {`Builtin` 'OS.readSelect'    1}
        writeSelect:   {`Builtin` 'OS.writeSelect'   1}
        acceptSelect:  {`Builtin` 'OS.acceptSelect'  1}
        deSelect:      {`Builtin` 'OS.deSelect'      1}

        %% Misc stuff
        system:        {`Builtin` 'OS.system'        2}
        pipe:          {`Builtin` 'OS.pipe'          4}
        wait:          {`Builtin` 'OS.wait'          2}
        getEnv:        {`Builtin` 'OS.getEnv'        2}
        putEnv:        {`Builtin` 'OS.putEnv'        2}
        tmpnam:        {`Builtin` 'OS.tmpnam'        1}

        %% Random numbers
        rand:          {`Builtin` 'OS.rand'          1}
        srand:         {`Builtin` 'OS.srand'         1}
        randLimits:    {`Builtin` 'OS.randLimits'    2}

        %% Time inquiry
        time:          {`Builtin` 'OS.time'          1}
        gmTime:        {`Builtin` 'OS.gmTime'        1}
        localTime:     {`Builtin` 'OS.localTime'     1})

\endif
