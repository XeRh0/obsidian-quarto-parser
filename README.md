# obsidian-quarto-parser

This is a personal script for parsing specific parts of the obsidian markdown syntax into quarto.

# TODO

High priority:
- [x] replace manual input parsing with optarg package
- [ ] Add more verbatim tests

- [ ] Add a flag for verbatim parsing (currently it does so by default, but it should not)
    - [ ] Look up and credit plugin creators if needed?
- [x] Clean up available i/o options - currently too many redundant options
    - [ ] Update --help flag to reflect this change
- [ ] Proper comments
- [ ] YAML header parsing support
- [ ] Add inplace parsing support
