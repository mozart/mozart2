# -*-perl-*-

# Authors:
#   Denys Duchier (2000)
#
# Copyright:
#   Denys Duchier (2000)
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
     { name  => 'GtkTree',

       super => 'GtkContainer',

       inits => { 'gtk_tree_new'                => { in  => [],
                                                     out => 'GtkWidget*' }},

       meths => { 'gtk_tree_append'             => { in  => ['GtkTree*',
                                                             '!GtkWidget*'] },
                  'gtk_tree_child_position'     => { in  => ['GtkTree*',
                                                             '!GtkWidget*'],
                                                     out => 'gint' },
                  'gtk_tree_clear_items'        => { in  => ['GtkTree*','gint','gint'] },
                  'gtk_tree_insert'             => { in  => ['GtkTree*','!GtkWidget*','gint'] },
                  'gtk_tree_prepend'            => { in  => ['GtkTree*','!GtkWidget*'] },
                  'gtk_tree_remove_item'        => { in  => ['GtkTree*','!GtkWidget*'] },
                  'gtk_tree_select_child'       => { in  => ['GtkTree*','!GtkWidget*'] },
                  'gtk_tree_select_item'        => { in  => ['GtkTree*','gint'] },
                  'gtk_tree_unselect_child'     => { in  => ['GtkTree*','!GtkWidget*'] },
                  'gtk_tree_unselect_item'      => { in  => ['GtkTree*','gint'] },
              }
   }
     );
