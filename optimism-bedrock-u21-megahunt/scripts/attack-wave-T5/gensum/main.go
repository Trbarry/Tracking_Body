package main

import (
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"strings"

	"github.com/klauspost/compress/zstd"
)

// Sums the ETH balances of a superchain-registry genesis alloc (read-only, local files).
func main() {
	dict, _ := os.ReadFile(os.Args[1])
	for _, f := range os.Args[2:] {
		fh, _ := os.Open(f)
		d, err := zstd.NewReader(fh, zstd.WithDecoderDicts(dict))
		if err != nil { panic(err) }
		var g struct {
			Alloc map[string]struct{ Balance string `json:"balance"` } `json:"alloc"`
		}
		if err := json.NewDecoder(d).Decode(&g); err != nil { fmt.Println(f, "decode", err); continue }
		tot := new(big.Int); n := 0
		for a, acc := range g.Alloc {
			b := new(big.Int)
			s := acc.Balance
			if strings.HasPrefix(s, "0x") { b.SetString(s[2:], 16) } else if s != "" { b.SetString(s, 10) }
			if b.Sign() > 0 { n++; fmt.Println("  ", a, b.String()) }
			tot.Add(tot, b)
		}
		fmt.Println(f, "accounts", len(g.Alloc), "funded", n, "total_wei", tot.String())
	}
}
