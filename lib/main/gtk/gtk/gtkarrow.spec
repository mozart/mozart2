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
     { name  => 'GtkArrow',

       super => 'GtkMisc',

       args  => { 'arrow_type'                     => 'GtkArrowType',
                  'shadow_type'                    => 'GtkShadowType' },

       inits => { 'gtk_arrow_new'                  => { in  => ['GtkArrowType',
                                                                'GthShadowType'],
                                                        out => 'GtkWidget*' }},

       meths => { 'gtk_arrow_set'                  => { in  => ['GtkArrow*',
                                                                'GtkArrowType',
                                                                'GtkShadowType'] } }}
     );
