#import <UIKit/UIKit.h>
#import "Hello4S.h"

@interface HelloViewController : UIViewController
@end

@implementation HelloViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.16 alpha:1.0];

    char greeting[128];
    hello4s_greeting(greeting, sizeof greeting);

    UILabel *title = [[UILabel alloc] init];
    title.text = [NSString stringWithUTF8String:greeting];
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 0;

    UIDevice *device = [UIDevice currentDevice];
    UILabel *detail = [[UILabel alloc] init];
    detail.text = [NSString stringWithFormat:@"%@ %@\n1² + … + 10² = %ld (Swift)\nBuilt with Xcode clang + Embedded Swift for armv7",
                   device.systemName, device.systemVersion, hello4s_sum_of_squares(10)];
    detail.font = [UIFont systemFontOfSize:15];
    detail.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, detail]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[HelloViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
