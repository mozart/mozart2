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
     { name  => 'GtkMenuItem',

       super => 'GtkItem',

       inits => { 'gtk_menu_item_new'             => { out => 'GtkWidget*' },
                  'gtk_menu_item_new_with_label'  => { in  => ['const gchar*'],
                                                       out => 'GtkWidget*' } },

       meths => { 'gtk_menu_item_set_submenu'     => { in  => ['GtkMenuItem*',
                                                               '!GtkWidget*'] },
                  'gtk_menu_item_remove_submenu'  => { in  => ['GtkMenuItem*'] },
                  'gtk_menu_item_set_placement'   => { in  => ['GtkMenuItem*',
                                                               'GtkubmenuPlacement'] },
                  'gtk_menu_item_configure'       => { in  => ['GtkMenuItem*',
                                                               'gint',
                                                               'gint'] },
                  'gtk_menu_item_select'          => { in  => ['GtkMenuItem*'] },
                  'gtk_menu_item_deselect'        => { in  => ['GtkMenuItem*'] },
                  'gtk_menu_item_activate'        => { in  => ['GtkMenuItem*'] },
                  'gtk_menu_item_right_justify'   => { in  => ['GtkMenuItem*'] } }}
     );
