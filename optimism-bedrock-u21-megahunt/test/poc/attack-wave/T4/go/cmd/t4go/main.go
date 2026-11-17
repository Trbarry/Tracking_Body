// ATK-T4 op-node (v9 checkout) side of the crate-level differential. Same JSONL corpus as the
// Rust harness; pure computation with op-node's own derivation functions. No network.
package main

import (
	"bufio"
	"context"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"strconv"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/params"
	"github.com/ethereum/go-ethereum/trie"

	optypes "github.com/ethereum-optimism/optimism/op-core/types"
	"github.com/ethereum-optimism/optimism/op-node/rollup"
	"github.com/ethereum-optimism/optimism/op-node/rollup/derive"
	"github.com/ethereum-optimism/optimism/op-node/superchain"
	"github.com/ethereum-optimism/optimism/op-service/eth"

	derivecopy "t4go/derivecopy"
)

type M = map[string]any

func u64(v any) uint64 {
	switch x := v.(type) {
	case float64:
		return uint64(x)
	case json.Number:
		n, err := strconv.ParseUint(string(x), 10, 64)
		if err != nil {
			panic(err)
		}
		return n
	case string:
		if strings.HasPrefix(x, "0x") {
			n, err := strconv.ParseUint(x[2:], 16, 64)
			if err != nil {
				panic(err)
			}
			return n
		}
		n, err := strconv.ParseUint(x, 10, 64)
		if err != nil {
			panic(err)
		}
		return n
	}
	panic(fmt.Sprintf("u64 %T %v", v, v))
}

func h(v any) common.Hash     { return common.HexToHash(v.(string)) }
func a(v any) common.Address  { return common.HexToAddress(v.(string)) }
func bs(v any) []byte         { return common.FromHex(v.(string)) }
func u256(v any) *big.Int {
	n, ok := new(big.Int).SetString(v.(string), 0)
	if !ok {
		panic("u256")
	}
	return n
}

func logOf(m M) *types.Log {
	var topics []common.Hash
	for _, t := range m["topics"].([]any) {
		topics = append(topics, h(t))
	}
	return &types.Log{Address: a(m["address"]), Topics: topics, Data: bs(m["data"])}
}

type l1fetch struct {
	info     eth.BlockInfo
	receipts optypes.Receipts
}

func (f *l1fetch) InfoByHash(ctx context.Context, hash common.Hash) (eth.BlockInfo, error) {
	if hash != f.info.Hash() {
		return nil, fmt.Errorf("unknown hash")
	}
	return f.info, nil
}
func (f *l1fetch) FetchReceipts(ctx context.Context, hash common.Hash) (eth.BlockInfo, optypes.Receipts, error) {
	if hash != f.info.Hash() {
		return nil, nil, fmt.Errorf("unknown hash")
	}
	return f.info, f.receipts, nil
}

type l2fetch struct{ cfg eth.SystemConfig }

func (f *l2fetch) SystemConfigByL2Hash(ctx context.Context, hash common.Hash) (eth.SystemConfig, error) {
	return f.cfg, nil
}

func sysCfg(m M) eth.SystemConfig {
	var c eth.SystemConfig
	c.BatcherAddr = a(m["batcher"])
	c.Overhead = eth.Bytes32(common.BigToHash(u256(m["overhead"])))
	c.Scalar = eth.Bytes32(common.BigToHash(u256(m["scalar"])))
	c.GasLimit = u64(m["gas_limit"])
	if m["eip1559_denominator"] != nil {
		binary.BigEndian.PutUint32(c.EIP1559Params[0:4], uint32(u64(m["eip1559_denominator"])))
		binary.BigEndian.PutUint32(c.EIP1559Params[4:8], uint32(u64(m["eip1559_elasticity"])))
	}
	var of eth.OperatorFeeParams
	if m["operator_fee_scalar"] != nil {
		of.Scalar = uint32(u64(m["operator_fee_scalar"]))
	}
	if m["operator_fee_constant"] != nil {
		of.Constant = u64(m["operator_fee_constant"])
	}
	c.OperatorFeeParams = eth.EncodeOperatorFeeParams(of)
	if m["min_base_fee"] != nil {
		c.MinBaseFee = u64(m["min_base_fee"])
	}
	if m["da_footprint_gas_scalar"] != nil {
		c.DAFootprintGasScalar = uint16(u64(m["da_footprint_gas_scalar"]))
	}
	return c
}

