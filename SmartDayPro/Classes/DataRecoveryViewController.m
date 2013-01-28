//
//  DataRecoveryViewController.m
//  SmartDayPro
//
//  Created by Left Coast Logic on 1/23/13.
//  Copyright (c) 2013 Left Coast Logic. All rights reserved.
//

#import "DataRecoveryViewController.h"

#import "Common.h"

#import "DBManager.h"
#import "SDWSync.h"

@interface DataRecoveryViewController ()

@end

@implementation DataRecoveryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void) sync1way2SDW
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [[SDWSync getInstance] initBackground1WayPush];
}

- (void) sync1way2SD
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [[DBManager getInstance] cleanDB];
    
    [[SDWSync getInstance] initBackground1WayGet];
}

- (void)alertView:(UIAlertView *)alertVw clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertVw.tag == -10000 && buttonIndex != 0) //not Cancel
	{
        [self sync1way2SDW];
	}
	else if (alertVw.tag == -10001 && buttonIndex != 0) //not Cancel
	{
        [self sync1way2SD];
	}
}

- (void) confirmSync1way2SDW:(id) sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_warningText message:_deleteAllMySDDataConfirmation delegate:self cancelButtonTitle:_cancelText otherButtonTitles:_okText,nil];
    alertView.tag = -10000;
    
    [alertView show];
    [alertView release];
    
}

- (void) confirmSync1way2SD:(id) sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_warningText message:_deleteAllSDDataConfirmation delegate:self cancelButtonTitle:_cancelText otherButtonTitles:_okText,nil];
    
    alertView.tag = -10001;
    
    [alertView show];
    [alertView release];
}

#pragma mark View

- (void) loadView
{
    CGRect frm = CGRectZero;
    frm.size = [Common getScreenSize];
    
    UIView *contentView = [[UIView alloc] initWithFrame:frm];
    contentView.backgroundColor = [UIColor darkGrayColor];
    
    self.view = contentView;
    [contentView release];
    
    settingTableView = [[UITableView alloc] initWithFrame:contentView.bounds style:UITableViewStyleGrouped];
	settingTableView.delegate = self;
	settingTableView.dataSource = self;
	
	[contentView addSubview:settingTableView];
	[settingTableView release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.title = _dataRecovery;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section)
    {
		case 0:
			return _dataRecoveryHint;
	}
    
	return @"";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	else
	{
		for(UIView *view in cell.contentView.subviews)
		{
			if(view.tag >= 10000)
			{
				[view removeFromSuperview];
			}
		}
	}
    
    // Set up the cell...
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = @"";
	cell.textLabel.backgroundColor = [UIColor clearColor];
    
    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row == 0)
            {
                UIButton *fromSDButton = [Common createButton:@""
                                                   buttonType:UIButtonTypeCustom
                                                        frame:CGRectMake(80, 5, 135, 60)
                                                   titleColor:[UIColor whiteColor]
                                                       target:self
                                                     selector:@selector(confirmSync1way2SDW:)
                                             normalStateImage:@"replace_SDtomSD.png"
                                           selectedStateImage:nil];
                fromSDButton.tag = 10000;
                [cell.contentView addSubview:fromSDButton];
                
            }
        }
            break;
        case 1:
        {
            if (indexPath.row == 0)
            {
                UIButton *toSDButton = [Common createButton:@""
                                                 buttonType:UIButtonTypeCustom
                                                      frame:CGRectMake(80, 5, 135, 60)
                                                 titleColor:[UIColor whiteColor]
                                                     target:self
                                                   selector:@selector(confirmSync1way2SD:)
                                           normalStateImage:@"replace_mSDtoSD.png"
                                         selectedStateImage:nil];
                toSDButton.tag = 11000;
                [cell.contentView addSubview:toSDButton];
            }
            
        }
            break;
    }
    
    return cell;
}

@end