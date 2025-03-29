# Changelog

<!--
Prefix your message with one of the following:

- [Added] for new features.
- [Changed] for changes in existing functionality.
- [Deprecated] for soon-to-be removed features.
- [Removed] for now removed features.
- [Fixed] for any bug fixes.
- [Security] in case of vulnerabilities.
-->

# Unreleased

- [Added] Add support for prefixed env vars with (e.g. `MYAPP_`).
- [Added] Add `SuperConfig#get` method to retrieve values.
- [Changed] Define boolean properties defined with `SuperConfig#set` as
  predicates.

# v2.2.1

- [Changed] Silence warnings when reassigning a method with `set`.

# v2.2.0

- [Added] `SuperConfig#set(key, value)` method to set arbitrary values.

## v2.1.1

- [Changed] Ensure bad JSON strings doesn't leak it's contents.

## v2.0.0

- Initial release.
