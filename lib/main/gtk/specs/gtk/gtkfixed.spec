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
     { name  => 'GtkFixed',

       super => 'GtkContainer',

       fields => { 'children'                     => 'GList*' },

       inits => { 'gtk_fixed_new'                 => { out => 'GtkWidget*' },
                  'gtk_fixed_put'                 => { in  => ['GtkFixed*',
                                                               '!GtkWidget*',
                                                               'gint16',
                                                               'gint16'] },
                  'gtk_fixed_move'                => { in  => ['GtkFixed*',
                                                               '!GtkWidget*',
                                                               'gint16',
                                                               'gint16'] } }}
     );
