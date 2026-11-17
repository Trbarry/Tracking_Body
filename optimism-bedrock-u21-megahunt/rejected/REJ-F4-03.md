REJ-ID: REJ-F4-03
Title: "Legacy bytes sharing the `_initialized` slot (L1CDM OVM `libAddressManager`, L1StandardBridge OVM `messenger`) are read as initializer state"

Idea
- L1StandardBridge slot 0 held the OVM `messenger` 0x25ace71c… (low byte 0xa1 => `_initialized` 161, `_initializing`
  true under the v1.1.0+ layout). L1CDM slot 0 bytes 0-19 held AddressManager 0xdE1FCfB0…, `_initialized` at offset 20.

Killing fact
- Both slots were rewritten INSIDE the upgrade tx at 19314493 (StorageSetter zero, then `initialize`): cast storage
  slot 0 @19314492 / @19314493: bridge `…25ace71c…5fa1` -> `0x…01`; L1CDM `…01de1fcfb0…d81f` -> `…01 << 160`. The bridge
  implementation running before (1.1.0 0xbfb731cd…) had no initializer at all. Since then the OPCM clears exactly one byte
  at the right offset (0/0; L1CDM 0/20; op-v9.0.0 OPContractsManagerUtils.upgrade). Poisoning the 18 / 30 bytes above
  the initializer bytes with junk leaves 60 getters and a real withdrawal + deposit unchanged
  (`test_poisonedPreV7Slots_realWithdrawalAndDepositAreUnchanged`, PASS). Ink / Soneium / Unichain never held these values.
