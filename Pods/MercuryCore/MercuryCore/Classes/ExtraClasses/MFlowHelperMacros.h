//
//  MFlowHelperMacros.h
//

#ifdef DEBUG

	// logs with the function name prepended before the arguments
	#define	MFLOG(args...)			NSLog( @"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: args])

	// marks a log line with pointer, function and line number, good for tracking through methods
	#define	MFLOG_MARK()			NSLog( @"%p: %s (%d)",self, __PRETTY_FUNCTION__, __LINE__)

	// you can pass code inside this macro that will only be compiled and executed if the DEBUG flag is on
    #define DEBUG_ONLY(x) x

    #define DLog(...) NSLog(__VA_ARGS__)

#else
	
	// these stub out the above macros for compiles without the DEBUG flag
	
    #define MFLOG(args...)

	#define	MFLOG_MARK()

    #define DEBUG_ONLY(x)

    #define DLog(...) /* */

#endif


// generally useful

/** 
 Creates a shared instance sudo singleton. This does not strictly enforce the singleton idea so it is ok to user when you want both a defalut instance and the ability to create other instances.
 */
#define SHARED_INSTANCE(classname)\
\
+ (classname *)shared##classname {\
\
    static dispatch_once_t pred;\
    static classname * shared##classname = nil;\
    dispatch_once( &pred, ^{\
        shared##classname = [[self alloc] init]; });\
    return shared##classname;\
}                                                           


// nil out and release an object
#define DESTROY(targ)						do {\
												NSObject* __HELPERMACRO_OLDTARG = (NSObject*)(targ);\
												(targ) = nil;\
												[__HELPERMACRO_OLDTARG release];\
											} while(0)
