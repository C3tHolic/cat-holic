#import "AppDelegate.h"
#import "CatHolic-Swift.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSArray<NSImage *> *catFrames;
@property (nonatomic, assign) NSInteger currentFrame;
@property (nonatomic, strong) NSTimer *animationTimer;
@end

@implementation AppDelegate

#pragma mark - Lifecycle
- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupStatusItem];
    [self setupCatFrames];
    [self startAnimation];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
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
    
    // 종료 메뉴
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Exit"
                                                      action:@selector(quitApplication:)
                                               keyEquivalent:@"q"];
    [quitItem setTarget:self];
    [menu addItem:quitItem];
    
    return menu;
}

- (void)setupCatFrames {
    NSImage *frame0 = [NSImage imageNamed:@"cat_page0"];
    NSImage *frame1 = [NSImage imageNamed:@"cat_page1"];
    
    if (!frame0 || !frame1) {
        NSLog(@"Warning: Cat animation images not found");
        return;
    }
    
    self.catFrames = @[frame0, frame1];
    self.currentFrame = 0;
    
    [self updateStatusItemImage];
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
    double interval = MAX(0.05, 1.5 - (usage / 100.0) * 1.45);
    
    __weak typeof(self) weakSelf = self;
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          repeats:NO
                                                            block:^(NSTimer *timer) {
        [weakSelf animateFrame];
    }];
}

- (void)animateFrame {
    if (!self.catFrames.count) {
        return;
    }
    
    self.currentFrame = (self.currentFrame + 1) % self.catFrames.count;
    [self updateStatusItemImage];
    [self scheduleNextAnimation];
}

- (void)updateStatusItemImage {
    if (!self.statusItem || !self.catFrames.count) {
        return;
    }
    
    NSImage *currentImage = self.catFrames[self.currentFrame];
    NSImage *resizedImage = [currentImage copy];
    [resizedImage setSize:NSMakeSize(24, 24)];
    
    [self.statusItem setImage:resizedImage];
}

- (void)stopAnimation {
    if (self.animationTimer) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
    }
}

#pragma mark - Menu Actions
- (void)showAbout:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"CatHolic Info"];
    [alert setInformativeText:@"This adorable cat app tracks your CPU usage — the busier your CPU, the more the cat chomps like it’s got something tasty!"];
    [alert addButtonWithTitle:@"Confirm"];
    [alert setAlertStyle:NSAlertStyleInformational];

    alert.icon = [NSImage imageNamed:@"cat_page0"];

    [alert runModal];
}

- (void)quitApplication:(NSMenuItem *)sender {
    NSLog(@"Goodbye from CatHolic");
    [NSApp terminate:self];
}

@end
