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
     { name  => 'GtkButtonBox',

       super => 'GtkBox',

       meths => { 'gtk_button_box_get_child_size_default'     => { in => ['gint*',
                                                                          'gint*'] },
                  'gtk_button_box_get_child_ipadding_default' => { in => ['gint*',
                                                                          'gint*'] },
                  'gtk_button_box_set_child_size_default'     => { in => ['gint',
                                                                          'gint'] },
                  'gtk_button_box_set_child_ipadding_default' => { in => ['gint',
                                                                          'gint'] },
                  'gtk_button_box_get_spacing'                => { in => ['GtkButtonBox*'],
                                                                   out => 'gint' },
                  'gtk_button_box_get_layout'                 => { in => ['GtkButtonBox*'],
                                                                   out => '%GtkButtonBoxStyle' },
                  'gtk_button_box_get_child_size'             => { in => ['GtkButtonBox*',
                                                                          'gint*',
                                                                          'gint*'] },
                  'gtk_button_box_get_child_ipadding'         => { in => ['GtkButtonBox*',
                                                                          'gint*',
                                                                          'gint*'] },
                  'gtk_button_box_set_spacing'                => { in => ['GtkButtonBox*',
                                                                          'gint'] },
                  'gtk_button_box_set_layout'                 => { in => ['GtkButtonBox*',
                                                                          '%GtkButtonBoxStyle'] },
                  'gtk_button_box_set_child_size'             => { in => ['GtkButtonBox*',
                                                                          'gint',
                                                                          'gint'] },
                  'gtk_button_box_set_child_ipadding'         => { in => ['GtkButtonBox*',
                                                                          'gint',
                                                                          'gint'] },
                  'gtk_button_box_child_requisition'          => { in => ['GtkWidget*',
                                                                          'int*',
                                                                          'int*',
                                                                          'int*'] }}}
     );
