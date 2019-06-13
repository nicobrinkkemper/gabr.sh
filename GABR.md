# gabr.sh

This file contains the gabr function and acts as the function when called as file (`bash ./gabr.sh`)

* [gabr()](#gabr)


## gabr()

 The gabr function turns arguments in to a function call.
When a function is named after a file, only one argument is needed. This
is also true for a directory. Gabr chooses the path of least resistance
towards a function call.

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

