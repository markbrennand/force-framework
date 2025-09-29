# summary

Removes all Apex test results from an org.

# description

All Apex test results will be purged in the chosen org.

# examples

- Purge all Apex unit test results:

  <%= config.bin %> <%= command.id %>

# flags.verbose.summary

Setting this flag will produce output recording command's progress.

# flags.limit.summary

Sets the number of Apex test results to be purged. If unset, all results will be purged.
