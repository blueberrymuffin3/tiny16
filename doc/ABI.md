> Note: r0 is the zero register

# Callee save:
- r8-12

# Caller save:
- lr, r1-r7

# Parameters and return value(s):
- r1-r7
- caller stack frame, from sp+0 up
- vargs are stored on the stack

# Stack Pointer:
- Stack grows downwards
- Stack pointer points to the last word of the current frame
