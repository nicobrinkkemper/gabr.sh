# gabr.linux.sh

This file contains the original gabr function before it got butchered in order to support older Bash versions.

* [gabr()](#gabr)


## gabr()

The main benefit is cleaner code. But the draw-back is Bash 4.3+ only. 4.3+ supports
associative arrays (-A) and -v flags. The -A flag is used to check if files are not being resourced, which
is a minor extra feature. This file is automatically loaded if found and BASH_VERSION is 4.3+.

### Example

```bash
$ debug=(files)
$ gabr example human smile
```

### Arguments

* **$1** (string): A file, directory or function
* **...** (any): Will be shifted through until a valid function is found

### Exit codes

* **0**:  If successfull
* **>0**: On failure

