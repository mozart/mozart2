%  Programming Systems Lab, DFKI Saarbruecken,
%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%%  Author: Konstantin Popov & Co.
%%  (i.e. all people who make proposals, advices and other rats at all:))
%%  Last modified: $Date$ by $Author$
%%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Local constants;
%%%  This file should be included in a declaration part
%%% (i.e. local ... \insert 'constants.oz' ... in ... end)
%%%
%%%

%%
%%  *Real* constants;
%%

%%
%%  INIT value;
%%
InitValue       = {NewName}

%%
%%  Some special values for PseudoObject;
%%

In_Text_Widget  = {NewName}

%%
%%  Types of Terms -
%% should be parametric, because Oz has the strong trend to be modified :))
%%  You have to modify 'terms.oz', 'textWidget.oz' and 'termsStore.oz' if
%% you change types;
%%

%%
%%  group #0: pseudo-term (top-level term);
T_PSTerm        = {NewName}
%%
%%  group #1: atomic values;
T_Atom          = {NewName}
T_Int           = {NewName}
T_Float         = {NewName}
T_Name          = {NewName}
%%
T_Procedure     = {NewName}
T_Cell          = {NewName}
%%
%%  group #2: chunks;
T_Chunk         = {NewName}
T_Object        = {NewName}
T_Class         = {NewName}
%%
%%  group #3: proper "enclosed" structures;
%% well-formed;
T_WFList        = {NewName}
T_Tuple         = {NewName}
T_Record        = {NewName}
T_ORecord       = {NewName}
%%
%%  group #4: "not-enclosed" structures;
%% incomplete or not well-formed;
T_List          = {NewName}
%% optimization: flat representation of the T_(B)List;
T_FList         = {NewName}
T_HashTuple     = {NewName}
%%
%%  group #5: What for a bullsh$t ??!
T_Unknown       = {NewName}
%%
%%  group #6: variables;
%%  special: if a variable is not yet constrained somehow,
%% we say that this is *something* of type T_Variable;
%%  Of course, such operation is not monotonic, but we need it in browser.
T_Variable      = {NewName}
%%  ... and FD variable;
T_FDVariable    = {NewName}
%%  ... and Meta variable;
T_MetaVariable    = {NewName}
%%
%%  group #7: special things;
%%  VERY special: reference;
T_Reference     = {NewName}
%%  Another special: unshown (sub)term (leaf);
T_Shrunken      = {NewName}

%%
%%  There are actually the following parameters in browser's store
%% (these are the names of corresponding features in store)":
%%
StoreTWWidth         = {NewName}
StoreXSize           = {NewName}
StoreXMinSize        = {NewName}
StoreYSize           = {NewName}
StoreYMinSize        = {NewName}
StoreDepth           = {NewName}
StoreNodeNumber      = {NewName}
StoreWidth           = {NewName}
StoreFillStyle       = {NewName}
StoreArityType       = {NewName}
StoreHeavyVars       = {NewName}
StoreFlatLists       = {NewName}
StoreScrolling       = {NewName}
StoreWidthInc        = {NewName}
StoreDepthInc        = {NewName}
StoreCheckStyle      = {NewName}
StoreOnlyCycles      = {NewName}
StoreSmallNames      = {NewName}
StoreAreInactive     = {NewName}
StoreAreVSs          = {NewName}
StoreTWFont          = {NewName}
StoreHistoryLength   = {NewName}
StoreAreButtons      = {NewName}
StoreAreMenus        = {NewName}
StoreOrigWindow      = {NewName}
StoreScreen          = {NewName}
%%
Expanded             = {NewName}
Filled               = {NewName}
AtomicArity          = {NewName}
TrueArity            = {NewName}

%%
%%  (configurable) parameters;
%%

%%
%%  Help file;
%%
IHelpFile   = System.ozHome#'/lib/browser/help.txt'

%%
%%  window(graphic) parameters;
%%
ITWWidth    = 60
ITWHeight   = 20
%% ITitle      = "Modern Real Hacker\'s Browser"
ITitle      = "Oz Browser"
IVTitle     = "Oz Browser: View"
IMTitle     = "Oz Browser: Warnings"
IHTitle     = "Oz Browser: Help"
%% IITitle     = "Modern Browser"
IITitle     = "Oz Browser"
IMITitle    = "Messages"
IHITitle    = "Help"

