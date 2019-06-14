# gabr.sh

This file contains one function and acts as that function when called as a file.

* [gabr()](#gabr)


## gabr()

 The gabr function will be available after sourcing this file.
Tt sources a more modern version of the function if BASH_VERSION is 4.3+
Fear not, these files behave almost identical.

### Example

```bash
$ gabr example human smile
This is human
:)
```

### Arguments

* **$1** (string): A file, directory or function
* **...** (any): Will be shifted through until a valid function is found

### Exit codes

* **0**:  If successfull
* **>0**: On failure

