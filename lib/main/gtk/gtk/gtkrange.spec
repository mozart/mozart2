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
     { name  => 'GtkRange',

       super => 'Gtkwidget',

       args  => { 'update_policy'                      => '%GtkUpdateType' },

       meths => { 'gtk_range_get_adjustment'           => { in  => ['GtkRange*'],
                                                            out => 'GtkAdjustment*' },
                  'gtk_range_set_update_policy'        => { in  => ['GtkRange*',
                                                                    '%GtkUpdateType'] },
                  'gtk_range_set_adjustment'           => { in  => ['GtkRange*',
                                                                    '!GtkAdjustment*'] },
                  'gtk_range_draw_background'          => { in  => ['GtkRange*'] },
                  'gtk_range_draw_trough'              => { in  => ['GtkRange*'] },
                  'gtk_range_draw_slider'              => { in  => ['GtkRange*'] },
                  'gtk_range_draw_step_forw'           => { in  => ['GtkRange*'] },
                  'gtk_range_draw_step_back'           => { in  => ['GtkRange*'] },
                  'gtk_range_slider_update'            => { in  => ['GtkRange*'] },
                  'gtk_range_trough_click'             => { in  => ['GtkRange*',
                                                                    'gint',
                                                                    'gint',
                                                                    'gfloat*'],
                                                            out => 'gint' },
                  'gtk_range_default_hslider_update'   => { in  => ['GtkRange*'] },
                  'gtk_range_default_vslider_update'   => { in  => ['GtkRange*'] },
                  'gtk_range_default_htrough_click'    => { in  => ['GtkRange*',
                                                                    'gint',
                                                                    'gint',
                                                                    'gfloat*'],
                                                            out => 'gint' },
                  'gtk_range_default_vtrough_click'    => { in  => ['GtkRange*',
                                                                    'gint',
                                                                    'gint',
                                                                    'gfloat*'],
                                                            out => 'gint' },
                  'gtk_range_default_hmotion'          => { in  => ['GtkRange*',
                                                                    'gint',
                                                                    'gint'] },
                  'gtk_range_default_vmotion'          => { in  => ['GtkRange*',
                                                                    'gint',
                                                                    'gint'] },
                  'gtk_range_clear_background'         => { in  => ['GtkRange*'] } }}
     );