%% IIBitmap    = '/opt/ps/soft/X/bitmaps/misc/face_angry.xbm'
IIBitmap    = System.ozHome#'/lib/bitmaps/browserIcon.xbm'
%% IMIBitmap   = '/opt/ps/soft/X/bitmaps/std/RIP.xbm'
IMIBitmap   = System.ozHome#'/lib/bitmaps/browserMIcon.xbm'
%%          IIBMask     ?
%%          IIBitmap    '/home/ps-home/popow/prgs/Oz/modernBrowser/icon.xbm'
%%          IMIBitmap   '/home/ps-home/popow/prgs/Oz/modernBrowser/micon.xbm'

%% curosr name (see include file X11/cursorfont.h);
ICursorName = 'hand2'
%%  the following two are in pixels (no subwindows are gridded);
%%  these sizes are used if there is(are) no buttons and/or menus frame(s);
IXMinSize   = 450
IYMinSize   = 300
%%
IXSize      = 500
IYSize      = 350
%%  ... for messages' window (but it is gridded, so - in chars);
IMXMinSize  = 40
IMYMinSize  = 5
%%  ... for help window - the fixed size;
IHXSize     = 550
IHYSize     = 400
%%  colours on text widget;
IBackGround   = 'white'
IForeGround   = 'black'
%%  borders and scrollbars' sizes are in pixels;
IBigBorder    = 3
ISmallBorder  = 2
%%  text widgets are raised, while menus, buttons and scrollbars frames are sunken;
ITextRelief   = raised
IFrameRelief  = sunken
IButtonRelief = raised
%%  width (or height) of scrollbars (pixels);
ISWidth       = 15

%%
%%  default font for text widgets, 'x' and 'y' resolutions for it;
ITWFontUnknown = font(name:'*startup*'
                      font:'-*-*-*-*-*-*-*-*-*-*-*-*-*-1'
                      xRes:0 yRes:0)   % these are just some values!
ITWFont1       = font(name:'8x13' font:'8x13' xRes:8 yRes:13)
ITWFont2       = font(name:'14'
                      font:'-*-courier-medium-r-*-*-14-*-*-*-*-*-*-*'
                      xRes:0 yRes:0)
ITWFont3       = font(name:'*any*'
                      font:'-*-*-*-*-*-*-*-*-*-*-*-*-*-1'
                      xRes:0 yRes:0)   % these are just some values!
IKnownMiscFonts = [font(name:'10x20' font:'10x20' xRes:10 yRes:20)
                   font(name:'9x15' font:'9x15' xRes:9 yRes:15)
                   font(name:'9x15bold' font:'9x15bold' xRes:9 yRes:15)
                   font(name:'8x13' font:'8x13' xRes:8 yRes:13)
                   font(name:'8x13bold' font:'8x13bold' xRes:8 yRes:13)
                   font(name:'7x13' font:'7x13' xRes:7 yRes:13)
                   font(name:'7x13bold' font:'7x13bold' xRes:7 yRes:13)
                   font(name:'6x13' font:'6x13' xRes:6 yRes:13)
                   font(name:'6x13bold' font:'6x13bold' xRes:6 yRes:13)
                   font(name:'6x12' font:'6x12' xRes:6 yRes:12)
                   font(name:'6x10' font:'6x10' xRes:6 yRes:10)
                   font(name:'any'
                        font:'-*-*-*-*-*-*-*-*-*-*-*-*-*-1'
                        xRes:0 yRes:0)]

