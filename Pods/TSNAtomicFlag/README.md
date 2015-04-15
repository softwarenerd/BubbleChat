TSNAtomicFlag
=============

TSNAtomicFlag is a thread-safe boolean for use in multi-threaded applications.

    TSNAtomicFlag * atomicFlag = [[TSNAtomicFlag alloc] init];
    if ([atomicFlag trySet])
    {
        NSLog(@"The flag was set!");
    }
    if ([atomicFlag isSet])
    {
        NSLog(@"The flag is set!");
    }
    if ([atomicFlag tryClear])
    {
        NSLog(@"The flag was cleared!");
    }
    if ([atomicFlag isClear])
    {
        NSLog(@"The flag is clear!");
    }
    
TSNAtomicFlag is released under an MIT license, meaning you're free to use it in both closed and open source projects. However, even in a closed source project, please include a publicly-accessible copy of TSNAtomicFlag's copyright notice, which you can find in the LICENSE file.

If you have any questions about, suggestions for, or contributions to TSNAtomicFlag, please [contact me](mailto:brianlambert@softwarenerd.org).
