swift package \
    --allow-writing-to-directory ./docs \
    generate-documentation --target Factory \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path Factory \
    --output-path ./docs
