#import "AppDelegate.h"
#import "CatHolic-Swift.h"
#import <CoreServices/CoreServices.h>

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSArray<NSImage *> *catFrames;
@property (nonatomic, strong) NSArray<NSImage *> *ssuaFrames;
@property (nonatomic, strong) NSArray<NSImage *> *dinoFrames;
@property (nonatomic, strong) NSArray<NSNumber *> *ssuaFrameSequence;
@property (nonatomic, assign) NSInteger currentFrame;
@property (nonatomic, strong) NSTimer *animationTimer;
@end

@implementation AppDelegate

#pragma mark - Lifecycle
- (void)awakeFromNib {
    [super awakeFromNib];
    [self loadSavedCharacterType];
    [self setupStatusItem];
    [self setupCatFrames];
    [self startAnimation];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    // 첫 실행 시 자동 시작 설정
    [self setupAutoLaunchOnFirstRun];
}

- (void)dealloc {
    [self stopAnimation];
    if (self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    }
}

#pragma mark - Setup Methods
- (void)setupStatusItem {
    CGFloat width = 28.0;
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    
    if (!self.statusItem) {
        NSLog(@"Failed to create status item");
        return;
    }
    
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:[self createMenu]];
    [self.statusItem setToolTip:@"CatHolic - CPU Monitoring"];
}

- (NSMenu *)createMenu {
    NSMenu *menu = [[NSMenu alloc] init];
    
    // CatHolic 정보
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"CatHolic"
                                                       action:@selector(showAbout:)
                                                keyEquivalent:@""];
    [aboutItem setTarget:self];
    [menu addItem:aboutItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 캐릭터 선택 서브메뉴
    NSMenuItem *characterMenuItem = [[NSMenuItem alloc] initWithTitle:@"Choose Theme"
                                                              action:nil
                                                       keyEquivalent:@""];
    NSMenu *characterSubmenu = [[NSMenu alloc] init];
    
    // POPCAT 메뉴 아이템
    NSMenuItem *catItem = [[NSMenuItem alloc] initWithTitle:@"Pop Cat"
                                                     action:@selector(selectCharacter:)
                                              keyEquivalent:@""];
    [catItem setTarget:self];
    [catItem setTag:CharacterTypeCat];
    [catItem setState:(self.currentCharacterType == CharacterTypeCat) ? NSControlStateValueOn : NSControlStateValueOff];
    [characterSubmenu addItem:catItem];
    
    // 슝슝이 메뉴 아이템
    NSMenuItem *ssuaItem = [[NSMenuItem alloc] initWithTitle:@"Shxxng"
                                                       action:@selector(selectCharacter:)
                                                keyEquivalent:@""];
    [ssuaItem setTarget:self];
    [ssuaItem setTag:CharacterTypeSsua];
    [ssuaItem setState:(self.currentCharacterType == CharacterTypeSsua) ? NSControlStateValueOn : NSControlStateValueOff];
    [characterSubmenu addItem:ssuaItem];
    
    // 세번째 메뉴 아이템
    /*
    NSMenuItem *dinoItem = [[NSMenuItem alloc] initWithTitle:@"Dino"
                                                      action:@selector(selectCharacter:)
                                               keyEquivalent:@""];
    [dinoItem setTarget:self];
    [dinoItem setTag:CharacterTypeDino];
    [dinoItem setState:(self.currentCharacterType == CharacterTypeDino) ? NSControlStateValueOn : NSControlStateValueOff];
    [characterSubmenu addItem:dinoItem];
    */
    
    [characterMenuItem setSubmenu:characterSubmenu];
    [menu addItem:characterMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 자동 시작 토글
    NSMenuItem *autoLaunchItem = [[NSMenuItem alloc] initWithTitle:@"Start at Login"
                                                            action:@selector(toggleAutoLaunch:)
                                                     keyEquivalent:@""];
    [autoLaunchItem setTarget:self];
    [autoLaunchItem setState:[self isAutoLaunchEnabled] ? NSControlStateValueOn : NSControlStateValueOff];
    [menu addItem:autoLaunchItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 종료 메뉴
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Exit"
                                                      action:@selector(quitApplication:)
                                               keyEquivalent:@"q"];
    [quitItem setTarget:self];
    [menu addItem:quitItem];
    
    return menu;
}

- (void)setupCatFrames {
    // POPCAT 프레임 설정 (cat 폴더에서 로드)
    NSImage *catFrame0 = [NSImage imageNamed:@"cat_page0"];
    NSImage *catFrame1 = [NSImage imageNamed:@"cat_page1"];
    
    // SSUA 프레임 설정 (ssua 폴더에서 로드)
    NSImage *ssuaFrame0 = [NSImage imageNamed:@"ssua_page0"];
    NSImage *ssuaFrame1 = [NSImage imageNamed:@"ssua_page1"];
    NSImage *ssuaFrame2 = [NSImage imageNamed:@"ssua_page2"];
    
    // 세번째 캐릭터 프레임 설정
    /*
    NSMutableArray *dinoFrameArray = [NSMutableArray array];
    for (int i = 0; i <= 11; i++) {
        NSString *frameName = [NSString stringWithFormat:@"frame_%03d", i];
        NSImage *frame = [NSImage imageNamed:frameName];
        if (frame) {
            [dinoFrameArray addObject:frame];
        }
    }
    */
    
    if (!catFrame0 || !catFrame1) {
        NSLog(@"Warning: Cat animation images not found");
        self.catFrames = @[];
    } else {
        self.catFrames = @[catFrame0, catFrame1];
        NSLog(@"Cat frames loaded successfully");
    }
    
    if (!ssuaFrame0 || !ssuaFrame1 || !ssuaFrame2) {
        NSLog(@"Warning: ssua animation images not found");
        self.ssuaFrames = @[];
    } else {
        self.ssuaFrames = @[ssuaFrame0, ssuaFrame1, ssuaFrame2];
        self.ssuaFrameSequence = @[@0, @1, @2, @1, @0];
        NSLog(@"SSUA frames loaded successfully");
    }
    
    /*
    if (dinoFrameArray.count == 0) {
        NSLog(@"Warning: Dino animation images not found");
        self.dinoFrames = @[];
    } else {
        self.dinoFrames = [dinoFrameArray copy];
        NSLog(@"Dino frames loaded successfully: %lu frames", (unsigned long)self.dinoFrames.count);
    }
    */
    
    self.currentFrame = 0;
    [self updateStatusItemImage];
}

#pragma mark - Character Selection
- (void)selectCharacter:(NSMenuItem *)sender {
    CharacterType selectedType = (CharacterType)sender.tag;
    
    // 기존 선택 해제
    NSMenu *parentMenu = [sender parentItem].submenu;
    for (NSMenuItem *item in parentMenu.itemArray) {
        [item setState:NSControlStateValueOff];
    }
    
    // 새로운 선택 표시
    [sender setState:NSControlStateValueOn];
    
    // 캐릭터 타입 변경
    self.currentCharacterType = selectedType;
    self.currentFrame = 0;
    
    // 설정 저장
    [self saveCharacterType];
    
    // 즉시 이미지 업데이트
    [self updateStatusItemImage];
}

- (void)saveCharacterType {
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentCharacterType
                                               forKey:@"selectedCharacterType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSavedCharacterType {
    NSInteger savedType = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedCharacterType"];
    
    // 유효한 값인지 확인
    if (savedType == CharacterTypeCat || savedType == CharacterTypeSsua /* || savedType == CharacterTypeDino */) {
        self.currentCharacterType = (CharacterType)savedType;
    } else {
        self.currentCharacterType = CharacterTypeCat; // 기본값을 Cat으로 변경
    }
}

#pragma mark - Auto Launch Setup
- (void)setupAutoLaunchOnFirstRun {
    // 이미 설정했는지 확인
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasSetupAutoLaunch"]) {
        return;
    }
    
    // 자동 시작 설정
    [self setAutoLaunch:YES];
    
    // 설정 완료 표시
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSetupAutoLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"Auto launch setup completed on first run");
}

