# europal_direct
Scripts to generate a parallel, directional version of the Europarl corpus (see https://www.aclweb.org/anthology/L12-1050/)

## europarl preprocessing for building directional corpora
-------------------------------------------------------

You need the two scripts

- europarl_language_tag_index.pl
- europarl_direct_ctags.pl

Have your original europarl corpus files in a directory structure like the follwing:

```
europarl/en_de/en
europarl/en_de/de
europarl/en_fr/en
europarl/en_fr/fr
europarl/en_it/en
europarl/en_it/it
```

etc.

On this level run the index script like the following without any arguments:

```
.../europarl$ perl europarl_language_tag_index.pl
```

This builds a large index text file named "europarl_language_index.txt" (the file "index_all.txt" is a subproduct and can be deleted).

Copy this file "europarl_language_index.txt" and the other script "europarl_direct_ctags.pl" into the directory of the required language direction, e.g. into .../en_fr.
In the subdirectories in there make two empty directories like the following:

```
.../en_fr/en/processed
.../en_fr/fr/processed
```

Then run the script like:

```
.../en_fr$ perl europarl_direct_ctags.pl ./fr ./en ./fr/processed ./en/processed EN yes correct
```

...to build the tag-corrected, directional corpus English to French with the tag information kept in the files.

Please see the script comment for other command line arguments.

If using this work, please cite https://www.aclweb.org/anthology/L12-1050/

COMTIS, Bruno Cartoni and Thomas Meyer, 04.11.2010, Bruno.Cartoni@unige.ch, Thomas.Meyer@idiap.ch
