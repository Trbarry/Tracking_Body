# [DRAFT, NOT SUBMITTED] Airbender V2: padding rows of the unified circuit can emit delegation requests

> Internal draft. The severity, the impact chain and the PoC tier are still open. See the "Open items" section at the end.
> Every claim below has to be backed by `poc.md` and `impact-notes.md` before submission.

## Summary

In Airbender V2 (`matter-labs/zksync-airbender` @ `0decdcd`, "feat!: Airbender V2 (#587)"), the
`unified_reduced_machine` circuit never ties its delegation-request multiplicity to the row's `execute`
predicate. On padding rows (`execute = 0`) the decoder lookup is not enforced and the state permutation
is masked, so the opcode bitmask, the `rs1` value and the cycle timestamp are all prover-chosen.

A malicious prover can therefore use a padding row to emit a Blake2s delegation request at a timestamp
of its choice, and serve it with an extra row of the Blake2s delegation circuit. That row reads and
overwrites RAM (the state buffer at `x10`, plus `x12`) in the middle of an otherwise honest execution. The
proven execution then no longer follows RISC-V semantics, yet every constraint and every argument still
balances.

The sibling circuit `shift_binary_csr`, which has the same delegation feature, contains the guard
explicitly, with a comment describing exactly this attack. The unified circuit lacks it.

## Affected code

- `cs/src/machine/ops/common_impls/csr_with_delegation.rs:54-72`

  ```rust
  let should_delegate = cs.add_variable_from_constraint(
      Term::from(is_for_delegation) * Term::from(exec_flag),
  );
  ...
  let delegation_request = DelegatedComputationRequest {
      execute: should_delegate,
      delegation_type: csr_index_masked,
      memory_offset_high: offset_masked,
  };
  cs.add_delegation_request(delegation_request);
  ```

  `exec_flag` is the CSR major flag that comes from the family bitmask. Nothing relates it to `inputs.execute`.

- It is reached from `cs/src/machine/ops/unrolled/reduced_machine_ops.rs` (the `PERFORM_DELEGATION == true` branch).

- For comparison, `cs/src/machine/ops/unrolled/shift_binary_csr.rs:679-685` has the guard:

  ```rust
  // And to avoid prover's possibility to set delegation to 1 when we actually do not execute on this row, check
  // that we indeed execute
  cs.add_constraint(
      Term::from(execute_delegation) * (Term::from(1u64) - Term::from(inputs.execute)),
  );
  ```

### Evidence in the committed generated verifier code

From `circuit_defs/unrolled_circuits/*/generated/`:

| | `shift_binary_csr` | `unified_reduced_machine` |
|---|---|---|
| execute column | `memory[19]` | `memory[30]` |
| delegation multiplicity column | `memory[17]` | `memory[27]` |
| constraint `m·(1−execute) = 0` | present (`m17 − m17·m19`, quotient.rs ~l.380) | **absent** |

In the `unified_reduced_machine` quotient, `memory[30]` appears in only three places:
- its booleanity (l.471);
- the decoder-lookup multiplicity (l.4028);
- the state-permutation predicate (l.4725).

`memory[27]` is defined by `w26·w79 − m27` (l.1486), where `w26` is the CSR flag and `w79` is
`is_for_delegation`. It is used unmasked as `m` in the delegation-request accumulator term (l.4390). The
timestamp in that term is read from `memory[33]`/`memory[34]`, the row's own state columns, because
`timestamp_setup_columns` is empty for this circuit. On a padding row those columns are free.

## Attack

1. Run the honest program and generate an honest witness for all circuits.
2. In the `unified_reduced_machine` trace, choose a padding row (`execute = 0`). Copy into it the witness
   columns of an honest `CSRRW` delegation row targeting `BLAKE2S_DELEGATION_CSR_REGISTER`, which is the
   only delegation allowed in the unified machine (`execution_utils/src/unified_circuit.rs:91`). Keep
   `execute = 0`.
3. Set the row's start timestamp to `B`, where `B` is the start timestamp of some honest, non-delegating
   cycle. The delegation slot `B+3` (`in_cycle_write_index = 3`) of that cycle is unused.
4. Every constraint of the row still holds:
   - the constraints that would bind the bitmask to the bytecode are lookups with multiplicity `execute = 0`;
   - the memory and state permutation terms are masked by `execute`.

   The row contributes a delegation request `(type = Blake2s, abi_offset, ts = B+3)` with multiplicity 1.
5. Add one row to the Blake2s delegation circuit that processes this request. It reads `x10`, `x11` and
   `x12` and the state/input buffers at their latest write timestamps (all `< B+3`), and writes the
   compressed state (and the updated `x12`) at `B+3`.
6. Re-point the next reads of the affected addresses to `(v', B+3)`. The RAM argument and the delegation
   set-equality both balance.

**Result:** the proof attests to an execution in which a Blake2s compression was applied to the buffer at
`x10` at a cycle where the program executed no such instruction.

## Impact

**[OPEN: to be completed from impact-notes.md]**

- The unified circuit proves the recursion verifier program, the "unified" recursion layer
  (`execution_utils/src/unified_circuit.rs`, `full_statement_verifier/src/unified_circuit_statement.rs`).
  That program relies on Blake2s for its Fiat-Shamir transcript and its Merkle-path checks.
- **What is established:** a soundness break of the unified circuit. Accepted executions are no longer
  faithful RISC-V executions of the committed program.
- **What still has to be shown or bounded:** whether this lets an invalid inner proof, or wrong public
  outputs, pass the recursion layer. A candidate route is re-sampling Fiat-Shamir state at chosen points.

## Fix

Add the same guard as in `shift_binary_csr` to the unified path, for example in `csr_with_delegation.rs`
right after `should_delegate` is allocated, or in `reduced_machine_ops.rs`:

```rust
cs.add_constraint(
    Term::from(should_delegate) * (Term::from(1u64) - Term::from(inputs.execute)),
);
```

Then regenerate the unified circuit artifacts and verifiers.

A more robust fix is for the compiler to multiply the delegation-request multiplicity by the `execute`
predicate for every unrolled circuit, as is already done for the memory and state arguments.

## Proof of concept

See `poc.md`, which also gives the tier reached and the negative control with the fix applied.

## Versions

- Introduced in `0decdcd` (2026-11-04). V1 had no unified/unrolled circuits.
- Still present on `main` as of 2026-11-18.

---
### Open items (internal, remove before submission)
- [ ] Impact chain: from inserting a compression to forging a proof or a public output (impact-notes.md)
- [ ] Whether the m = −1 variant (cancelling a real delegation) holds
- [ ] Production usage of the unified layer, and program scope
- [ ] Duplicate check upstream
- [ ] PoC tier reached (T1/T2/T3); T3 on the OVH machine if required
- [ ] Hostile triager pass
