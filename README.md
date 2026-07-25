# Testing eullm

## Requirements

### The Admin server

1. Needs `jq` installed
2. Certificate based access to ssh / scp to all the test servers

### The test server

1. `neofetch` or `fastfetch`
2. Needs `timeout`. Part of coreutils but need installing on Mac
3. Passwordless sudo access

## Workflow

To see what is available run `./latest_tags`

When a new release becomes available you need to:

1. Run `./download` to get all the assets into the `assets` directory
2. Run `./checksums` to check that the download worked correctly
3. For each test server run `./deploy XXX` where `XXX` is the test host
