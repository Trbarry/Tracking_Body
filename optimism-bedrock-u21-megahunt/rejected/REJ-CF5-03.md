# REJ-CF5-03 — custody migration left no Portal/messenger/bridge ETH residue

U16 emitted one exact `ETHMigrated` per target Portal: OP 236752.243071584240518225 ETH, Ink 6020.610509607786200086 ETH, Soneium 8877.050938229307093797 ETH, Unichain 133613.248268096507106891 ETH (raw integer values in `mirror/CF5/evidence/events-current.json`). At block 26,433,900 every Portal, L1XDM, and L1StandardBridge balance is zero; only the chain lockboxes hold canonical liquidity (`pinned-cast-reads.txt:33-37,61-65,89-93,117-121`). Rejected as no stranded-custody differential.
