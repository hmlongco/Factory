swift package \
    --allow-writing-to-directory ./Documentation \
    generate-documentation \
    --target Factory \
    --output-path ./Documentation \
    --transform-for-static-hosting \
    --hosting-base-path Factory
