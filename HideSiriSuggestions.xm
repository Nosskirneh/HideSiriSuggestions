#define prefPath [NSString stringWithFormat:@"%@/Library/Preferences/se.nosskirneh.hidesirisuggestions.plist", NSHomeDirectory()]
#define ClassName(x) NSStringFromClass([x class])

// iOS 9
@interface SPSearchResult : NSObject
@property (nonatomic, strong, readwrite) NSString *bundleID;
@end
// ---

// iOS 10 +
@interface _DECItem : NSObject
@property (readonly) NSString *bundleIdentifier;
@end

@interface _DECSearchResult : NSObject
@property (readonly) _DECItem *item;
@end
// ---

NSArray *modifyResults(NSArray *_results) {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    if (preferences && preferences.count > 0) {
        NSMutableArray *results = [_results mutableCopy];

        for (id result in _results) {
            if (([ClassName(result) isEqualToString:@"SPSearchResult"] && preferences[((SPSearchResult *) result).bundleID]) ||
                ([ClassName(result) isEqualToString:@"_DECSearchResult"] && preferences[((_DECSearchResult *) result).item.bundleIdentifier])) {
                [results removeObject:result];
            }
        }

        return [results copy];
    }

    return nil;
}

%hook SearchUIMultiResultTableViewCell

- (void)updateWithResults:(NSArray *)_results {
    NSArray *results = modifyResults(_results);
    if (results) {
        return %orig(results);
    }

    %orig;
}

%end


%hook SearchUISimpleMultiResultTableViewCell

- (void)updateWithResults:(NSArray *)_results {
    NSArray *results = modifyResults(_results);
    if (results) {
        return %orig(results);
    }

    %orig;
}

%end
