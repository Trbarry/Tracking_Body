// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
    function initBonds(uint32) external view returns (uint256);
}
interface IGame {
    function weth() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function status() external view returns (uint8);
    function version() external view returns (string memory);
    function l2ChainId() external view returns (uint256);
}
interface IW {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function systemConfig() external view returns (address);
    function config() external view returns (address);
}

contract EnumTest is Test {
    address[] seenW;
    address[] seenA;
    mapping(address => bool) sw;
    mapping(address => bool) sa;
    mapping(address => uint256) firstIdx;
    mapping(address => uint256) lastIdx;

    function _fork() internal { string memory f = vm.envOr("FORK", string("l1")); vm.createSelectFork(f, keccak256(bytes(f)) == keccak256("l1") ? 26433900 : 26430858); }
    function _addr(address t, string memory sig) internal view returns (address r) {
        (bool ok, bytes memory d) = t.staticcall{gas: 300000}(abi.encodeWithSignature(sig));
        if (ok && d.length == 32) r = abi.decode(d, (address));
    }
    function _str(address t, string memory sig) internal view returns (string memory r) {
        (bool ok, bytes memory d) = t.staticcall{gas: 300000}(abi.encodeWithSignature(sig));
        if (ok && d.length >= 64) r = abi.decode(d, (string));
    }
    function _scan(string memory name, address dgf, uint256 stride, uint256 tail) internal {
        delete seenW; delete seenA;
        uint256 n = IDGF(dgf).gameCount();
        emit log_named_uint(string.concat(name, " gameCount"), n);
        for (uint256 i = 0; i < n; ) {
            (uint32 gt,, address g) = IDGF(dgf).gameAtIndex(i);
            address w; address a;
            w = _addr(g, "weth()"); a = _addr(g, "anchorStateRegistry()");
            if (!sw[w]) { sw[w] = true; seenW.push(w); firstIdx[w] = i; emit log_named_uint(string.concat("  new weth at idx (gt ", vm.toString(gt), ") ", vm.toString(w)), i); }
            lastIdx[w] = i;
            if (!sa[a]) { sa[a] = true; seenA.push(a); emit log_named_uint(string.concat("  new asr at idx ", vm.toString(a)), i); }
            if (i + tail >= n) i += 1; else if (i + stride + tail >= n) i = n - tail; else i += stride;
        }
        for (uint256 k; k < seenW.length; k++) {
            address w = seenW[k];
            if (w == address(0)) continue;
            string memory v = _str(w, "version()"); address lb = _addr(w, "ethLockbox()"); address sc = _addr(w, "systemConfig()"); address cfg = _addr(w, "config()");
            emit log_string(string.concat("  WETH ", vm.toString(w), " v", v, " lockbox ", vm.toString(lb), " sysCfg ", vm.toString(sc), " config ", vm.toString(cfg)));
            emit log_named_decimal_uint("     balance", w.balance, 18);
            emit log_named_uint("     first idx", firstIdx[w]);
            emit log_named_uint("     last idx", lastIdx[w]);
            emit log_named_bytes32("     impl", vm.load(w, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));
        }
        uint32[11] memory gts = [uint32(0),1,4,5,6,7,8,9,10,254,255];
        for (uint256 k; k < gts.length; k++) {
            address impl = IDGF(dgf).gameImpls(gts[k]);
            if (impl == address(0)) continue;
            emit log_string(string.concat("  gameImpl ", vm.toString(gts[k]), " = ", vm.toString(impl), " bond ", vm.toString(IDGF(dgf).initBonds(gts[k]))));
            try IDGF(dgf).gameArgs(gts[k]) returns (bytes memory ga) { emit log_named_bytes("     args", ga); } catch {}
        }
    }

    function test_enum_op() public { _fork(); _scan("op", 0xe5965Ab5962eDc7477C8520243A95517CD252fA9, 700, 25); }
    function test_enum_ink() public { _fork(); _scan("ink", 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD, 700, 25); }
    function test_enum_soneium() public { _fork(); _scan("soneium", 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0, 700, 25); }
    function test_enum_unichain() public { _fork(); _scan("unichain", 0x2F12d621a16e2d3285929C9996f478508951dFe4, 700, 25); }
}
