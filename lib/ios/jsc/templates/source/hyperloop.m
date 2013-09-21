/**
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 * This generated code and related technologies are covered by patents
 * or patents pending by Appcelerator, Inc.
 */
#import "hyperloop.h"

//#define LOG_ALLOC_DEALLOC

/**
 * create a JSPrivateObject for storage in a JSObjectRef
 */
JSPrivateObject* HyperloopMakePrivateObjectForID(JSContextRef ctx, id object)
{
#ifdef LOG_ALLOC_DEALLOC
	NSLog(@"HyperloopMakePrivateObjectForID %p, %@",ctx,object);
#endif
	JSPrivateObject *p = (JSPrivateObject*)malloc(sizeof(JSPrivateObject));
	p->object = (void *)object;
	p->type = JSPrivateObjectTypeID;
	p->map = nil;
	p->context = ctx;
	[object retain];
	return p;
}

/**
 * create a JSPrivateObject for storage in a JSObjectRef where the object is a JSBuffer *
 */
JSPrivateObject* HyperloopMakePrivateObjectForJSBuffer(JSBuffer *buffer)
{
	JSPrivateObject *p = (JSPrivateObject*)malloc(sizeof(JSPrivateObject));
	p->object = (void *)buffer;
	p->type = JSPrivateObjectTypeJSBuffer;
	p->map = nil;
	p->context = NULL;
	return p;
}

/**
 * create a JSPrivateObject for storage in a JSObjectRef where the object is a Class
 */
JSPrivateObject* HyperloopMakePrivateObjectForClass(Class cls)
{
	JSPrivateObject *p = (JSPrivateObject*)malloc(sizeof(JSPrivateObject));
	p->object = (void *)cls;
	p->type = JSPrivateObjectTypeClass;
	p->map = nil;
	p->context = NULL;
	return p;
}

/**
 * destroy a JSPrivateObject stored in a JSObjectRef
 */
void HyperloopDestroyPrivateObject(JSObjectRef object)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
#ifdef LOG_ALLOC_DEALLOC
		NSLog(@"HyperloopDestroyPrivateObject %p",p->context);
#endif
		if (p->type == JSPrivateObjectTypeID)
		{
			id object = (id)p->object;
			[object release];
		}
		else if (p->type == JSPrivateObjectTypeJSBuffer)
		{
			JSBuffer *buffer = (JSBuffer*)p->object;
			free(buffer->buffer);
			free(buffer);
			buffer = NULL;
		}
		else if (p->type == JSPrivateObjectTypeClass)
		{
			Class cls = (Class)p->object;
			[cls release];
		}
		if (p->map)
		{
			[p->map removeAllObjects];
			[p->map release];
			p->map=nil;
			JSValueUnprotect(p->context,object);
		}
		if (p->context!=NULL)
		{
			p->context = NULL;
		}
		free(p);
		p = NULL;
		JSObjectSetPrivate(object,0);
	}
}

/**
 * return a JSPrivateObject as an ID (or nil if not of type JSPrivateObjectTypeID)
 */
id HyperloopGetPrivateObjectAsID(JSObjectRef object)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
		if (p->type == JSPrivateObjectTypeID)
		{
			return (id)p->object;
		}
	}
	return nil;
}

/**
 * return a JSPrivateObject as a Class (or nil if not of type JSPrivateObjectTypeID)
 */
Class HyperloopGetPrivateObjectAsClass(JSObjectRef object)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
		if (p->type == JSPrivateObjectTypeClass)
		{
			return (Class)p->object;
		}
	}
	return nil;
}

/**
 * return a JSPrivateObject as a JSBuffer (or NULL if not of type JSPrivateObjectTypeJSBuffer)
 */
JSBuffer* HyperloopGetPrivateObjectAsJSBuffer(JSObjectRef object)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
		if (p->type == JSPrivateObjectTypeJSBuffer)
		{
			return (JSBuffer*)p->object;
		}
	}
	return NULL;
}

