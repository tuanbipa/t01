//
//  MiniMonthMovableController.m
//  SmartCal
//
//  Created by Left Coast Logic on 5/2/12.
//  Copyright (c) 2012 LCL. All rights reserved.
//

#import "MiniMonthMovableController.h"

//#import "ListMovableController.h"

#import "Common.h"
#import "Settings.h"
#import "TaskManager.h"
#import "DBManager.h"
#import "Task.h"

#import "TaskView.h"
#import "PlanView.h"
#import "ContentView.h"
#import "MiniMonthView.h"
#import "MonthlyCalendarView.h"
#import "FocusView.h"

#import "SmartDayViewController.h"
#import "iPadSmartDayViewController.h"

#import "NoteDetailTableViewController.h"
#import "TaskDetailTableViewController.h"

extern SmartDayViewController *_sdViewCtrler;
extern AbstractSDViewController *_abstractViewCtrler;
extern iPadSmartDayViewController *_iPadSDViewCtrler;

@implementation MiniMonthMovableController

/*
- (CGRect) getMovableRect:(UIView *)view
{
    return [view.superview convertRect:view.frame toView:_abstractViewCtrler.contentView];
}
*/
- (BOOL)checkSeparate:(TaskView *)view
{
    //Task *task = (Task *) view.tag;
    Task *task = view.task;
    
    return ![task checkMustDo];
}

-(void)beginMove:(MovableView *)view
{
    [super beginMove:view];
    
    moveInFocus = NO;
    moveInMM = NO;
}

-(void) endMove:(MovableView *)view
{
    if (moveInMM)
    {
        [self doTaskMovementInMM];
    }
    else if (moveInFocus)
    {
        [self doTaskMovementInFocus];
    }
    else
    {
        [super endMove:view];
    }
}

-(void)move:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.activeMovableView == nil)
	{
		return;
	}
    
    CGRect frm = dummyView.frame;
    
    [super move:touches withEvent:event];

    CGPoint touchPoint = [self.activeMovableView getTouchPoint];
    
    CGPoint p = [self.activeMovableView.superview convertPoint:touchPoint toView:_abstractViewCtrler.contentView];
    
    if ([self.activeMovableView isKindOfClass:[TaskView class]])
    {
        CGRect mmFrm = [self getMovableRect:_abstractViewCtrler.miniMonthView.calView];
        
        moveInMM = CGRectContainsPoint(mmFrm, p) && !_abstractViewCtrler.miniMonthView.hidden;
        
        moveInFocus = NO;
        
        if (_abstractViewCtrler.focusView != nil)
        {
            CGRect focusFrm = [self getMovableRect:_abstractViewCtrler.focusView];
            p = [self.activeMovableView.superview convertPoint:touchPoint toView:_abstractViewCtrler.contentView];
            
            moveInFocus = CGRectContainsPoint(focusFrm, p);
        }
                
    }
    
    if (moveInMM || moveInFocus)
    {
        if (frm.size.width > 100)
        {
            if ([self.activeMovableView isKindOfClass:[TaskView class]])
            {
                ((TaskView *)dummyView).starEnable = NO;
            }
                        
            [dummyView setNeedsDisplay];
        }
        
        frm.origin.x = p.x;
        frm.origin.y = p.y - (moveInMM?40:25);
        
        frm.size.width = (moveInMM?80:160);
        frm.size.height = 25;
        
        if (moveInMM)
        {
            p = [self.activeMovableView.superview convertPoint:touchPoint toView:_abstractViewCtrler.miniMonthView];
            [_abstractViewCtrler.miniMonthView moveToPoint:p];
        }
    }
    else
    {        
        if (frm.size.width <= 160)
        {
            if ([self.activeMovableView isKindOfClass:[TaskView class]])
            {
                TaskView *tv = (TaskView *) self.activeMovableView;
                
                ((TaskView *) dummyView).starEnable = tv.starEnable;
            }
            
            [dummyView setNeedsDisplay];
        }
        
        frm = [self getMovableRect:self.activeMovableView];
    }
    
    dummyView.frame = frm;    
}

- (void) changeTaskDeadline:(Task *)task
{
    DBManager *dbm = [DBManager getInstance];
    
    //Task *task = ((TaskView *) self.activeMovableView).task;
    
    if (task.original != nil)
    {
        task = task.original;
    }    
    
    NSDate *calDate = [_abstractViewCtrler.miniMonthView.calView getSelectedDate];
    
    NSDate *dDate = nil;
    NSDate *deadline = task.deadline;
    
    if (deadline != nil)
    {
        dDate = [[deadline copy] autorelease];
        
        deadline = [[Settings getInstance] getWorkingEndTimeForDate:calDate];
    }
    else 
    {
        deadline = [[Settings getInstance] getWorkingEndTimeForDate:calDate];
    }
    
    task.deadline = deadline;
    
    [task updateDeadlineIntoDB:[dbm getDatabase]];
    
    if (dDate != nil)
    {
        [_abstractViewCtrler.miniMonthView.calView refreshCellByDate:dDate];
    }
    
    [_abstractViewCtrler.miniMonthView.calView refreshCellByDate:calDate];
    
    [[TaskManager getInstance] initSmartListData]; //refresh Must Do list
    
}

