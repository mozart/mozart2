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
     { name  => 'GtkMenuBar',

       super => 'GtkMenuShell',

       args  => { 'shadow'                        => 'GtkShadowType' },

       inits => { 'gtk_menu_bar_new'              => { out => 'GtkWidget*' } },

       meths => { 'gtk_menu_bar_append'           => { in  => ['GtkMenuBar*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_bar_prepend'          => { in  => ['GtkMenuBar*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_bar_insert'           => { in  => ['GtkMenuBar*',
                                                               '!GtkWidget*',
                                                               'gint'] },
                  'gtk_menu_bar_set_shadow_type'  => { in  => ['GtkMenuBar*',
                                                               'GtkShadowType'] } }}
     );
