# FXP – Fixed-Point Data Type for GNU Octave
GNU Octave Fixed-Point Class/Data-Type
## Overview

**FXP** is a custom fixed-point numeric data type implemented in **GNU Octave**, inspired by MATLAB’s `fi` object.  
The library provides configurable fixed-point arithmetic with support for:

- Signed and unsigned numbers  
- Arbitrary word length and fractional length  
- Rounding and overflow handling  
- Scalar and vectorized fixed-point conversion  
- Operator overloading for arithmetic expressions  
- Regression testing framework  

This project is intended for **numerical modeling**, **DSP**, and **hardware-oriented algorithm development** where fixed-point precision must be explicitly controlled.

---


## Repository Structure

```
├── README.md
├── vfxp.m
├── test_regression.m
└── @fxp
    └── fxp.m
```

---

## Installation (Bash)
This is simple Bash script tht helps in downloading and setting up the fxp class.

```bash
#!/bin/bash

PKG_PATH="/home/$USER/octave/fxp"
GIT_PATH="https://github.com/ahmedshahein/fxp.git"

git clone $GIT_PATH $PKG_PATH/@fxp

cat <<EOF >> /home/$USER/.octaverc
addpath('$PKG_PATH');
rehash;
EOF
```
---
## File Descriptions

### fxp.m
Core class definition implementing the fixed-point data type.

Key responsibilities:
- Fixed-point quantization
- Internal binary and integer representation
- Overflow and rounding handling
- Operator overloading (`+`, `-`, `*`, `/`, comparisons, etc.)
- Metadata such as word length, fraction length, and error tracking

Constructor signature:
```octave
obj = fxp(data, signed, word_length, frac_length)
```

---

### vfxp.m
Vectorized fixed-point helper function.

Purpose:
- Converts arrays or vectors of numeric values into arrays of `fxp` objects
- Applies scalar `fxp` construction element-by-element
- Avoids object preallocation issues in GNU Octave

Example:
```octave
a = vfxp([3.14, 0.25, 22/7], 1, 16, 8);
```

---

### test_regression.m
Regression test suite for functional verification.

Features:
- Multiple fixed-point test cases
- Arithmetic correctness checks
- Overflow and quantization validation
- Structured test execution

Run with:
```octave
test_regression
```

---

## Requirements

- GNU Octave ≥ 7.x
- No external toolboxes required
- Designed for Octave compatibility (avoids unsupported MATLAB features)

---

## Features
### PROPERTIES:
  vfxp        - Quantized fixed-point value
  S           - Signedness (1=signed, 0=unsigned)
  WL          - Word-length (total bits)
  IL          - Integer-length (derived: WL - FL - S)
  FL          - Fractional-length (bits for fraction)
  max         - Maximum representable value
  min         - Minimum representable value
  res         - Resolution (2^-FL)
  DR_dB       - Dynamic range in dB
  dec         - Scaled integer representation
  bin         - Binary array (2's complement)
  bin_str     - Formatted binary string with decimal point
  err         - Quantization error
  ovf         - Overflow flag (1=overflow, 0=no overflow)

### METHODS:
  disp()      - Display complete fixed-point information
  disp_bits() - Display detailed bit-level information
  struct()    - Convert to struct with all fields
  double()    - Convert to double precision
  int32()     - Convert to int32
  uint32()    - Convert to uint32
  struct()    - Convert to struct

### ARITHMETIC OPERATIONS:
  +, -, *, /, mod
  (with automatic result word-length adjustment)

### COMPARISON OPERATIONS:
  ==, ~=, <, <=, >, >=
  ---
  
## Basic Usage

### Scalar Conversion
```octave
x = fxp(3.14159, 1, 16, 8);
```

### Vector Conversion
```octave
x = vfxp([1.5, 2.75, -0.125], 1, 12, 6);
```

### Arithmetic
```octave
a = fxp(1.25, 1, 8, 4);
b = fxp(0.5,  1, 8, 4);

c = a + b;
d = a * b;
```

---

## Design Notes

- Object arrays are created via element-wise construction to comply with GNU Octave’s object model
- Default properties are explicitly initialized
- Single quotes are used instead of `string()` for compatibility
- Focus is on numerical correctness and determinism

---

## Roadmap

Planned enhancements:
- Additional overflow modes (wrap, saturate)
- More rounding methods
- Bit-true formatting utilities
- Expanded operator coverage
- MATLAB compatibility layer

---

## Author

Ahmed Shahein 