func rollupCfg(chain uint64, override M) *rollup.Config {
	cfg, err := superchain.LoadOPStackRollupConfig(chain)
	if err != nil {
		panic(err)
	}
	for k, v := range override {
		var t *uint64
		if v != nil {
			x := u64(v)
			t = &x
		}
		switch k {
		case "ecotone":
			cfg.EcotoneTime = t
		case "fjord":
			cfg.FjordTime = t
		case "granite":
			cfg.GraniteTime = t
		case "holocene":
			cfg.HoloceneTime = t
		case "isthmus":
			cfg.IsthmusTime = t
		case "jovian":
			cfg.JovianTime = t
		case "karst":
			cfg.KarstTime = t
		default:
			panic(k)
		}
	}
	return cfg
}

func ptrStr(p *uint64) string {
	if p == nil {
		return "None"
	}
	return strconv.FormatUint(*p, 10)
}

func run(c M) (out M) {
	id := c["id"]
	defer func() {
		if r := recover(); r != nil {
			out = M{"id": id, "panic": fmt.Sprint(r)}
		}
	}()
	switch c["k"].(string) {
	case "dep":
		l := logOf(c)
		l.BlockHash = h(c["bh"])
		l.Index = uint(u64(c["idx"]))
		dep, err := derive.UnmarshalDepositLogEvent(l)
		if err != nil {
			return M{"id": id, "err": err.Error()}
		}
		b, err := dep.MarshalBinary()
		if err != nil {
			return M{"id": id, "err": "marshal: " + err.Error()}
		}
		return M{"id": id, "ok": hexutil.Encode(b), "hash": crypto.Keccak256Hash(b).Hex()}
	case "attr":
		chain := u64(c["chain"])
		var ov M
		if o, ok := c["override_hardforks"]; ok {
			ov = o.(M)
		}
		rcfg := rollupCfg(chain, ov)
		hj, _ := json.Marshal(c["l1_header"])
		var hdr types.Header
		if err := json.Unmarshal(hj, &hdr); err != nil {
			panic(err)
		}
		info := eth.HeaderBlockInfo(&hdr)
		var rs types.Receipts
		idx := uint(0)
		if rr, ok := c["receipts"].([]any); ok {
			for _, ri := range rr {
				r := ri.(M)
				rec := &types.Receipt{Status: u64(r["status"]), CumulativeGasUsed: u64(r["cgu"]), BlockHash: info.Hash()}
				for _, li := range r["logs"].([]any) {
					lg := logOf(li.(M))
					lg.BlockHash = info.Hash()
					lg.Index = idx
					idx++
					rec.Logs = append(rec.Logs, lg)
				}
				rs = append(rs, rec)
			}
		}
		p := c["parent"].(M)
		parent := eth.L2BlockRef{
			Hash: h(p["hash"]), Number: u64(p["number"]), Time: u64(p["timestamp"]),
			L1Origin:       eth.BlockID{Hash: h(p["l1_hash"]), Number: u64(p["l1_number"])},
			SequenceNumber: u64(p["seq"]),
		}
		epoch := eth.BlockID{Hash: info.Hash(), Number: info.NumberU64()}
		l1cfg := eth.L1ChainConfigByChainID(eth.ChainIDFromBig(rcfg.L1ChainID))
		b := derive.NewFetchingAttributesBuilder(rcfg, l1cfg, nil,
			&l1fetch{info: info, receipts: optypes.FromGethReceipts(rs)}, &l2fetch{cfg: sysCfg(c["sys"].(M))})
		attrs, err := b.PreparePayloadAttributes(context.Background(), parent, epoch)
		if err != nil {
			return M{"id": id, "l1_hash": info.Hash().Hex(), "err": err.Error()}
		}
		txs := []string{}
		hashes := []string{}
		for _, t := range attrs.Transactions {
			txs = append(txs, hexutil.Encode(t))
			hashes = append(hashes, crypto.Keccak256Hash(t).Hex())
		}
		var beacon any
		if attrs.ParentBeaconBlockRoot != nil {
			beacon = attrs.ParentBeaconBlockRoot.Hex()
		}
		var wd any
		if attrs.Withdrawals != nil {
			wd = len(*attrs.Withdrawals)
		}
		var e1559 any
		if attrs.EIP1559Params != nil {
			e1559 = hexutil.Encode(attrs.EIP1559Params[:])
		}
		var mbf any
		if attrs.MinBaseFee != nil {
			mbf = *attrs.MinBaseFee
		}
		return M{
			"id": id, "l1_hash": info.Hash().Hex(), "timestamp": uint64(attrs.Timestamp),
			"prev_randao": common.Hash(attrs.PrevRandao).Hex(), "fee_recipient": attrs.SuggestedFeeRecipient.Hex(),
			"beacon_root": beacon, "withdrawals": wd, "txs": txs, "tx_hashes": hashes, "no_tx_pool": attrs.NoTxPool,
			"gas_limit": uint64(*attrs.GasLimit), "eip1559": e1559, "min_base_fee": mbf,
		}
	case "rroot":
		var rs types.Receipts
		for _, ri := range c["receipts"].([]any) {
			r := ri.(M)
			rec := &types.Receipt{Type: uint8(u64(r["type"])), Status: u64(r["status"]), CumulativeGasUsed: u64(r["cgu"])}
			for _, li := range r["logs"].([]any) {
				rec.Logs = append(rec.Logs, logOf(li.(M)))
			}
			rec.Bloom = types.CreateBloom(rec)
			if r["deposit_nonce"] != nil {
				x := u64(r["deposit_nonce"])
				rec.DepositNonce = &x
			}
			if r["deposit_receipt_version"] != nil {
				x := u64(r["deposit_receipt_version"])
				rec.DepositReceiptVersion = &x
			}
			rs = append(rs, rec)
		}
		root := types.DeriveSha(rs, trie.NewStackTrie(nil))
		return M{"id": id, "root": root.Hex()}
	case "donly":
		pa := &eth.PayloadAttributes{}
		for _, t := range c["txs"].([]any) {
			pa.Transactions = append(pa.Transactions, eth.Data(bs(t)))
		}
		d := pa.WithDepositsOnly()
		txs := []string{}
		for _, t := range d.Transactions {
			txs = append(txs, hexutil.Encode(t))
		}
		return M{"id": id, "txs": txs}
	case "span2":
		var raws [][]byte
		for _, t := range c["raw"].([]any) {
			raws = append(raws, bs(t))
		}
		cid := new(big.Int).SetUint64(u64(c["chain_id"]))
		genc, err := derivecopy.T4SpanEncode(raws, cid)
		if err != nil {
			return M{"id": id, "err": "go encode: " + err.Error()}
		}
		eq := func(a, b [][]byte) bool {
			if len(a) != len(b) {
				return false
			}
			for i := range a {
				if hexutil.Encode(a[i]) != hexutil.Encode(b[i]) {
					return false
				}
			}
			return true
		}
		rt, err1 := derivecopy.T4SpanDecode(genc, uint64(len(raws)), cid)
		kd, err2 := derivecopy.T4SpanDecode(bs(c["kona_enc"]), uint64(len(raws)), cid)
		return M{"id": id, "go_enc": hexutil.Encode(genc), "go_enc_eq_kona_enc": hexutil.Encode(genc) == c["kona_enc"].(string),
			"go_rt_ok": err1 == nil && eq(rt, raws), "go_dec_kona_ok": err2 == nil && eq(kd, raws)}
	case "sysfrom":
		rcfg := rollupCfg(u64(c["chain"]), nil)
		hj, _ := json.Marshal(c["header"])
		var hdr types.Header
		if err := json.Unmarshal(hj, &hdr); err != nil {
			panic(err)
		}
		d := c["tx0"].(M)
		to := a(d["to"])
		dep := &optypes.DepositTx{SourceHash: h(d["sourceHash"]), From: a(d["from"]), To: &to, Value: u256(d["value"]),
			Gas: u64(d["gas"]), Data: bs(d["input"])}
		if m, ok := d["mint"].(string); ok && m != "0x0" {
			dep.Mint = u256(m)
		}
		if b, ok := d["isSystemTx"].(bool); ok {
			dep.IsSystemTransaction = b
		}
		raw, err := dep.MarshalBinary()
		if err != nil {
			panic(err)
		}
		payload := &eth.ExecutionPayload{BlockNumber: hexutil.Uint64(hdr.Number.Uint64()), BlockHash: hdr.Hash(), Timestamp: hexutil.Uint64(hdr.Time),
			GasLimit: hexutil.Uint64(hdr.GasLimit), ExtraData: hdr.Extra, Transactions: []eth.Data{raw}}
		sc, err := derive.PayloadToSystemConfig(rcfg, payload)
		if err != nil {
			return M{"id": id, "err": err.Error()}
		}
		of := eth.DecodeOperatorFeeParams(sc.OperatorFeeParams)
		return M{"id": id, "hash_ok": hdr.Hash().Hex() == common.HexToHash(c["hash"].(string)).Hex(), "tx_ok": crypto.Keccak256Hash(raw).Hex() == common.HexToHash(d["hash"].(string)).Hex(),
			"batcher": strings.ToLower(sc.BatcherAddr.Hex()), "overhead": hexutil.Encode(sc.Overhead[:]), "scalar": hexutil.Encode(sc.Scalar[:]),
			"gas_limit": sc.GasLimit, "eip1559": hex.EncodeToString(sc.EIP1559Params[:]), "operator_fee": fmt.Sprintf("%d/%d", of.Scalar, of.Constant),
			"min_base_fee": sc.MinBaseFee, "da_footprint": sc.DAFootprintGasScalar}
	case "oroot":
		o := eth.OutputV0{StateRoot: eth.Bytes32(h(c["state"])), MessagePasserStorageRoot: eth.Bytes32(h(c["storage"])), BlockHash: h(c["block"])}
		r := eth.OutputRoot(&o)
		return M{"id": id, "hash": common.Hash(r).Hex(), "enc": hexutil.Encode(o.Marshal())}
	case "sroot":
		var chains []eth.ChainIDAndOutput
		for _, x := range c["outs"].([]any) {
			p := x.([]any)
			chains = append(chains, eth.ChainIDAndOutput{ChainID: eth.ChainIDFromUInt64(u64(p[0])), Output: eth.Bytes32(h(p[1]))})
		}
		s := eth.NewSuperV1(u64(c["ts"]), chains...)
		r := eth.SuperRoot(s)
		return M{"id": id, "hash": common.Hash(r).Hex(), "enc": hexutil.Encode(s.Marshal())}
	case "cfg":
		chain := u64(c["chain"])
		r := rollupCfg(chain, nil)
		l1 := eth.L1ChainConfigByChainID(eth.ChainIDFromBig(r.L1ChainID))
		bs := l1.BlobScheduleConfig
		sched := []string{}
		add := func(n string, c *params.BlobConfig) {
			if c != nil {
				sched = append(sched, fmt.Sprintf("%s:%d/%d/%d", n, c.Target, c.Max, c.UpdateFraction))
			}
		}
		add("cancun", bs.Cancun)
		add("prague", bs.Prague)
		add("osaka", bs.Osaka)
		add("bpo1", bs.BPO1)
		add("bpo2", bs.BPO2)
		add("bpo3", bs.BPO3)
		add("bpo4", bs.BPO4)
		add("bpo5", bs.BPO5)
		return M{
			"id": id,
			"hardforks": fmt.Sprintf("regolith=%s canyon=%s delta=%s ecotone=%s fjord=%s granite=%s holocene=%s pectra_blob=%s isthmus=%s jovian=%s karst=%s lagoon=%s",
				ptrStr(r.RegolithTime), ptrStr(r.CanyonTime), ptrStr(r.DeltaTime), ptrStr(r.EcotoneTime), ptrStr(r.FjordTime), ptrStr(r.GraniteTime), ptrStr(r.HoloceneTime), ptrStr(r.PectraBlobScheduleTime), ptrStr(r.IsthmusTime), ptrStr(r.JovianTime), ptrStr(r.KarstTime), ptrStr(r.LagoonTime)),
			"block_time":       r.BlockTime,
			"deposit_contract": r.DepositContractAddress.Hex(),
			"system_config":    r.L1SystemConfigAddress.Hex(),
			"l1": fmt.Sprintf("prague=%s osaka=%s bpo1=%s bpo2=%s bpo3=%s bpo4=%s bpo5=%s amsterdam=%s",
				ptrStr(l1.PragueTime), ptrStr(l1.OsakaTime), ptrStr(l1.BPO1Time), ptrStr(l1.BPO2Time), ptrStr(l1.BPO3Time), ptrStr(l1.BPO4Time), ptrStr(l1.BPO5Time), ptrStr(l1.AmsterdamTime)),
			"blob_schedule": sched,
		}
	}
	return M{"id": id, "err": "unknown kind"}
}

func main() {
	sc := bufio.NewScanner(os.Stdin)
	sc.Buffer(make([]byte, 64<<20), 64<<20)
	w := bufio.NewWriter(os.Stdout)
	defer w.Flush()
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}
		var c M
		dec := json.NewDecoder(strings.NewReader(line))
		dec.UseNumber() // keep 64-bit integers exact
		if err := dec.Decode(&c); err != nil {
			panic(err)
		}
		r := run(c)
		b, _ := json.Marshal(r)
		w.Write(b)
		w.WriteString("\n")
	}
}
