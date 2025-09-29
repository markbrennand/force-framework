# summary

Runs all non-namespaced unit tests in an org.

# description

The tests are first run in parallel. Any tests that fail to run due to a ROW LOCK error are re-run synchronously.
Once the re-run has completed, any tests that failed in both parallel and synchronously are reported.


# examples

- Run all tests:

  <%= config.bin %> <%= command.id %>

# flags.output-file.summary

Output file for results. Filename extension determines data format used. Two formats are supported. For CSV use .csv. For JSON use .json

# flags.verbose.summary

Setting this flag will produce output recording command's progress.
