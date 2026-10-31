// Without chat usage, the command bar's bottom row only holds Go and two buttons that can't be used.
#import "StdPatch/StdPatch.h"

extern DPPatch DPCompactCommandBar;

NSView *DPCommandBarPart(NSView *commandBar, const char *className);
BOOL DPChatLocked(NSView *view);
NSView *DPCompactToolbar(NSView *commandBar);  // The bottom row while the patch applies to this command bar, else nil.
NSView *DPGoButton(NSView *toolbar);

// Layout.m
void DPInstallCommandBarLayout(void);
