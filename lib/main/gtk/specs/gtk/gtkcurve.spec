# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$ by $Author$
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
     { name  => 'GtkCurve',

       super => 'GtkDrawingArea',

       inits => { 'gtk_curve_new'                  => { out => 'GtkWidget*' }},

       meths => { 'gtk_curve_reset'                => { in  => ['GtkCurve*'] },
                  'gtk_curve_set_gamma'            => { in  => ['GtkCurve*',
                                                                'gfloat'] },
                  'gtk_curve_set_range'            => { in  => ['GtkCurve*',
                                                                'gfloat',
                                                                'gfloat',
                                                                'gfloat',
                                                                'gfloat'] },
                  'gtk_curve_get_vector'           => { in  => ['GtkCurve*',
                                                                'int',
                                                                'gfloat[]'] },
                  'gtk_curve_set_vector'           => { in  => ['GtkCurve*',
                                                                'gint',
                                                                'gfloat[]'] },
                  'gtk_curve_set_curve_type'       => { in  => ['GtkCurve*',
                                                                '%GtkCurveType'] } }}
     );