- (void) changeEventDate:(Task *)task
{
    //Task *task = ((TaskView *) self.activeMovableView).task;
    
    NSDate *calDate = [_abstractViewCtrler.miniMonthView.calView getSelectedDate];
    
    NSDate *oldDate = [[task.startTime copy] autorelease];
    
    [[TaskManager getInstance] moveTime:[Common copyTimeFromDate:oldDate toDate:calDate] forEvent:task];
    
    if ([task isADE])
    {
        [_abstractViewCtrler.miniMonthView refresh]; 
    }
    else 
    {
        [_abstractViewCtrler.miniMonthView.calView refreshCellByDate:oldDate];
        [_abstractViewCtrler.miniMonthView.calView refreshCellByDate:calDate];
    }
}

- (void) doTaskMovementInFocus
{
    Task *task = ((TaskView *) self.activeMovableView).task;
    
    [[task retain] autorelease];
    
    [super endMove:self.activeMovableView];
    
    if ([task isTask])
    {
        [self changeTaskDeadline:task];
    }
    else if ([task isEvent])
    {
        [self changeEventDate:task];
    }
    else if ([task isNote])
    {
        task.startTime = [Common copyTimeFromDate:task.startTime toDate:[[TaskManager getInstance] today]];
        
        [task updateStartTimeIntoDB:[[DBManager getInstance] getDatabase]];
    }
    
    if ([task isEvent])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EventChangeNotification" object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskChangeNotification" object:nil];
        
        if ([_abstractViewCtrler.focusView checkExpanded])
        {
            [_abstractViewCtrler.focusView refreshData];

            //resize calendar views
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MiniMonthResizeNotification" object:nil];
        }
    }
}

- (void) doTaskMovementInMM
{
    NSDate *calDate = [_abstractViewCtrler.miniMonthView.calView getSelectedDate];
    
    Task *task = ((TaskView *) self.activeMovableView).task;
    
    if ([task isTask])
    {
        NSString *msg = [NSString stringWithFormat:@"%@: %@", _newDeadlineCreatedText, [Common getCalendarDateString:calDate]];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_warningText message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:_editText, _okText, nil];
        
        alertView.tag = -10000;
        
        [alertView show];
        [alertView release];
        
    }    
    else if ([task isEvent])
    {
        NSString *msg = [NSString stringWithFormat:@"%@: %@", _newDateIsText, [Common getCalendarDateString:[Common copyTimeFromDate:task.startTime toDate:calDate]]];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_warningText message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:_editText, _okText, nil];
        
        alertView.tag = -10001;
        
        [alertView show];
        [alertView release];        
    }
    else if ([task isNote])
    {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", _noteAssociatedText, [Common getCalendarDateString:calDate]];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_warningText message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:_editText, _okText, nil];
        
        alertView.tag = -10002;
        
        [alertView show];
        [alertView release];
        
    }
}

- (void)alertView:(UIAlertView *)alertVw clickedButtonAtIndex:(NSInteger)buttonIndex
{
    TaskView *tv = (TaskView *) self.activeMovableView;
    
    Task *task = [[((TaskView *) self.activeMovableView).task retain] autorelease];
    
    [super endMove:self.activeMovableView];
    
    NSDate *calDate = [_abstractViewCtrler.miniMonthView.calView getSelectedDate];
    
    NSDate *visitDate = nil;
    
    BOOL needEdit = NO;

	if (alertVw.tag == -10000)
	{
        switch (buttonIndex) 
        {
            case 0: //Edit
            {
                [self changeTaskDeadline:task];
                
                needEdit = YES;
            }
                break;
                
            case 1: //OK
                [self changeTaskDeadline:task];
                break;
        }
        
	}
	else if (alertVw.tag == -10001)
	{
        switch (buttonIndex) 
        {
            /*case 0: //Visit
            {
                [self changeEventDate:task];
                
                visitDate = [[task.startTime copy] autorelease];
                
            }
                break;*/
            case 0: //Edit
            {
                [self changeEventDate:task];
                
                needEdit = YES;
            }
                break;
            case 1: //OK
                [self changeEventDate:task];
                break;
        }
        
    }
	else if (alertVw.tag == -10002)
	{
        switch (buttonIndex) 
        {
            case 0: //Edit
            {                
                task.startTime = [Common copyTimeFromDate:task.startTime toDate:calDate];
                
                [task updateStartTimeIntoDB:[[DBManager getInstance] getDatabase]];
                
                needEdit = YES;
            }
                break;
            case 1: //OK
            {
                task.startTime = [Common copyTimeFromDate:task.startTime toDate:calDate];
                
                [task updateStartTimeIntoDB:[[DBManager getInstance] getDatabase]];
                
            }
                break;
        }
    }
    
    if (moveInMM)
    {
        [_abstractViewCtrler.miniMonthView jumpToDate:(visitDate != nil?visitDate:calDate)];
        
        if (visitDate != nil)
        {
            [_sdViewCtrler showCalendarView];    
        }
        
        if (needEdit)
        {
            if (task.original != nil && ![task isREException])
            {
                task = task.original;
            }
        
            Task *taskCopy = [[task copy] autorelease];
            
            taskCopy.listSource = task.listSource;
            
            CGRect frm = [_abstractViewCtrler.miniMonthView.calView getRectOfSelectedCellInView:_abstractViewCtrler.contentView];
            
            /*
            if (_iPadSDViewCtrler != nil)
            {
                [_iPadSDViewCtrler editItem:taskCopy inView:tv];
            }
            else if (_sdViewCtrler != nil)
            {
                [_sdViewCtrler editItem:taskCopy];
            }*/
            
            [_abstractViewCtrler editItem:taskCopy inRect:frm];
        }
        else
        {
            if ([task isEvent])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"EventChangeNotification" object:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskChangeNotification" object:nil];
            }
        }
    }
}

@end
