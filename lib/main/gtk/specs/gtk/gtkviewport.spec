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
     { name  => 'GtkViewport',

       super => 'GtkBin',

       args  => { 'hadjustment'                   => 'GtkAdjustment*',
                  'vadjustment'                   => 'GtkAdjustment*',
                  'shadow_type'                   => 'GtkShadowType' },

       inits => { 'gtk_viewport_new'              => { in  => ['^GtkAdjustment*',
                                                               '^GtkAdjustment*'],
                                                       out => 'GtkWidget*' } },

       meths => { 'gtk_viewport_get_hadjustment'  => { in  => ['GtkViewport*'],
                                                       out => 'GtkAdjustment*' },
                  'gtk_viewport_get_vadjustment'  => { in  => ['GtkViewport*'],
                                                       out => 'GtkAdjustment*' },
                  'gtk_viewport_set_hadjustment'  => { in  => ['GtkViewport*',
                                                               '!GtkAdjustment*'] },
                  'gtk_viewport_set_vadjustment'  => { in  => ['GtkViewport*',
                                                               '!GtkAdjustment*'] },
                  'gtk_viewport_set_shadow_type'  => { in  => ['GtkViewport*',
                                                               '%GtkShadowType'] } }}
     );
