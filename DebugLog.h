//
//  DebugLog.h
//  NSLog-ing my way.
//
//  DebugLog()			print Class, Selector, Comment				(ObjC only)
//  DebugLog0			print Class, Selector						(ObjC only)
//  DebugLogMore()		print Filename, Line, Signature, Comment	(ObjC only)
//  DebugLogC(s, ...)	print Comment								(C, ObjC)
//
//  Sticktron 2014
//
//#define DEBUG

#ifdef DEBUG

// Default Prefix
#ifndef DEBUG_PREFIX
	#define DEBUG_PREFIX @"[Velox]"
#endif


// Print styles

#define DebugLog(s, ...) \
	NSLog(@"%@ %@::%@ >> %@", DEBUG_PREFIX, \
		NSStringFromClass([self class]), \
		NSStringFromSelector(_cmd), \
		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
	)

#define DebugLog0 \
	NSLog(@"%@ %@::%@", DEBUG_PREFIX, \
		NSStringFromClass([self class]), \
		NSStringFromSelector(_cmd) \
	)

#define DebugLogC(s, ...) \
	NSLog(@"%@ >> %@", DEBUG_PREFIX, \
		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
	)

#else

// Ignore macros
#define DebugLog(s, ...)
#define DebugLog0
#define DebugLogC(s, ...)
//#define DebugLogMore(s, ...)

#endif
