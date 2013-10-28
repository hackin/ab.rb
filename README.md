# abter - a simple, open source autobuyer written in Ruby

## Installation

```
$ gem install curb
```

## Authentication headers

Log in to the web app, inspect the requests and make a player search.
Grab the X-UT-PHISHING-TOKEN and X-UT-SID and add them into the top of the script like the example below.

```
session_headers = {
  'X-UT-PHISHING-TOKEN' => '46887542156800540597',
  'X-UT-SID' => '11fc3bbe-a98c-470d-a1df-a591f272800f'
}
```

Keep your browser open to keep the session alive.

## Adding players

`players.json` is the file which contains the players to search for.

### Valid JSON parameters

`leag`: League
`defid`: Definition ID
`mdefid`: Masked Definition ID
`nat`: Nation
`team`: Team
`zone`: Player zone (attacker, midfield, defender)
`pos`: Player position
`minb`: Minimum BIN price
`maxb`: Maximum BIN price, can either be a single integer or an array of integers.

### Example players.json

#### With various search parameters

  [
    {
      "desc": "Aguero",
      "maxb": 200000,
      "leag": "13",
      "team": "10",
      "nat": "52",
      "zone": "attacker"
    },
    {
      "desc": "Alaba",
      "maxb": [ 30000, 29000, 30500 ],
      "leag": "19",
      "nat": "4",
      "team": "21",
      "zone": "defense"
    }
  ]

#### With definition ID

Whitespace does not matter, so it is possible to compress the JSON.

    [{"desc":"David Silva","assetid":"168542","maxb":[100000,105000,102000]},
     {"desc":"Gotze","assetid":"192318","maxb":[50000,51000,52000]}]

## Running the script

```
$ ./abt
```
