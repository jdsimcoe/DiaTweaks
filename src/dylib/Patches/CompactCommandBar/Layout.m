#import "CompactCommandBar.h"

static const CGFloat DPCommandBarSpacing = 14;
static char DPCompactedKey;

// The popover sizes itself to the command bar, so it drops the bottom row's height, keeping as much space
// under the input (or the suggestions) as the input has between it and the suggestions.
static void DPPopover_setFrameSize(NSView *self, SEL _cmd, NSSize size) {
    NSView *commandBar = DPCommandBarPart(self, DPDiaCommandBar), *toolbar = DPCompactToolbar(commandBar);
    NSView *input = DPCommandBarPart(commandBar, DPDiaCommandBarInput), *suggestions = DPCommandBarPart(commandBar, DPDiaCommandBarSuggestions);
    if (toolbar && input && suggestions) {
        CGFloat gap = NSMinY(suggestions.frame) - NSMaxY(input.frame), below = NSMinY(input.frame) - gap;
        size.height -= MAX(0, NSHeight(toolbar.frame) - below);
    }
    DPCallOriginal(DPPopover_setFrameSize, self, size);
}

static void DPPopover_setFrameOrigin(NSView *self, SEL _cmd, NSPoint origin) {
    DPCallOriginal(DPPopover_setFrameOrigin, self, origin);
    NSView *commandBar = DPCommandBarPart(self, DPDiaCommandBar);
    if (DPCompactToolbar(commandBar)) commandBar.needsLayout = YES;
}

// Go moves up beside the input, and the row is still full width so it keeps its place at the trailing edge.
// Dia lets the popover run past the top of the window, so Go is centered in the part of the row that shows.
static void DPCommandBar_layout(NSView *self, SEL _cmd) {
    DPCallOriginal(DPCommandBar_layout, self);
    NSView *toolbar = DPCommandBarPart(self, DPDiaCommandBarToolbar);
    NSStackView *stack = toolbar.subviews.firstObject;
    if (![stack isKindOfClass:NSStackView.class]) return;
    BOOL compact = DPCompactToolbar(self) != nil;
    if (!compact && !DPGet(stack, &DPCompactedKey)) return;
    DPSet(stack, &DPCompactedKey, compact ? @YES : nil);
    // Faded rather than hidden: the add tabs button stretches to push Go to the trailing edge.
    for (NSView *view in stack.views)
        if (view != DPGoButton(toolbar) && DPChatLocked(view)) view.alphaValue = !compact;
    NSView *input = DPCommandBarPart(self, DPDiaCommandBarInput), *suggestions = DPCommandBarPart(self, DPDiaCommandBarSuggestions);
    if (!compact || !input || !suggestions || !self.window) return;
    CGFloat gap = NSMinY(suggestions.frame) - NSMaxY(input.frame), rowBottom = NSMinY(suggestions.frame) + NSMinY(input.frame) - gap;
    CGFloat cut = MAX(0, NSMaxY([self convertRect:self.bounds toView:nil]) - NSHeight(self.window.frame));
    NSRect frame = toolbar.frame;
    frame.origin.y = (MIN(cut, NSMinY(input.frame)) + rowBottom - NSHeight(frame)) / 2;
    toolbar.frame = frame;
}

// The text stops short of Go instead of running under it.
static void DPCommandBarInput_layout(NSView *self, SEL _cmd) {
    DPCallOriginal(DPCommandBarInput_layout, self);
    NSView *go = DPGoButton(DPCompactToolbar(self.superview)), *text = DPCommandBarPart(self, DPDiaCommandBarText);
    if (!go || !text) return;
    NSRect frame = text.frame;
    frame.size.width = MAX(0, NSWidth(self.bounds) - NSMinX(frame) - go.intrinsicContentSize.width - 2 * DPCommandBarSpacing);
    text.frame = frame;
}

// The row now lies over the input, so only Go takes clicks.
static NSView *DPCommandBarToolbar_hitTest(NSView *self, SEL _cmd, NSPoint point) {
    NSView *hit = DPCallOriginal(DPCommandBarToolbar_hitTest, self, point), *commandBar = self.superview.superview;
    if (!hit || !DPIsKind(commandBar, DPDiaCommandBar) || !DPCompactToolbar(commandBar)) return hit;
    return [hit isDescendantOf:DPGoButton(self)] ? hit : nil;
}

void DPInstallCommandBarLayout(void) {
    DPHook(DPDiaPopover, @selector(setFrameSize:), (IMP)DPPopover_setFrameSize);
    DPHook(DPDiaPopover, @selector(setFrameOrigin:), (IMP)DPPopover_setFrameOrigin);
    DPHook(DPDiaCommandBar, @selector(layout), (IMP)DPCommandBar_layout);
    DPHook(DPDiaCommandBarInput, @selector(layout), (IMP)DPCommandBarInput_layout);
    DPHook(DPDiaCommandBarToolbar, @selector(hitTest:), (IMP)DPCommandBarToolbar_hitTest);
}
