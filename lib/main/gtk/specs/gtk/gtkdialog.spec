# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$
#   $Revision$
#
# This file is part of Mozart, an implementation
# of Oz 3:
#   http://www.mozart-oz.org
#
# See the file "LICENSE" or
#   http://www.mozart-oz.org/LICENSE.html
# for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL
# WARRANTIES.
#

$class =
    (
     { name  => 'GtkDialog',

       super => 'GtkWindow',

       fields => { 'vbox'                                 => 'GtkVBox*',
                   'action_area'                          => 'GtkHBox*' },

       # TODO: build implizid Oz objects: vbox and action_area
       inits => { 'gtk_dialog_new'                        => { out => 'GtkWidget*' } }}

     );
