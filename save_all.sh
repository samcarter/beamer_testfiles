for f in ./testfiles/*.tex; do
    fbname=$(basename "$f" .tex)
    l3build save $fbname;
done