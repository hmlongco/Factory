swift package \
    --package-path ../Factory \
    --allow-writing-to-directory ./docs \
    generate-documentation --target FactoryKit \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path Factory \
    --output-path ./docs