- (void)setAutoLaunch:(BOOL)enabled {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    
    // Login Items에 추가/제거
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        if (enabled) {
            // 먼저 기존 항목이 있는지 확인하고 제거
            [self removeFromLoginItems:loginItems withAppPath:appPath];
            
            // 새로 추가
            CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                         kLSSharedFileListItemLast,
                                                                         NULL, NULL, url, NULL, NULL);
            if (item) {
                CFRelease(item);
                NSLog(@"Added to login items successfully");
            } else {
                NSLog(@"Failed to add to login items");
            }
        } else {
            // 제거
            [self removeFromLoginItems:loginItems withAppPath:appPath];
        }
        CFRelease(loginItems);
    }
}

- (void)removeFromLoginItems:(LSSharedFileListRef)loginItems withAppPath:(NSString *)appPath {
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, NULL);
    if (loginItemsArray) {
        CFIndex count = CFArrayGetCount(loginItemsArray);
        for (CFIndex i = 0; i < count; i++) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(loginItemsArray, i);
            CFURLRef url = NULL;
            if (LSSharedFileListItemResolve(item, 0, &url, NULL) == noErr && url) {
                NSString *itemPath = [(__bridge NSURL *)url path];
                if ([itemPath isEqualToString:appPath]) {
                    LSSharedFileListItemRemove(loginItems, item);
                    NSLog(@"Removed from login items");
                    CFRelease(url);
                    break;
                }
                CFRelease(url);
            }
        }
        CFRelease(loginItemsArray);
    }
}

