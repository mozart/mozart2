%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Parameter names;
%%%  This file should be included in a declaration part
%%% (i.e. local ... \insert 'constants.oz' ... in ... end)
%%%
%%%

%%
%% Values for boolean parameters are 'true' and 'false';
%%

%%
%% Window size - positive integeres;
BrowserXSize                 = browserXSize
BrowserYSize                 = browserYSize
BrowserXMinSize              = browserXMinSize
BrowserYMinSize              = browserYMinSize

%%
%%  (Browsed) term's sizes - positive integers;
BrowserDepth                 = browserDepth
BrowserWidth                 = browserWidth

%%
%%  'Expansion increments' - positive integers;
BrowserDepthInc              = browserDepthInc
BrowserWidthInc              = browserWidthInc

%%
%% Scrolling - boolean;
% BrowserSmoothScrolling       = smoothScrolling

%%
%% Extensions - booleans;
BrowserShowGraph             = browserShowGraph
BrowserShowMinGraph          = browserMinGraph
BrowserChunkFields           = browserChunkFields
BrowserVirtualStrings        = browserVirtualStrings

%%
%% Layout modes - booleans;
BrowserRecordFieldsAligned   = browserRecordFieldsAligned
BrowserNamesAndProcsShort    = browserNamesAndProcsShort

%%
%% Fonts - atoms from beneath;
BrowserFont                  = browserFont
%% Known fonts are:
%% fixed:   '6x10', '6x12', '6x13bold', '6x13', '7x13bold', '7x13',
%%           '8x13bold', '8x13', '9x15bold', '9x15', and '10x20';
%% courier: '24', '24bold', '18', '18bold', '14', '14bold',
%%           '12', '12bold', '10', '10bold';

%% Buffer size - non-negative integers;
BrowserBufferSize            = browserBufferSize
