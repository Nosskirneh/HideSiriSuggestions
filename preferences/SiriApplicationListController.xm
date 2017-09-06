#import "SiriApplicationListController.h"
#import <Preferences/PSSpecifier.h>
#import <AppList/AppList.h>

#define prefPath [NSString stringWithFormat:@"%@/Library/Preferences/se.nosskirneh.hidesirisuggestions.plist", NSHomeDirectory()]
#define notify(x) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)x, NULL, NULL, YES)

@implementation SiriApplicationListController

- (id)specifiers {
	if (_specifiers == nil) {
        specifiers = [[NSMutableArray alloc] init];
        PSSpecifier *spec;

        // System applications
        spec = [PSSpecifier groupSpecifierWithHeader:@"System Applications" footer:nil];
        [specifiers addObject:spec];
        specifiers = [self addApplications:YES];

        // User applications
        spec = [PSSpecifier groupSpecifierWithHeader:@"User Applications" footer:nil];
        [specifiers addObject:spec];
        specifiers = [self addApplications:NO];

        _specifiers = [[NSArray arrayWithArray:specifiers] retain];
    }

	return _specifiers;
}

- (NSMutableArray *)addApplications:(BOOL)systemApps {
    NSArray *sortedDisplayIdentifiers;
    NSString *predStr = systemApps ? @"isSystemApplication = TRUE" : @"isSystemApplication = FALSE";
    NSDictionary *applications = [[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:predStr]
                                                                                     onlyVisible:YES
                                                                          titleSortedIdentifiers:&sortedDisplayIdentifiers];
    // Sort the array
    NSArray *orderedKeys = [applications keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj1 compare:obj2];
    }];

    // Add each application as a switch
    for (NSString *key in orderedKeys) {
        PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:applications[key]
                                                           target:self
                                                              set:@selector(setPreferenceValue:specifier:)
                                                              get:@selector(readPreferenceValue:)
                                                           detail:Nil
                                                             cell:PSSwitchCell
                                                             edit:Nil];
        [spec setProperty:key forKey:@"key"];
        [spec setProperty:[NSNumber numberWithBool:NO] forKey:@"default"];

        UIImage *icon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:key];
        [spec setProperty:icon forKey:@"iconImage"];

        [specifiers addObject:spec];
    }

    return specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    NSString *key = [specifier propertyForKey:@"key"];

    if (preferences[key]) {
        return preferences[key];
    }

    return specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
    if (!preferences) preferences = [[NSMutableDictionary alloc] init];
    NSString *key = [specifier propertyForKey:@"key"];

    if ([value isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [preferences removeObjectForKey:key];
    } else if ([value isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        [preferences setObject:value forKey:key];
    }

    [preferences writeToFile:prefPath atomically:YES];
}

@end
