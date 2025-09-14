#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CharacterType) {
    CharacterTypeCat = 0,
    CharacterTypeSsua = 1,
    CharacterTypeDino = 2
};

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) CharacterType currentCharacterType;

@end
