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
     { name  => 'GtkNotebook',

       super => 'GtkContainer',

       args  => { 'page'                                    => 'gint',
                  'tab_pos'                                 => 'GtkPositionType',
                  'tab_border'                              => 'guint',
                  'tab_hborder'                             => 'guint',
                  'tab_vborder'                             => 'guint',
                  'show_tabs'                               => 'gboolean',
                  'show_border'                             => 'gboolean',
                  'scrollable'                              => 'gboolean',
                  'enable_popup'                            => 'gboolean' },

       inits => { 'gtk_notebook_new'                        => { out => 'GtkWidget*' } },

       meths => { 'gtk_notebook_append_page'                => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_append_page_menu'           => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_prepend_page'               => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_prepend_page_menu'          => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_insert_page'                => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*',
                                                                         'gint'] },
                  'gtk_notebook_insert_page_menu'           => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*',
                                                                         'gint'] },
                  'gtk_notebook_remove_page'                => { in  => ['GtkNotebook*',
                                                                         'gint'] },
                  'gtk_notebook_page_num'                   => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*'],
                                                                 out => 'gint' },
                  'gtk_notebook_set_page'                   => { in  => ['GtkNotebook*',
                                                                         'gint'] },
                  'gtk_notebook_next_page'                  => { in  => ['GtkNotebook*'] },
                  'gtk_notebook_prev_page'                  => { in  => ['GtkNotebook*'] },
                  'gtk_notebook_reorder_child'              => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         'gint'] },
                  'gtk_notebook_set_tab_pos'                => { in  => ['GtkNotebook*',
                                                                         'GtkPositionType'] },
                  'gtk_notebook_set_show_tabs'              => { in  => ['GtkNotebook*',
                                                                         'boolean'] },
                  'gtk_notebook_set_show_border'            => { in  => ['GtkNotebook*',
                                                                         'boolean'] },
                  'gtk_notebook_set_scrollable'             => { in  => ['GtkNotebook*',
                                                                         'boolean'] },
                  'gtk_notebook_set_tab_border'             => { in  => ['GtkNotebook*',
                                                                          'gint'] },
                  'gtk_notebook_popup_enable'               => { in  => ['GtkNotebook*'] },
                  'gtk_notebook_popup_disable'              => { in  => ['GtkNotebook*'] },
                  'gtk_notebook_get_current_page'           => { in  => ['GtkNotebook*'],
                                                                 out => 'gint' },
                  'gtk_notebook_get_menu_label'             => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*'],
                                                                 out => 'GtkWidget*' },
                  'gtk_notebook_get_nth_page'               => { in  => ['GtkNotebook*',
                                                                         'gint'],
                                                                 out => 'GtkWidget*' },
                  'gtk_notebook_get_tab_label'              => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*'],
                                                                 out => 'GtkWidget*' },
                  'gtk_notebook_query_tab_label_packing'    => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         'gboolean*',
                                                                         'gboolean*',
                                                                         'GtkPackType*'] },
                  'gtk_notebook_set_homogeneous_tabs'       => { in  => ['GtkNotebook*',
                                                                         'gboolean'] },
                  'gtk_notebook_set_menu_label'             => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_set_menu_label_text'        => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         'const gchar*'] },
                  'gtk_notebook_set_tab_hborder'            => { in  => ['GtkNotebook*',
                                                                         'guint'] },
                  'gtk_notebook_set_tab_label'              => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         '!GtkWidget*'] },
                  'gtk_notebook_set_tab_label_packing'      => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         'gboolean',
                                                                         'gboolean',
                                                                         'GtkPackType'] },
                  'gtk_notebook_set_tab_label_text'         => { in  => ['GtkNotebook*',
                                                                         '!GtkWidget*',
                                                                         'const gchar*'] },
                  'gtk_notebook_set_tab_vborder'            => { in  => ['GtkNotebook*',
                                                                         'guint'] } }}
     );
