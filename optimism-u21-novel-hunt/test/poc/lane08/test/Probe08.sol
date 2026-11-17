// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IP { function finalizedWithdrawals(bytes32) external view returns (bool); }
interface IC { function successfulMessages(bytes32) external view returns (bool); function failedMessages(bytes32) external view returns (bool); }

/// Stateless measurement helper, executed only through eth_call / debug_traceCall on the lane's private anvil.
/// Calls the portal with exactly `g` gas (the gas a direct transaction would have left after intrinsic gas)
/// and reports what happened. flags: bit0 call ok, bit1 withdrawal finalized, bit2 successfulMessages, bit3 failedMessages.
contract Probe08 {
    function run(address portal, bytes calldata cd, uint256 g, address cdm, bytes32 wh, bytes32 mh)
        external
        returns (uint256 flags, bytes4 sel, uint256 used)
    {
        require(gasleft() > g + g / 60 + 200_000, "probe: not enough outer gas");
        used = gasleft();
        (bool ok, bytes memory ret) = portal.call{ gas: g }(cd);
        used = used - gasleft();
        if (ret.length >= 4) sel = bytes4(ret);
        if (ok) flags |= 1;
        if (IP(portal).finalizedWithdrawals(wh)) flags |= 2;
        if (IC(cdm).successfulMessages(mh)) flags |= 4;
        if (IC(cdm).failedMessages(mh)) flags |= 8;
    }
}
