# gabr.sh

This file contains the most stable `gabr` implementation

* [gabr()](#gabr)


## gabr()

 The gabr function will be available after sourcing this file.
This file supports bash 3.2+, this is to support apple machines.
This file sources a modern version of the function if applicable.
This file acts as a function when called as a file.

### Example

```bash
$ gabr [file] function [arguments] -- A function to call other functions  
```

### Arguments

* **$1** (string): A file, directory or function
* **...** (any): Will be shifted through until a valid function is found

### Exit codes

* **0**:  If successfull
* **>0**: On failure