%%
%%  Note: actually, precise dimentions of the courier fonts are not
%% known (and even more, they depend on many other factors!). So, we
%% just left them unspecified (i.e. == 0).
%%
IKnownCourFonts = [font(name:'24'
                        font:'-*-courier-medium-r-*-*-24-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'24bold'
                        font:'-*-courier-bold-r-*-*-24-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'18'
                        font:'-*-courier-medium-r-*-*-18-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'18bold'
                        font:'-*-courier-bold-r-*-*-18-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'14'
                        font:'-*-courier-medium-r-*-*-14-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'14bold'
                        font:'-*-courier-bold-r-*-*-14-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'12'
                        font:'-*-courier-medium-r-*-*-12-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'12bold'
                        font:'-*-courier-bold-r-*-*-12-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'10'
                        font:'-*-courier-medium-r-*-*-10-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)
                   font(name:'10bold'
                        font:'-*-courier-bold-r-*-*-10-*-*-*-*-*-*-*'
                        xRes:0 yRes:0)]

%%
%% for each font in IKnownFonts must be the feature in IFontMap;
%% IFontMap      = map('10x20': 'lucidasans-italic-18' ...)
%%
%% (external) pads (pixels);
IPad          = 1
IButtonPad    = 1
ITWPad        = 3
%%  initial size of messages' text widget (in cols/lines);
IMWidth       = 45
IMHeight      = 5
%%  width of a button (in cm);
IButtonWidth  = 10

%%
IBFont1       = '-*-lucida-bold-r-*-sans-12-*-*-*-*-*-*-*'
IBFont2       = '-*-courier-bold-r-*-*-12-*-*-*-*-*-*-*'
IBFont3       = '-*-*-*-r-*-*-*-*-*-*-*-*-*-1'
%% ... menu buttons;
IMBWidth      = 10
IMBFont1      = '-*-lucida-bold-i-*-sans-12-*-*-*-*-*-*-*'
IMBFont2      = '-*-courier-bold-*-*-*-12-*-*-*-*-*-*-*'
IMBFont3      = '-*-*-*-i-*-*-*-*-*-*-*-*-*-1'
%%
%% ... menus;
IMFont1       = '-*-lucida-bold-r-*-sans-12-*-*-*-*-*-*-*'
IMFont2       = '-*-courier-bold-r-*-*-12-*-*-*-*-*-*-*'
IMFont3       = '-*-*-*-r-*-*-*-*-*-*-*-*-*-1'
%%
%%% default font: if the specified one is not found;
IReservedFont = '-*-*-*-*-*-*-*-*-*-*-*-*-*-1'

%%
%% offsets for a message window;
IMWXOffset    = 50
IMWYOffset    = 50

%%
%% would the buttons&menus frames come at start?
IAreMenus       = !True
IAreButtons     = !False
IShowAll        = !True

%%
%%  defaults section (for "store");
%%
IDepth          = 15
INodeNumber     = 500
IWidth          = 50
IFillStyle      = Expanded
IArityType      = AtomicArity
IHeavyVars      = !False
IFlatLists      = !True
IScrolling      = !True
ISmallNames     = !True
IAreInactive    = !True
IAreVSs         = !False
%% How many (in depth) terms will be browsed by zoom (by default);
IDepthInc       = 1
%% ... In width;
IWidthInc       = 1
ICheckStyle     = !False
%% setting both 'ICheckStyle' and IOnlyCycles to 'True' means 'corereferences';
IOnlyCycles     = !False
IHistoryLength  = 15

%%
%%  Non-modifiable parameters;
%%
%% how much live elements in terms store list should be for one pruned;
TermsStoreGCRatio  = 10
%% how much a real size of a 'ResizableArray' can be bigger than 'visible' (%);
RArrayRRatio       = 10

%%
%%  Various definitions for debugging;
%%
%\define    DEBUG_BO
\undef     DEBUG_BO
%\define    DEBUG_TO
\undef     DEBUG_TO
%\define    DEBUG_TT
\undef     DEBUG_TT
%\define    DEBUG_TW
\undef     DEBUG_TW
%\define    DEBUG_TI
\undef     DEBUG_TI
%\define    DEBUG_TI_DET
\undef     DEBUG_TI_DET
%\define   DEBUG_METAVAR
\undef    DEBUG_METAVAR
%%
%%  Work-Arounds;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%      Don't change anything below this line!
%%%
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%  spacing between atoms, etc. in output:
%% size of blank, hash, colon, braces and '=';
DSpace          = 1
DDSpace         = 2
DTSpace         = 3
DQSpace         = 4
%%  spacing to subterms of a {record, tuple};
DOffset         = 3

%% max approx;
DReference      = 2
%% 'R?'

%%
%% glues; should be of the same length (DSpace);
%%
DSpaceGlue      = ' '           % DSpace;
DVBarGlue       = '|'
DHashGlue       = "#"           % note: it must be a string!
%%
%% symbols;
DLRBraceS       = '('
DRRBraceS       = ')'
DLSBraceS       = '['
DRSBraceS       = ']'
DEqualS         = '='
DColonS         = ':'
DHatS           = '^'           % I was pretty dumb!
DLCBraceS       = '{'
DRCBraceS       = '}'
%%%
%%
DNameUnshown    = ',,,'         % DTSpace;
DOpenFS         = '...'         % DTSpace;
DUnderscore     = '_'           % DSpace;
DUnshownPFs     = '?'           % DSpace
%%
%%  char values;
CNameDelimiter  = ":".1
BQuote          = "`".1
CharDot         = ".".1
CharSpace       = " ".1
%%

%% big enough:))
DInfinite       = 1000000
