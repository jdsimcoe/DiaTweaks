#import "CompactCommandBar.h"

NSView *DPCommandBarPart(NSView *commandBar, const char *className) {
    return DPFindView(commandBar, ^BOOL(NSView *view) { return DPIsKind(view, className); });
}

BOOL DPChatLocked(NSView *view) {
    return DPFindView(view, ^BOOL(NSView *v) { return [v.accessibilityLabel hasSuffix:@"only available when you have chat usage"]; }) != nil;
}

NSView *DPCompactToolbar(NSView *commandBar) {
    NSView *toolbar = commandBar ? DPCommandBarPart(commandBar, DPDiaCommandBarToolbar) : nil;
    return DPCompactCommandBar.on && toolbar && DPChatLocked(toolbar) ? toolbar : nil;
}

NSView *DPGoButton(NSView *toolbar) {
    NSStackView *stack = toolbar.subviews.firstObject;
    return [stack isKindOfClass:NSStackView.class] ? stack.views.lastObject : nil;
}

static void DPApplyCompactCommandBar(DPPatch *patch) {
    for (NSView *commandBar in DPFindViews(DPDiaCommandBar)) commandBar.needsLayout = YES;
}

// A command bar that isn't open passes, as does one with chat usage, which keeps its bottom row.
static NSString *DPVerifyCompactCommandBar(DPPatch *patch) {
    for (NSView *commandBar in DPFindViews(DPDiaCommandBar)) {
        NSView *toolbar = DPCommandBarPart(commandBar, DPDiaCommandBarToolbar), *go = DPGoButton(toolbar);
        NSView *input = DPCommandBarPart(commandBar, DPDiaCommandBarInput);
        if (!go || !input || !DPChatLocked(toolbar)) continue;
        NSRect goFrame = [go convertRect:go.bounds toView:input.superview];
        BOOL beside = NSMinY(goFrame) < NSMaxY(input.frame) && NSMaxY(goFrame) > NSMinY(input.frame);
        if (beside != patch->on) return patch->on ? @"Go is still under the input" : @"Go is still beside the input";
    }
    return nil;
}

DP_PATCH(DPCompactCommandBar) {
    .key = @"compactCommandBar",
    .order = 100,
    .title = @"Compact command bar",
    .detail = @"Fit the command bar on one line when adding tabs, files and dictation need chat usage.",
    .symbol = @"rectangle.and.text.magnifyingglass",
    .tint = @"systemCyanColor",
    .classes = DPClasses(DPDiaPopover, DPDiaCommandBar, DPDiaCommandBarInput, DPDiaCommandBarText, DPDiaCommandBarSuggestions, DPDiaCommandBarToolbar),
    .install = DPInstallCommandBarLayout,
    .apply = DPApplyCompactCommandBar,
    .verify = DPVerifyCompactCommandBar,
};
