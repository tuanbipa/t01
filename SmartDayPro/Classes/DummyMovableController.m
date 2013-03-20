//
//  DummyMovableController.m
//  SmartDayPro
//
//  Created by Left Coast Logic on 3/18/13.
//  Copyright (c) 2013 Left Coast Logic. All rights reserved.
//

#import "DummyMovableController.h"

#import "Common.h"
#import "Task.h"

#import "ContentView.h"
#import "TaskView.h"
#import "PlanView.h"

#import "AbstractSDViewController.h"

extern AbstractSDViewController *_abstractViewCtrler;

@implementation DummyMovableController

- (CGRect) getMovableRect:(UIView *)view
{
    return [view.superview convertRect:view.frame toView:_abstractViewCtrler.contentView];
}

- (void) beginMove:(MovableView *)view
{
    [_abstractViewCtrler deselect];
    
    [super beginMove:view];
    
    CGRect frm = [self getMovableRect:view];
    
    if ([view isKindOfClass:[TaskView class]])
    {
        TaskView *dummyTaskView = [[TaskView alloc] initWithFrame:frm];
        
        TaskView *tv = (TaskView *) view;
        
        dummyTaskView.starEnable = tv.starEnable;
        dummyTaskView.listStyle = tv.listStyle;
        dummyTaskView.showListBorder = YES;
        
        dummyView = dummyTaskView;
        
        dummyTaskView.task = tv.task;
    }
    else if ([view isKindOfClass:[PlanView class]])
    {
        PlanView *dummyPlanView = [[PlanView alloc] initWithFrame:frm];
        dummyPlanView.listStyle = YES;
        dummyPlanView.listType = ((PlanView *)view).listType;
        
        dummyView = dummyPlanView;
        
        dummyPlanView.project = ((PlanView *)view).project;
    }
    
    [_abstractViewCtrler.contentView addSubview:dummyView];
    [dummyView release];
    
    self.activeMovableView.hidden = YES;
    
}

-(void)move:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.activeMovableView == nil)
	{
		return;
	}
    
    [super move:touches withEvent:event];
    
    dummyView.frame = [self getMovableRect:self.activeMovableView];
}

-(void) endMove:(MovableView *)view
{
    [self unseparate];
    
    self.activeMovableView.hidden = NO;
    
    [self enableScroll:YES container:self.activeMovableView.superview];
    
    dummyView.hidden = YES;
    
    if (dummyView != nil && [dummyView superview])
    {
        [super endMove:view];
        
        [dummyView removeFromSuperview];
        
        dummyView = nil;
    }
}

@end