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
     { name  => 'GtkTooltips',

       super => 'GtkData',

       inits => { 'gtk_tooltips_new'              => { out => 'GtkWidget*' } },


       meths => { 'gtk_tooltips_enable'           => { in  => ['GtkTooltips*'] },
                  'gtk_tooltips_disable'          => { in  => ['GtkTooltips*'] },
                  'gtk_tooltips_set_delay'        => { in  => ['GtkTooltips*',
                                                               'guint'] },
                  'gtk_tooltips_set_tip'          => { in  => ['GtkTooltips*',
                                                               '!GtkWidget*',
                                                               'const gchar*',
                                                               'const gchar*'] },
                  'gtk_tooltips_set_colors'       => { in  => ['GtkTooltips*',
                                                               '!GdkColor*',
                                                               '!GdkColor*'] },
                  'gtk_tooltips_force_window'     => { in  => ['GtkTooltips*'] } }}
     );
