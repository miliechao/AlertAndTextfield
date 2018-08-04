//
//  ViewController.m
//  AlertAndTextfield
//
//  Created by milichao on 2018/8/3.
//  Copyright © 2018年 milichao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIAlertViewDelegate>

@property(nonatomic, strong) UITextField *inField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton * cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelButton.frame = CGRectMake(100, 100, 80, 44);
    [cancelButton setTitle:@"提示框" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    

}

-(void)cancelButtonClicked
{
    
    UIAlertView * alertView  = [[UIAlertView alloc] initWithTitle:@"请给你的专属音效起个名字吧！" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"保存", nil];
    
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    alertView.delegate = self;
    
    self.inField = [alertView textFieldAtIndex:0];
    
    self.inField.text = @"我的音效1";
    
    [self.inField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [alertView show];

}




-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == 0) {
    
        return;
    
    }else{
        
        
    }
        
    
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if (textField.markedTextRange == nil) { //输入中文时，当英文转为中文后再调用convertToInt::事件
        textField.text = [self convertToInt:textField.text :20];
    }
}

- (NSString *)convertToInt:(NSString *)text :(int)length
{
    int i, n = [text length], l = 0, a = 0, b = 0;
    int len = 0;
    unichar c;
    for (i = 0; i < n; i++) {
        c = [text characterAtIndex:i];
        if (isblank(c)) { // 判断输入的字符是否为空格或者换行
            b++;
        } else if (isascii(c)) { // 判断输入的字符是否为英文
            a++;
        } else { // 判断输入的字符是否为中文
            l++;
        }
        
        len = l * 2 + (int)ceilf((float) (a + b)); // ceilf去最接近的较大整数
        if (len > length) {
            //            [[UIApplication sharedApplication].keyWindow makeToast:[NSString stringWithFormat:@"最多只允许输入%d个英文字符，汉字占两个字符", length] duration:defaultDuration position:@"center"];
            return [text substringToIndex:i];
        }
    }
    if (a == 0 && l == 0) {
        return text;
    }
    
    return text;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