/**
 * return true if JSPrivateObject is of type
 */
bool HyperloopPrivateObjectIsType(JSObjectRef object, JSPrivateObjectType type)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
		return p->type == type;
	}
	return false;
}

/**
 * raise an exception
 */
JSValueRef HyperloopMakeException(JSContextRef ctx, const char *error, JSValueRef *exception)
{
	JSStringRef string = JSStringCreateWithUTF8CString(error);
	JSValueRef message = JSValueMakeString(ctx, string);
	JSStringRelease(string);
	*exception = JSObjectMakeError(ctx, 1, &message, 0);
	return JSValueMakeUndefined(ctx);
}

/**
 * return a string representation as a JSValueRef for an id
 */
JSValueRef HyperloopToString(JSContextRef ctx, id object)
{
    NSString *description = [object description];
    JSStringRef descriptionStr = JSStringCreateWithUTF8CString([description UTF8String]);
    JSValueRef result = JSValueMakeString(ctx, descriptionStr);
    JSStringRelease(descriptionStr);
    return result;
}

/**
 * set the owner for an object
 */
void HyperloopSetOwner(JSObjectRef object, id owner)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL)
	{
		BOOL protect = YES;
		if (p->map==nil)
		{
			p->map = [[NSMapTable alloc] init];
		}
		else
		{
			[p->map removeAllObjects];
			protect = NO; // already held
		}
		[p->map setObject:owner forKey:@"o"];
		if (protect)
		{
			JSValueProtect(p->context,object);
		}
	}
}

/**
 * get the owner for an object or nil if no owner or it's been released
 */
id HyperloopGetOwner(JSObjectRef object)
{
	JSPrivateObject *p = (JSPrivateObject*)JSObjectGetPrivate(object);
	if (p!=NULL && p->map)
	{
		id owner = [p->map objectForKey:@"o"];
		if (owner==nil)
		{
			[p->map removeAllObjects];
			p->map = nil;
			JSValueUnprotect(p->context,object);
		}
	}
	return nil;
}

NSData* HyperloopDecompressBuffer (NSData*  _data) 
{
    NSUInteger dataLength = [_data length];
    NSUInteger halfLength = dataLength / 2;

#ifdef DEBUG_COMPRESS
    NSLog(@"decompress called with %d bytes",dataLength);
#endif

    NSMutableData *decompressed = [NSMutableData dataWithLength: dataLength + halfLength];
    BOOL done = NO;
    int status;

    z_stream strm;
    strm.next_in = (Bytef *)[_data bytes];
    strm.avail_in = (uInt)dataLength;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;

    // inflateInit2 knows how to deal with gzip format
    if (inflateInit2(&strm, (15+32)) != Z_OK)
    {
#ifdef DEBUG_COMPRESS
        NSLog(@"decompress inflateInit2 failed");
#endif
        return nil;
    }

    while (!done)
    {
        // extend decompressed if too short
        if (strm.total_out >= [decompressed length])
        {
            [decompressed increaseLengthBy: halfLength];
        }

        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)[decompressed length] - (uInt)strm.total_out;

        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);

        if (status == Z_STREAM_END)
        {
            done = YES;
        }
        else if (status != Z_OK)
        {
            break;
        }
    }

    if (inflateEnd (&strm) != Z_OK || !done)
    {
#ifdef DEBUG_COMPRESS
        NSLog(@"decompress inflateEnd failed");
#endif
        return nil;
    }

    // set actual length
    [decompressed setLength:strm.total_out];

#ifdef DEBUG_COMPRESS
    NSLog(@"decompress returning %ld bytes",strm.total_out);
#endif
    return decompressed;
}

/**
 * attempt to convert a JSValueRef to a NSString
 */
