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
