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
%% Representation mode - atoms 'tree', 'graph' or 'minGraph';
BrowserRepMode               = browserRepMode

%%
%% Extensions - booleans;
BrowserChunkFields           = browserChunkFields
BrowserNamesAndProcsShort    = browserNamesAndProcsShort

%%
%% A special representatio type - show virtual strings as strings;
BrowserVirtualStrings        = browserVirtualStrings

%%
%% Fonts - records of the shape
%%    font(size:Size wght:Weight)
%% where 'Size' is an integer out of 10,12,14,18 and 24, and
%% 'Weight' is an atom out of 'medium' and 'bold'.
%% Normally, Browser takes matching Adobe courier fonts;
BrowserFont                  = browserFont

%%
%% Buffer size - non-negative integers;
BrowserBufferSize            = browserBufferSize

%%
%% Separators between buffer entries - boolean;
BrowserSeparators            = browserSeparators

%%
%% Layout mode - boolean;
BrowserRecordFieldsAligned   = browserRecordFieldsAligned
