#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "SiriApplicationListController.h"

#define cellText @"Hide apps"

@interface SearchSettingsController : PSListController
- (void)addAppListIfNeeded;
@end

%hook SearchSettingsController

- (void)viewDidLayoutSubviews {
    %orig;

    [self addAppListIfNeeded];
}

- (void)reloadSpecifiers {
    %orig;
    [self addAppListIfNeeded];
}

%new
- (void)addAppListIfNeeded {
    // Already added specifier?
    if (MSHookIvar<NSMutableDictionary *>(self, "_specifiersByID")[cellText]) {
        return;
    }

    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:cellText
                                                       target:self
                                                          set:NULL
                                                          get:NULL
                                                       detail:NSClassFromString(@"SiriApplicationListController")
                                                         cell:PSLinkCell
                                                         edit:Nil];

    [self insertSpecifier:spec atEndOfGroup:0];
}

%end


%ctor {
    // Load SearchSettings
    dlopen("/System/Library/PreferenceBundles/SearchSettings.bundle/SearchSettings", RTLD_LAZY);
}
