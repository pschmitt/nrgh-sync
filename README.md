# nrgh-sync

# Installation

Dependencies:

- [newreleases CLI](https://github.com/newreleasesio/cli-go)
- [jq](https://stedolan.github.io/jq/)

# Usage

```bash
# Dry run
nrgh-sync.sh sync -n --delete --gh-token YOUR_GH_TOKEN --nr-token YOUR_NR_TOKEN
# Run
nrgh-sync.sh sync --delete --gh-token YOUR_GH_TOKEN --nr-token YOUR_NR_TOKEN
```

# Notes

You may hit rate-limiting if you have a lot of starred repositories.

nrgh-sync will automatically wait and retry if it hits the limit.

If you really need to raise the limits you should [get in touch with the newreleases.io team](https://newreleases.io/contact).
