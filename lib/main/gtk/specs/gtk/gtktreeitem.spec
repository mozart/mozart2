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
     { name  => 'GtkTreeItem',

       super => 'GtkItem',

       inits => { 'gtk_tree_item_new'           => { in  => [],
                                                     out => 'GtkWidget*' },
                  'gtk_tree_item_new_with_label'=> { in  => ['gchar*'],
                                                     out => 'GtkWidget*' }
              },

       meths => { 'gtk_tree_item_collapse'      => { in  => ['GtkTreeItem*'] },
                  'gtk_tree_item_deselect'      => { in  => ['GtkTreeItem*'] },
                  'gtk_tree_item_expand'        => { in  => ['GtkTreeItem*'] },
                  'gtk_tree_item_remove_subtree'=> { in  => ['GtkTreeItem*'] },
                  'gtk_tree_item_select'        => { in  => ['GtkTreeItem*'] },
                  'gtk_tree_item_set_subtree'   => { in  => ['GtkTreeItem*','!GtkWidget*'] },
              }
   }
     );
