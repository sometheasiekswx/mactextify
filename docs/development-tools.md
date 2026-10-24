# Personal development tools

The downloaded skills in `/.agents/` are personal development tools. They are
not application dependencies or shared contributor requirements and should not
be committed or included in releases.

Each developer who installs these tools should add this checkout-local rule to
Git's `info/exclude` file (locate it with `git rev-parse --git-path info/exclude`):

```gitignore
/.agents/
```

This exclusion is local to the checkout and is not distributed by cloning.
The project `.gitignore` deliberately does not impose a blanket `.agents/`
policy on other contributors. Any future shared agent instructions or skills
should be reviewed and explicitly adopted before being version-controlled.

Keep installation provenance, pinned revisions and security-review metadata
alongside the personal skills. Review third-party skills before installing or
updating them. Ignoring files does not remove already tracked files or provide
secret protection.
