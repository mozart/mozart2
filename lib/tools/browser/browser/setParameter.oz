%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Parameter names;
%%%  This file should be included in a declaration part
%%% (i.e. local ... \insert 'constants.oz' ... in ... end)
%%%
%%%

%%
%%  Values for boolean parameters are 'True' and 'False';
%%

%%
%%  Window size - positive integeres;
BrowserXSize                 = browserXSize
BrowserYSize                 = browserYSize
BrowserXMinSize              = browserXMinSize
BrowserYMinSize              = browserYMinSize

%%
%%  (Browsed) term's sizes - positive integers;
BrowserDepth                 = browserDepth
BrowserWidth                 = browserWidth
BrowserNodes                 = browserNodes

%%
%%  'Expansion increments' - positive integers;
BrowserDepthInc              = browserDepthInc
BrowserWidthInc              = browserWidthInc

%%
%%  Scrolling - booleans;
BrowserScrolling             = browserScrolling

%%
%%  Extensions - booleans;
BrowserCoreferences          = browserCoreferences
BrowserCycles                = browserCycles
BrowserPrivateFields         = browserPrivateFields
BrowserVirtualStrings        = browserVirtualStrings

%%
%%  Layout modes - booleans;
BrowserVariablesAligned      = browserVariablesAligned
BrowserRecordFieldsAligned   = browserRecordFieldsAligned
BrowserListsFlat             = browserListsFlat
BrowserNamesAndProcsShort    = browserNamesAndProcsShort
BrowserPrimitiveTermsActive  = browserPrimitiveTermsActive

%%
%%  Fonts - atoms from beneath;
BrowserFont                  = browserFont
%%  Known fonts are '6x10', '6x12', '6x13bold', '6x13', '7x13bold', '7x13',
%% '8x13bold', '8x13', '9x15bold', '9x15', and '10x20';

%%
%%  Are there menus/buttons? - booleans;
BrowserAreButtons            = browserAreButtons
BrowserAreMenus              = browserAreMenus

%%  'all' mode - booleans;
BrowserShowAll               = browserShowAll

%%  Buffer size - non-negative integers;
BrowserBufferSize            = browserBufferSize
