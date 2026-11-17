package derive

// ATK-T4: exports for the verbatim copy of op-node v9 op-node/rollup/derive (span batch tx codec).

import (
	"bytes"
	"math/big"
)

// T4SpanEncode encodes raw txs with op-node's span-batch transaction codec.
func T4SpanEncode(txs [][]byte, chainID *big.Int) ([]byte, error) {
	sb, err := newSpanBatchTxs(txs, chainID)
	if err != nil {
		return nil, err
	}
	var w bytes.Buffer
	if err := sb.encode(&w); err != nil {
		return nil, err
	}
	return w.Bytes(), nil
}

// T4SpanDecode decodes a span-batch transaction section of n txs and rebuilds the full txs.
func T4SpanDecode(enc []byte, n uint64, chainID *big.Int) ([][]byte, error) {
	sb := &spanBatchTxs{totalBlockTxCount: n}
	if err := sb.decode(bytes.NewReader(enc)); err != nil {
		return nil, err
	}
	if err := sb.recoverV(chainID); err != nil {
		return nil, err
	}
	return sb.fullTxs(chainID)
}
