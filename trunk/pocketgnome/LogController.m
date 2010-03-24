//
// LogController.m
// Pocket Gnome
//
// Created by benemorius on 12/17/09.
// Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "LogController.h"


@implementation LogController

+ (BOOL) canLog:(char*)type_s, ...
{

//	NSString* type = [NSString stringWithFormat:@"log_%s", type_s];
// Not logging conditions, remove when we no longer need manual supression.
//	return([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: type] boolValue]);

	NSString* type = [NSString stringWithFormat:@"%s", type_s];

	if (type == @"condition") return NO;
	if (type == @"rule") return NO;

	return YES;
}

+ (NSString*) log:(char*)type_s, ...
{
	NSString* type = [NSString stringWithFormat:@"%s", type_s];
	va_list args;
	va_start(args, type_s);
	NSString* format = va_arg(args, NSString*);
	NSMutableString* output = [[NSMutableString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	output = [NSString stringWithFormat:@"[%@] %@", type, output];
	return output;
}

@end