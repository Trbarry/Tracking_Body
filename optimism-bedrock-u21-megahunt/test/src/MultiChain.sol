// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// F6 historical harness — piece 5: handles for the L1 contracts of the four chains upgraded by the
// U21 transaction (OP Mainnet 10, Ink 57073, Soneium 1868, Unichain 130), so that one test body can
// run against each of them:
//
//     function test_x() public { _forkAt(26433900); _forEachChain(this.body); }
//     function body(OpChain memory c) external { IPortal(c.portal).depositTransaction(...); }
//
// Addresses: PASS A U21_PROXY_IMPLEMENTATION_MAP.md section 2 and LANE_CONTEXT.md section 3 (read at
// L1 blocks 26430858 / 26430859 / 26433900). `_resolveChain` re-derives every handle from the
// chain's SystemConfig on the active fork (works from portal >= 4.x / SystemConfig >= 3.x, i.e. U16
// on); MultiChain.t.sol asserts table == resolved at the post-U21 pin.
//
// L2 side: only OP Mainnet has a local archive proxy (http://127.0.0.1:7546). Ink, Soneium and
// Unichain L2 state must be read passively from public RPCs (name the endpoint in your report).

import "./Ifaces.sol";

struct OpChain {
    string name;
    uint256 chainId;
    address systemConfig;
    address portal;
    address lockbox;
    address l1cdm;
    address l1Bridge;
    address erc721Bridge;
    address erc20Factory;
    address dgf;
    address asr;
    address delayedWeth; // the DelayedWETH proxy touched by the U21 tx
    address addressManager;
    address proxyAdmin;
}

library Chains {
    uint256 internal constant COUNT = 4;
    uint256 internal constant OP = 0;
    uint256 internal constant INK = 1;
    uint256 internal constant SONEIUM = 2;
    uint256 internal constant UNICHAIN = 3;

    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C; // shared by all four
    address internal constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // Safe, owner of all four ProxyAdmins
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    // Base is NOT part of the U21 transaction; its portal is listed only for negative controls.
    address internal constant BASE_PORTAL = 0x49048044D57e1C92A77f79988d21Fa8fAF74E97e;

    function get(uint256 i) internal pure returns (OpChain memory c) {
        if (i == OP) {
            c.name = "OP Mainnet";
            c.chainId = 10;
            c.systemConfig = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
            c.portal = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
            c.lockbox = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
            c.l1cdm = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
            c.l1Bridge = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
            c.erc721Bridge = 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D;
            c.erc20Factory = 0x75505a97BD334E7BD3C476893285569C4136Fa0F;
            c.dgf = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
            c.asr = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
            c.delayedWeth = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
            c.addressManager = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
            c.proxyAdmin = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
        } else if (i == INK) {
            c.name = "Ink";
            c.chainId = 57073;
            c.systemConfig = 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364;
            c.portal = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
            c.lockbox = 0xbd4AbB321138e8Eddc399cE64E66451294325a14;
            c.l1cdm = 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f;
            c.l1Bridge = 0x88FF1e5b602916615391F55854588EFcBB7663f0;
            c.erc721Bridge = 0x661235a238B11191211fa95D4Dd9E423d521E0Be;
            c.erc20Factory = 0xA8B389A82e088b164cD03230e900980CcED34d29;
            c.dgf = 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD;
            c.asr = 0xEe018bAf058227872540AC60eFbd38b023d9dAe2;
            c.delayedWeth = 0x57b4C29DAee99a28E6E86778b499361294c134eA;
            c.addressManager = 0x9b7C9BbD6d540A8A4dEDd935819fC4408Ba71153;
            c.proxyAdmin = 0xd56045E68956FCe2576E680c95a4750cf8241f79;
        } else if (i == SONEIUM) {
            c.name = "Soneium";
            c.chainId = 1868;
            c.systemConfig = 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3;
            c.portal = 0x88e529A6ccd302c948689Cd5156C83D4614FAE92;
            c.lockbox = 0x67B4de6FfA66EF201Ea6099A89cA397D56622E31;
            c.l1cdm = 0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f;
            c.l1Bridge = 0xeb9bf100225c214Efc3E7C651ebbaDcF85177607;
            c.erc721Bridge = 0x5933e323bE8896DfaCd1cD671442F27dAA10a053;
            c.erc20Factory = 0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F;
            c.dgf = 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0;
            c.asr = 0x4890928941e62e273dA359374b105F803329F473;
            c.delayedWeth = 0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47;
            c.addressManager = 0xB24bFEeCE1B3b7A44559F4Cbc21BeD312b130b70;
            c.proxyAdmin = 0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a;
        } else if (i == UNICHAIN) {
            c.name = "Unichain";
            c.chainId = 130;
            c.systemConfig = 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6;
            c.portal = 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2;
            c.lockbox = 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5;
            c.l1cdm = 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6;
            c.l1Bridge = 0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA;
            c.erc721Bridge = 0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf;
            c.erc20Factory = 0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad;
            c.dgf = 0x2F12d621a16e2d3285929C9996f478508951dFe4;
            c.asr = 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9;
            c.delayedWeth = 0x74ad145aC900F1DD5551F0C9E143314DC4022FCf;
            c.addressManager = 0x8098F676033A377b9Defe302e9fE6877cD63D575;
            c.proxyAdmin = 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4;
        } else {
            revert("Chains: bad index");
        }
    }
}

abstract contract MultiChain {
    /// @notice Hard-coded handles of chain `i` (Chains.OP / INK / SONEIUM / UNICHAIN).
    function _chain(uint256 i) internal pure returns (OpChain memory) {
        return Chains.get(i);
    }

    /// @notice Handles of chain `i` re-derived from its SystemConfig on the ACTIVE fork (U16 or
    ///         later). delayedWeth, addressManager and proxyAdmin have no on-chain pointer from the
    ///         SystemConfig in every era and are copied from the table.
    function _resolveChain(uint256 i) internal view returns (OpChain memory c) {
        c = Chains.get(i);
        ISystemConfig sc = ISystemConfig(c.systemConfig);
        c.chainId = sc.l2ChainId();
        c.portal = sc.optimismPortal();
        c.l1cdm = sc.l1CrossDomainMessenger();
        c.l1Bridge = sc.l1StandardBridge();
        c.erc721Bridge = sc.l1ERC721Bridge();
        c.erc20Factory = sc.optimismMintableERC20Factory();
        c.dgf = sc.disputeGameFactory();
        c.lockbox = IPortal(c.portal).ethLockbox();
        c.asr = IPortal(c.portal).anchorStateRegistry();
    }

    /// @notice Runs `body` once per chain. `body` must be an external function of the test contract
    ///         (`this.body`). State changes of one iteration are visible to the next; wrap the body
    ///         in vm.snapshotState / vm.revertToStateAndDelete if the iterations must be independent.
    function _forEachChain(function(OpChain memory) external body) internal {
        for (uint256 i; i < Chains.COUNT; i++) {
            body(Chains.get(i));
        }
    }

    function _sameHandles(OpChain memory a, OpChain memory b) internal pure returns (bool) {
        return a.chainId == b.chainId && a.systemConfig == b.systemConfig && a.portal == b.portal && a.lockbox == b.lockbox
            && a.l1cdm == b.l1cdm && a.l1Bridge == b.l1Bridge && a.erc721Bridge == b.erc721Bridge
            && a.erc20Factory == b.erc20Factory && a.dgf == b.dgf && a.asr == b.asr;
    }
}
