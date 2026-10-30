// C declarations for the @c functions in Hello4S.swift.
// Swift's Int is 32 bits on armv7, the same as long.

#ifndef HELLO4S_H
#define HELLO4S_H

/// Writes the Swift greeting into buffer as NUL-terminated UTF-8.
/// Returns the number of bytes written, not counting the NUL.
long hello4s_greeting(char *buffer, long size);

/// Returns 1² + 2² + ... + n², computed in Swift.
long hello4s_sum_of_squares(long n);

#endif