NSString* HyperloopToNSString(JSContextRef ctx, JSValueRef value)
{
    if (JSValueIsString(ctx,value))
    {
        JSStringRef stringRef = JSValueToStringCopy(ctx, value, 0);
        size_t buflen = JSStringGetMaximumUTF8CStringSize(stringRef);
        char buf[buflen];
        buflen = JSStringGetUTF8CString(stringRef, buf, buflen);
        buf[buflen] = '\0';
        NSString *result = [NSString stringWithUTF8String:buf];
        JSStringRelease(stringRef);
        return result;
    }
    else if (JSValueIsNumber(ctx,value))
    {
        double result = JSValueToNumber(ctx,value,0);
        return [[NSNumber numberWithDouble:result] stringValue];
    }
    else if (JSValueIsBoolean(ctx,value))
    {
        bool result = JSValueToBoolean(ctx,value);
        return [[NSNumber numberWithBool:result] stringValue];
    }
    else if (JSValueIsNull(ctx,value) || JSValueIsUndefined(ctx,value))
    {
        return @"<null>";
    }
    else if (JSValueIsObject(ctx,value)) 
    {
    	JSObjectRef objectRef = JSValueToObject(ctx, value, 0);
    	if (HyperloopPrivateObjectIsType(objectRef,JSPrivateObjectTypeID))
    	{
    		id value = HyperloopGetPrivateObjectAsID(objectRef);
    		return [value description];
    	}
    	else if (HyperloopPrivateObjectIsType(objectRef,JSPrivateObjectTypeClass))
    	{
    		Class cls = HyperloopGetPrivateObjectAsClass(objectRef);
    		return NSStringFromClass(cls);
    	}
    	else if (HyperloopPrivateObjectIsType(objectRef,JSPrivateObjectTypeJSBuffer))
    	{
    		return @"JSBuffer";
    	}
    }
    JSStringRef stringRef = JSValueCreateJSONString(ctx, value, 0, 0);
    size_t buflen = JSStringGetMaximumUTF8CStringSize(stringRef);
    char buf[buflen];
    buflen = JSStringGetUTF8CString(stringRef, buf, buflen);
    buf[buflen] = '\0';
    NSString *result = [NSString stringWithUTF8String:buf];
    JSStringRelease(stringRef);
    return result;
}

JSValueRef HyperloopLogger (JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
    if (argumentCount>1) {
        NSMutableArray *array = [NSMutableArray array];
        for (size_t c=0;c<argumentCount;c++)
        {
            [array addObject:HyperloopToNSString(ctx,arguments[c])];
        }
        NSLog(@"%@", [array componentsJoinedByString:@" "]);
    }
    else if (argumentCount>0) {
        NSLog(@"%@",HyperloopToNSString(ctx,arguments[0]));
    }

    return JSValueMakeUndefined(ctx);
}

/**
 * create a hyperloop VM
 */
JSContext* HyperloopCreateVM (NSString *name)
{
	Class<HyperloopModule> cls = NSClassFromString(name);
	if (cls==nil) 
	{
		return nil;
	}

    JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
    JSContext *context = [[JSContext alloc] initWithVirtualMachine:vm];

    // get the global context
    JSGlobalContextRef globalContextRef = [context JSGlobalContextRef];
    JSObjectRef globalObjectref = JSContextGetGlobalObject(globalContextRef);

    // inject a simple console logger
    JSObjectRef consoleObject = JSObjectMake(globalContextRef, 0, 0);
    JSStringRef logProperty = JSStringCreateWithUTF8CString("log");
    JSStringRef consoleProperty = JSStringCreateWithUTF8CString("console");
    JSObjectRef logFunction = JSObjectMakeFunctionWithCallback(globalContextRef, logProperty, HyperloopLogger);
    JSObjectSetProperty(globalContextRef, consoleObject, logProperty, logFunction, kJSPropertyAttributeNone, 0);
    JSObjectSetProperty(globalContextRef, globalObjectref, consoleProperty, consoleObject, kJSPropertyAttributeNone, 0);
    JSStringRelease(logProperty);
    JSStringRelease(consoleProperty);

    // load the app into the context
    [cls load:context];

    return context;
}
