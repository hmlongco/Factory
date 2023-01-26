swift package \
    --allow-writing-to-directory ./docs \
    generate-documentation \
    --target Factory \
    --output-path ./docs \
    --transform-for-static-hosting \
    --hosting-base-path Factory
