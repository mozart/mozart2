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
     { name  => 'GtkFrame',

       super => 'GtkBin',

       args  => { 'label'                                      => 'gchar *',
                  'label_xalign'                               => 'gfloat',
                  'label_yalign'                               => 'gfloat',
                  'shadow'                                     => '%GtkShadowType' },

       inits => { 'gtk_frame_new'                              => { in  => ['const gchar*'],
                                                                    out => 'GtkWidget*' } },

       meths => { 'gtk_frame_set_label'                        => { in  => ['GtkFrame*',
                                                                            'const gchar*'] },
                  'gtk_frame_set_label_align'                  => { in  => ['GtkFrame*',
                                                                            'gfloat',
                                                                            'gfloat'] },
                  'gtk_frame_set_shadow_type'                  => { in  => ['GtkFrame*',
                                                                            '%GtkShadowType'] } }}
     );
