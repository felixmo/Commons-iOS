//
//  LoginViewController.m
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-08.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "LoginViewController.h"
#import "CommonsApp.h"

@interface LoginViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIImageView *logoView;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UILabel *errorLabel;
@property (nonatomic, strong) IBOutlet UIButton *loginBtn;

@property (nonatomic, weak) UITextField *activeField;

- (IBAction)loginButtonPushed:(id)sender;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self registerForKeyboardNotifications];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self unregisterForKeyboardNotifications];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
    
    //Add tap recognizer to scroll view, user can tap other part of scroll view to
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    [self.scrollView addGestureRecognizer:tapRecognizer];
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

//when the keyboard is number pad, there will be not reture key
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

/*
 When user tap on the scroll view, the method is called to disable the keyboard
 */
- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer
{
    [self.activeField resignFirstResponder];
    [self.scrollView removeGestureRecognizer:tapRecognizer];
}


#pragma mark - event of keyboard relative methods

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

-(void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


- (void)keyboardWillShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect frame = self.view.frame;
    
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        frame.size.height -= kbSize.height;
        
    } else
    {
        frame.size.height -= kbSize.width;
    }
    CGPoint scrollPoint = CGPointMake(0.0f, self.loginBtn.frame.origin.y - self.loginBtn.frame.size.height - frame.size.height);
    NSLog(@"%@", NSStringFromCGPoint(scrollPoint));
    [self.scrollView setContentOffset:scrollPoint animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


#pragma mark -

- (IBAction)loginButtonPushed:(id)sender {
    
    CommonsApp *app = CommonsApp.singleton;
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    // Only update & validate user credentials if they have been changed
    if (![app.username isEqualToString:username] || ![app.password isEqualToString:password]) {
        
        // Test credentials to make sure they are valid
        MWApi *mwapi = [app startApi];
        
        [mwapi loginWithUsername:username
                     andPassword:password
           withCookiePersistence:YES
                    onCompletion:^(MWApiResult *loginResult) {
                        
                        NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
                        
                        if (mwapi.isLoggedIn) {
                            // Credentials verified
                            
                            // Save credentials
                            app.username = username;
                            app.password = password;
                            [app saveCredentials];
                            [app refreshHistory];
                            
                            // Dismiss view
                            
                            [self dismissViewControllerAnimated:YES completion:nil];
                            
                        } else {
                            // Credentials invalid
                            
                            NSLog(@"Credentials invalid!");
                            
                            // Erase saved credentials so that the credentials are validated every time they are changed
                            app.username = @"";
                            app.password = @"";
                            [app saveCredentials];
                            
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                                                message:@"Your username and/or password is incorrect"
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"Dismiss"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                        }
                    }
                       onFailure:^(NSError *error) {
                           
                           NSLog(@"Login failed: %@", [error localizedDescription]);
                           
                           UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login failed!"
                                                                               message:[error localizedDescription]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"Dismiss"
                                                                     otherButtonTitles:nil];
                           [alertView show];
                       }];
        
    }
    else {
        // Credentials have not been changed
        
        NSLog(@"Credentials have not been changed.");
        
        // Dismiss view
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }    
}

@end
