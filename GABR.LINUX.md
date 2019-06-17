# gabr.linux.sh

This file contains the leanest `gabr` implementation

* [gabr()](#gabr)


## gabr()

The gabr function will be available after sourcing this file.
This file supports bash 4.3+, this is to add benefit for Linux machines.
This file is optional. Both `gabr.sh` and `gabr.linux.sh` work as stand-alones.
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

