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
     { name  => 'GtkOptionMenu',

       super => 'GtkButton',

       inits => { 'gtk_option_menu_new'           => { out => 'GtkWidget*' } },

       meths => { 'gtk_option_menu_get_menu'      => { in  => ['GtkOptionMenu*'],
                                                       out => 'GtkWidget*' },
                  'gtk_option_menu_set_menu'      => { in  => ['GtkOptionMenu*',
                                                               '!GtkWidget*'] },
                  'gtk_option_menu_remove_menu'   => { in  => ['GtkOptionMenu*'] },
                  'gtk_option_menu_set_history'   => { in  => ['GtkOptionMenu*',
                                                               'guint'] } }}
     );
