# Testing eullm

## Requirements

### The Admin server

0. Needs `jq` installed
0. Certificate based access to ssh / scp to all the test servers

### The test server

0. `neofetch` or `fastfetch`
0. Needs `timeout`. Part of coreutils but need installing on Mac
0. Passwordless sudo access

## Workflow

When a new release becomes available you need to:

0. Run `./download` to get all the assets into th `assets` directory
0. Run `./checksums` to check that the download worked correctly
0. For each test server run `./deploy XXX` where `XXX` is the test host