- (BOOL)isAutoLaunchEnabled {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    BOOL found = NO;
    
    if (loginItems) {
        CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, NULL);
        if (loginItemsArray) {
            CFIndex count = CFArrayGetCount(loginItemsArray);
            for (CFIndex i = 0; i < count; i++) {
                LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(loginItemsArray, i);
                CFURLRef url = NULL;
                if (LSSharedFileListItemResolve(item, 0, &url, NULL) == noErr && url) {
                    NSString *itemPath = [(__bridge NSURL *)url path];
                    if ([itemPath isEqualToString:appPath]) {
                        found = YES;
                        CFRelease(url);
                        break;
                    }
                    CFRelease(url);
                }
            }
            CFRelease(loginItemsArray);
        }
        CFRelease(loginItems);
    }
    
    return found;
}

- (void)toggleAutoLaunch:(NSMenuItem *)sender {
    BOOL isEnabled = [self isAutoLaunchEnabled];
    [self setAutoLaunch:!isEnabled];
    [sender setState:(!isEnabled) ? NSControlStateValueOn : NSControlStateValueOff];
    
    NSString *message = (!isEnabled) ? @"Auto launch enabled" : @"Auto launch disabled";
    NSLog(@"%@", message);
}

#pragma mark - Animation Methods
- (void)startAnimation {
    [self scheduleNextAnimation];
}

- (void)scheduleNextAnimation {
    if (self.animationTimer) {
        [self.animationTimer invalidate];
    }
    
    double usage = [CPUMonitor usageValue];
    
    // CPU 사용률에 따른 애니메이션 속도 조정 (0.2초 ~ 2.0초)
    double interval = MAX(0.05, 0.85 - (usage / 100.0) * 3.2);
    
    __weak typeof(self) weakSelf = self;
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          repeats:NO
                                                            block:^(NSTimer *timer) {
        [weakSelf animateFrame];
    }];
}

- (void)animateFrame {
    NSArray<NSImage *> *currentFrames = [self getCurrentFrames];
    
    if (!currentFrames.count) {
        NSLog(@"No frames available for current character type: %ld", (long)self.currentCharacterType);
        return;
    }
    
    if (self.currentCharacterType == CharacterTypeSsua && self.ssuaFrameSequence.count > 0) {
           self.currentFrame = (self.currentFrame + 1) % self.ssuaFrameSequence.count;
       } else {
           self.currentFrame = (self.currentFrame + 1) % currentFrames.count;
       }

   [self updateStatusItemImage];
   [self scheduleNextAnimation];
}

- (NSArray<NSImage *> *)getCurrentFrames {
    switch (self.currentCharacterType) {
        case CharacterTypeCat:
            return self.catFrames;
        case CharacterTypeSsua:
            return self.ssuaFrames;
        /*
        case CharacterTypeDino:
            return self.dinoFrames;
        */
        default:
            return self.catFrames;
    }
}

- (void)updateStatusItemImage {
    if (!self.statusItem) {
        NSLog(@"StatusItem is nil");
        return;
    }

    NSArray<NSImage *> *currentFrames = [self getCurrentFrames];
    if (!currentFrames.count) {
        NSLog(@"No current frames available");
        return;
    }

    NSImage *currentImage;
    if (self.currentCharacterType == CharacterTypeSsua && self.ssuaFrameSequence.count > 0) {
        NSInteger frameIndex = [self.ssuaFrameSequence[self.currentFrame] integerValue];
        currentImage = currentFrames[frameIndex];
    } else {
        currentImage = currentFrames[self.currentFrame];
    }

    NSImage *resizedImage = [currentImage copy];
    [resizedImage setSize:NSMakeSize(27, 27)];

    [self.statusItem setImage:resizedImage];
    NSLog(@"Updated status item image for frame %ld", (long)self.currentFrame);
}

- (void)stopAnimation {
    if (self.animationTimer) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
    }
}

#pragma mark - Helper Methods
- (NSString *)getCurrentCharacterName {
    switch (self.currentCharacterType) {
        case CharacterTypeCat:
            return @"Pop Cat";
        case CharacterTypeSsua:
            return @"Shxxng";
        /*
        case CharacterTypeDino:
            return @"Dino";
        */
        default:
            return @"Pop Cat";
    }
}

#pragma mark - Menu Actions
- (void)showAbout:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"@CatHolic"];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *currentCharacter = [self getCurrentCharacterName];
    NSString *infoText = [NSString stringWithFormat:@"Current Theme: %@\n\nThis adorable app tracks your CPU usage — the busier your CPU, the more the character moves like it's got something tasty!\n\nV%@", currentCharacter, version];
    
    [alert setInformativeText:infoText];
    [alert addButtonWithTitle:@"Confirm"];
    [alert setAlertStyle:NSAlertStyleInformational];

    // 현재 캐릭터의 첫 번째 프레임을 아이콘으로 사용
    NSArray<NSImage *> *currentFrames = [self getCurrentFrames];
    if (currentFrames.count > 0) {
        alert.icon = currentFrames[0];
    }

    [alert runModal];
}

- (void)quitApplication:(NSMenuItem *)sender {
    NSLog(@"Goodbye from CatHolic");
    [NSApp terminate:self];
}

@end
