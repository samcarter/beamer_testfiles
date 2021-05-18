A collection of test documents for beamer

- The examples are mainly taken from various Q&A sites.

- Some of them will exhibit some rather bad practises, that's deliberate. This collection is meant to test the code users actually use, not necessarily the code they should use

- for adding a new examples:

  - copy the `.tex` in the `testfiles` directory
  - run `l3build save filename` to save the current output as references
  - OR run the `save_all.sh` script to save all tests in the folder
  - run `l3build check filename` or `l3build check` to compare the reference output with  new output 
