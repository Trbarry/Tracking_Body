# Lane 28 selected v8.0.0 -> v9.0.0 source diff

v8 commit: f45a5ccfebcdf6da3f5b09cbc512667c063730b7
v9 commit: ba6fcadbc57eb99918c5b0f14f57c72527f531e3

The following files are byte-for-byte identical and therefore have no hunks: `universal/StandardBridge.sol`, `universal/ERC721Bridge.sol`, and `L2/L2ERC721Bridge.sol`.

## universal/CrossDomainMessenger.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol
index 5dde702..e092e43 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol
@@ -92,32 +92,19 @@ abstract contract CrossDomainMessenger is
     CrossDomainMessengerLegacySpacer1
 {
     /// @notice Current message version identifier.
     uint16 public constant MESSAGE_VERSION = 1;
 
-    /// @notice Constant overhead added to the base gas for a message.
-    uint64 public constant RELAY_CONSTANT_OVERHEAD = 200_000;
-
     /// @notice Numerator for dynamic overhead added to the base gas for a message.
     uint64 public constant MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR = 64;
 
     /// @notice Denominator for dynamic overhead added to the base gas for a message.
     uint64 public constant MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR = 63;
 
     /// @notice Extra gas added to base gas for each byte of calldata in a message.
     uint64 public constant MIN_GAS_CALLDATA_OVERHEAD = 16;
 
-    /// @notice Gas reserved for performing the external call in `relayMessage`.
-    uint64 public constant RELAY_CALL_OVERHEAD = 40_000;
-
-    /// @notice Gas reserved for finalizing the execution of `relayMessage` after the safe call.
-    uint64 public constant RELAY_RESERVED_GAS = 40_000;
-
-    /// @notice Gas reserved for the execution between the `hasMinGas` check and the external
-    ///         call in `relayMessage`.
-    uint64 public constant RELAY_GAS_CHECK_BUFFER = 5_000;
-
     /// @notice Base gas required for any transaction in the EVM.
     uint64 public constant TX_BASE_GAS = 21_000;
 
     /// @notice Floor overhead per byte of non-zero calldata in a message. Calldata floor was
     ///         introduced in EIP-7623.
@@ -223,11 +210,11 @@ abstract contract CrossDomainMessenger is
         uint256 _nonce,
         address _sender,
         address _target,
         uint256 _value,
         uint256 _minGasLimit,
-        bytes calldata _message
+        bytes memory _message
     )
         external
         payable
     {
         // On L1 this function will check the Portal for its paused status.
@@ -267,18 +254,18 @@ abstract contract CrossDomainMessenger is
         require(successfulMessages[versionedHash] == false, "CrossDomainMessenger: message has already been relayed");
 
         // If there is not enough gas left to perform the external call and finish the execution,
         // return early and assign the message to the failedMessages mapping.
         // We are asserting that we have enough gas to:
-        // 1. Call the target contract (_minGasLimit + RELAY_CALL_OVERHEAD + RELAY_GAS_CHECK_BUFFER)
-        //   1.a. The RELAY_CALL_OVERHEAD is included in `hasMinGas`.
-        // 2. Finish the execution after the external call (RELAY_RESERVED_GAS).
+        // 1. Call the target contract (_minGasLimit + call overhead + _localRelayGasCheckBuffer())
+        //   1.a. The call overhead is included in `hasMinGas`.
+        // 2. Finish the execution after the external call (_localRelayReservedGas()).
         //
         // If `xDomainMsgSender` is not the default L2 sender, this function
         // is being re-entered. This marks the message as failed to allow it to be replayed.
         if (
-            !SafeCall.hasMinGas(_minGasLimit, RELAY_RESERVED_GAS + RELAY_GAS_CHECK_BUFFER)
+            !SafeCall.hasMinGas(_minGasLimit, _localRelayReservedGas() + _localRelayGasCheckBuffer())
                 || xDomainMsgSender != Constants.DEFAULT_L2_SENDER
         ) {
             failedMessages[versionedHash] = true;
             emit FailedRelayedMessage(versionedHash);
 
@@ -293,11 +280,11 @@ abstract contract CrossDomainMessenger is
 
             return;
         }
 
         xDomainMsgSender = _sender;
-        bool success = SafeCall.call(_target, gasleft() - RELAY_RESERVED_GAS, _value, _message);
+        bool success = SafeCall.call(_target, gasleft() - _localRelayReservedGas(), _value, _message);
         xDomainMsgSender = Constants.DEFAULT_L2_SENDER;
 
         if (success) {
             // This check is identical to one above, but it ensures that the same message cannot be relayed
             // twice, and adds a layer of protection against rentrancy.
@@ -345,37 +332,75 @@ abstract contract CrossDomainMessenger is
     /// @return Nonce of the next message to be sent, with added message version.
     function messageNonce() public view returns (uint256) {
         return Encoding.encodeVersionedNonce(msgNonce, MESSAGE_VERSION);
     }
 
+    /// @notice Constant costs of `relayMessage` on the other chain, added to the base gas for a message.
+    /// @return Gas added to the base gas for a message.
+    function RELAY_CONSTANT_OVERHEAD() external view virtual returns (uint64);
+
+    /// @notice Gas the other chain needs for the dynamic parts of the CALL opcode in `relayMessage`.
+    /// @return Gas added to the base gas for a message.
+    function RELAY_CALL_OVERHEAD() external view virtual returns (uint64);
+
+    /// @notice Gas the other chain reserves for finishing `relayMessage` after the safe call.
+    /// @return Gas added to the base gas for a message.
+    function RELAY_RESERVED_GAS() external view virtual returns (uint64);
+
+    /// @notice Gas the other chain reserves for the execution between the `hasMinGas` check and
+    ///         the external call in `relayMessage`.
+    /// @return Gas added to the base gas for a message.
+    function RELAY_GAS_CHECK_BUFFER() external view virtual returns (uint64);
+
     /// @notice Computes the amount of gas required to guarantee that a given message will be
     ///         received on the other chain without running out of gas. Guaranteeing that a message
     ///         will not run out of gas is important because this ensures that a message can always
     ///         be replayed on the other chain if it fails to execute completely.
     /// @param _message     Message to compute the amount of required gas for.
     /// @param _minGasLimit Minimum desired gas limit when message goes to target.
     /// @return Amount of gas required to guarantee message receipt.
-    function baseGas(bytes memory _message, uint32 _minGasLimit) public pure returns (uint64) {
+    function baseGas(bytes memory _message, uint32 _minGasLimit) public pure virtual returns (uint64);
+
+    /// @notice Computes `baseGas` from the relay costs of the other chain's messenger.
+    /// @param _message                Message to compute the amount of required gas for.
+    /// @param _minGasLimit            Minimum desired gas limit when message goes to target.
+    /// @param _relayConstantOverhead  Constant costs of `relayMessage` on the other chain.
+    /// @param _relayCallOverhead      Dynamic costs of the CALL opcode on the other chain.
+    /// @param _relayReservedGas       Gas the other chain reserves to finish `relayMessage`.
+    /// @param _relayGasCheckBuffer    Gas the other chain spends between `hasMinGas` and the CALL.
+    /// @return Amount of gas required to guarantee message receipt.
+    function _baseGas(
+        bytes memory _message,
+        uint32 _minGasLimit,
+        uint64 _relayConstantOverhead,
+        uint64 _relayCallOverhead,
+        uint64 _relayReservedGas,
+        uint64 _relayGasCheckBuffer
+    )
+        internal
+        pure
+        returns (uint64)
+    {
         // Base gas should really be computed on the fully encoded message but that would break the
         // expected API, so we instead just add the encoding overhead to the message length inside
         // of this function.
 
         // We need a minimum amount of execution gas to ensure that the message will be received on
         // the other side without running out of gas (stored within the failedMessages mapping).
         // If we get beyond the hasMinGas check, then we *must* supply more than minGasLimit to
         // the external call.
         uint64 executionGas = uint64(
             // Constant costs for relayMessage
-            RELAY_CONSTANT_OVERHEAD
-            // Covers dynamic parts of the CALL opcode
-            + RELAY_CALL_OVERHEAD
-            // Ensures execution of relayMessage completes after call
-            + RELAY_RESERVED_GAS
-            // Buffer between hasMinGas check and the CALL
-            + RELAY_GAS_CHECK_BUFFER
-            // Minimum gas limit, multiplied by 64/63 to account for EIP-150.
-            + ((_minGasLimit * MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR) / MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR)
+            _relayConstantOverhead
+                // Covers dynamic parts of the CALL opcode
+                + _relayCallOverhead
+                // Ensures execution of relayMessage completes after call
+                + _relayReservedGas
+                // Buffer between hasMinGas check and the CALL
+                + _relayGasCheckBuffer
+                // Minimum gas limit, multiplied by 64/63 to account for EIP-150.
+                + ((_minGasLimit * MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR) / MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR)
         );
 
         // Total message size is the result of properly ABI encoding the call to relayMessage.
         // Since we only get the message data and not the rest of the calldata, we use the
         // ENCODING_OVERHEAD constant to conservatively account for the remaining bytes.
@@ -386,15 +411,14 @@ abstract contract CrossDomainMessenger is
         // cost of the message but it doesn't hurt in the L2 -> L1 case. After EIP-7623, the cost
         // of a transaction is floored by its calldata size. We don't need to account for the
         // contract creation case because this is always a call to relayMessage.
         return TX_BASE_GAS
             + uint64(
-                Math.max(
-                    executionGas + (totalMessageSize * MIN_GAS_CALLDATA_OVERHEAD),
-                    (totalMessageSize * FLOOR_CALLDATA_OVERHEAD)
-                )
-            );
+            Math.max(
+            executionGas + (totalMessageSize * MIN_GAS_CALLDATA_OVERHEAD), (totalMessageSize * FLOOR_CALLDATA_OVERHEAD)
+        )
+        );
     }
 
     /// @notice Initializer.
     /// @param _otherMessenger CrossDomainMessenger contract on the other chain.
     function __CrossDomainMessenger_init(CrossDomainMessenger _otherMessenger) internal onlyInitializing {
@@ -430,10 +454,19 @@ abstract contract CrossDomainMessenger is
     ///         CrossDomainMessenger send messages to itself.
     /// @param _target Address of the contract to check.
     /// @return Whether or not the address is an unsafe system address.
     function _isUnsafeTarget(address _target) internal view virtual returns (bool);
 
+    /// @notice Gas reserved on this chain for finalizing `relayMessage` after the safe call.
+    /// @return Gas reserved after the safe call.
+    function _localRelayReservedGas() internal pure virtual returns (uint64);
+
+    /// @notice Gas spent on this chain between the `hasMinGas` check and the external call in
+    ///         `relayMessage`.
+    /// @return Gas reserved between the check and the call.
+    function _localRelayGasCheckBuffer() internal pure virtual returns (uint64);
+
     /// @notice This function should return true if the contract is paused.
     ///         On L1 this function will check the SuperchainConfig for its paused status.
     ///         On L2 this function should be a no-op.
     /// @return Whether or not the contract is paused.
     function paused() public view virtual returns (bool) {
```

## L1/L1CrossDomainMessenger.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol
index cfd91d1..59cf226 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol
@@ -6,10 +6,11 @@ import { ProxyAdminOwnedBase } from "src/universal/ProxyAdminOwnedBase.sol";
 import { ReinitializableBase } from "src/universal/ReinitializableBase.sol";
 import { CrossDomainMessenger } from "src/universal/CrossDomainMessenger.sol";
 
 // Libraries
 import { Predeploys } from "src/libraries/Predeploys.sol";
+import "src/libraries/GasConstants.sol" as GasConstants;
 
 // Interfaces
 import { ISemver } from "interfaces/universal/ISemver.sol";
 import { ISuperchainConfig } from "interfaces/L1/ISuperchainConfig.sol";
 import { ISystemConfig } from "interfaces/L1/ISystemConfig.sol";
@@ -34,12 +35,45 @@ contract L1CrossDomainMessenger is CrossDomainMessenger, ProxyAdminOwnedBase, Re
     /// @custom:spacer systemConfig
     /// @notice Spacer taking up the legacy `systemConfig` slot.
     address private spacer_253_0_20;
 
     /// @notice Semantic version.
-    /// @custom:semver 2.11.1
-    string public constant version = "2.11.1";
+    /// @custom:semver 2.13.0
+    string public constant version = "2.13.0";
+
+    /// @notice See `GasConstants.L1_RELAY_RESERVED_GAS`.
+    uint64 internal constant LOCAL_RELAY_RESERVED_GAS = GasConstants.L1_RELAY_RESERVED_GAS;
+
+    /// @notice See `GasConstants.L1_RELAY_GAS_CHECK_BUFFER`.
+    uint64 internal constant LOCAL_RELAY_GAS_CHECK_BUFFER = GasConstants.L1_RELAY_GAS_CHECK_BUFFER;
+
+    /// @notice See `GasConstants.L2_RELAY_CONSTANT_OVERHEAD`.
+    uint64 internal constant REMOTE_RELAY_CONSTANT_OVERHEAD = GasConstants.L2_RELAY_CONSTANT_OVERHEAD;
+
+    /// @notice See `GasConstants.RELAY_CALL_OVERHEAD`.
+    uint64 internal constant REMOTE_RELAY_CALL_OVERHEAD = GasConstants.RELAY_CALL_OVERHEAD;
+
+    /// @notice See `GasConstants.L2_RELAY_RESERVED_GAS`.
+    uint64 internal constant REMOTE_RELAY_RESERVED_GAS = GasConstants.L2_RELAY_RESERVED_GAS;
+
+    /// @notice See `GasConstants.L2_RELAY_GAS_CHECK_BUFFER`.
+    uint64 internal constant REMOTE_RELAY_GAS_CHECK_BUFFER = GasConstants.L2_RELAY_GAS_CHECK_BUFFER;
+
+    // Public getters kept for ABI compatibility. They report the remote budgets that `baseGas` uses;
+    // this contract reads the `LOCAL_` and `REMOTE_` constants directly.
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_CONSTANT_OVERHEAD = REMOTE_RELAY_CONSTANT_OVERHEAD;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_CALL_OVERHEAD = REMOTE_RELAY_CALL_OVERHEAD;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_RESERVED_GAS = REMOTE_RELAY_RESERVED_GAS;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_GAS_CHECK_BUFFER = REMOTE_RELAY_GAS_CHECK_BUFFER;
 
     /// @notice Contract of the SystemConfig.
     ISystemConfig public systemConfig;
 
     /// @notice Constructs the L1CrossDomainMessenger contract.
@@ -77,18 +111,26 @@ contract L1CrossDomainMessenger is CrossDomainMessenger, ProxyAdminOwnedBase, Re
     /// @custom:legacy
     function PORTAL() external view returns (IOptimismPortal) {
         return portal;
     }
 
+    /// @inheritdoc CrossDomainMessenger
+    function baseGas(bytes memory _message, uint32 _minGasLimit) public pure override returns (uint64) {
+        return _baseGas({
+            _message: _message,
+            _minGasLimit: _minGasLimit,
+            _relayConstantOverhead: REMOTE_RELAY_CONSTANT_OVERHEAD,
+            _relayCallOverhead: REMOTE_RELAY_CALL_OVERHEAD,
+            _relayReservedGas: REMOTE_RELAY_RESERVED_GAS,
+            _relayGasCheckBuffer: REMOTE_RELAY_GAS_CHECK_BUFFER
+        });
+    }
+
     /// @inheritdoc CrossDomainMessenger
     function _sendMessage(address _to, uint64 _gasLimit, uint256 _value, bytes memory _data) internal override {
         portal.depositTransaction{ value: _value }({
-            _to: _to,
-            _value: _value,
-            _gasLimit: _gasLimit,
-            _isCreation: false,
-            _data: _data
+            _to: _to, _value: _value, _gasLimit: _gasLimit, _isCreation: false, _data: _data
         });
     }
 
     /// @inheritdoc CrossDomainMessenger
     function _isOtherMessenger() internal view override returns (bool) {
@@ -97,6 +139,16 @@ contract L1CrossDomainMessenger is CrossDomainMessenger, ProxyAdminOwnedBase, Re
 
     /// @inheritdoc CrossDomainMessenger
     function _isUnsafeTarget(address _target) internal view override returns (bool) {
         return _target == address(this) || _target == address(portal);
     }
+
+    /// @inheritdoc CrossDomainMessenger
+    function _localRelayReservedGas() internal pure override returns (uint64) {
+        return LOCAL_RELAY_RESERVED_GAS;
+    }
+
+    /// @inheritdoc CrossDomainMessenger
+    function _localRelayGasCheckBuffer() internal pure override returns (uint64) {
+        return LOCAL_RELAY_GAS_CHECK_BUFFER;
+    }
 }
```

## L2/L2CrossDomainMessenger.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L2/L2CrossDomainMessenger.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L2/L2CrossDomainMessenger.sol
index a3ee891..40ad500 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L2/L2CrossDomainMessenger.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L2/L2CrossDomainMessenger.sol
@@ -6,10 +6,11 @@ import { CrossDomainMessenger } from "src/universal/CrossDomainMessenger.sol";
 import { ProxyAdminOwnedBase } from "src/universal/ProxyAdminOwnedBase.sol";
 
 // Libraries
 import { AddressAliasHelper } from "src/vendor/AddressAliasHelper.sol";
 import { Predeploys } from "src/libraries/Predeploys.sol";
+import "src/libraries/GasConstants.sol" as GasConstants;
 
 // Interfaces
 import { ISemver } from "interfaces/universal/ISemver.sol";
 import { IL2ToL1MessagePasser } from "interfaces/L2/IL2ToL1MessagePasser.sol";
 
@@ -18,12 +19,45 @@ import { IL2ToL1MessagePasser } from "interfaces/L2/IL2ToL1MessagePasser.sol";
 /// @title L2CrossDomainMessenger
 /// @notice The L2CrossDomainMessenger is a high-level interface for message passing between L1 and
 ///         L2 on the L2 side. Users are generally encouraged to use this contract instead of lower
 ///         level message passing contracts.
 contract L2CrossDomainMessenger is ProxyAdminOwnedBase, CrossDomainMessenger, ISemver {
-    /// @custom:semver 2.2.1
-    string public constant version = "2.2.1";
+    /// @custom:semver 2.4.0
+    string public constant version = "2.4.0";
+
+    /// @notice See `GasConstants.L2_RELAY_RESERVED_GAS`.
+    uint64 internal constant LOCAL_RELAY_RESERVED_GAS = GasConstants.L2_RELAY_RESERVED_GAS;
+
+    /// @notice See `GasConstants.L2_RELAY_GAS_CHECK_BUFFER`.
+    uint64 internal constant LOCAL_RELAY_GAS_CHECK_BUFFER = GasConstants.L2_RELAY_GAS_CHECK_BUFFER;
+
+    /// @notice See `GasConstants.L1_RELAY_CONSTANT_OVERHEAD`.
+    uint64 internal constant REMOTE_RELAY_CONSTANT_OVERHEAD = GasConstants.L1_RELAY_CONSTANT_OVERHEAD;
+
+    /// @notice See `GasConstants.RELAY_CALL_OVERHEAD`.
+    uint64 internal constant REMOTE_RELAY_CALL_OVERHEAD = GasConstants.RELAY_CALL_OVERHEAD;
+
+    /// @notice See `GasConstants.L1_RELAY_RESERVED_GAS`.
+    uint64 internal constant REMOTE_RELAY_RESERVED_GAS = GasConstants.L1_RELAY_RESERVED_GAS;
+
+    /// @notice See `GasConstants.L1_RELAY_GAS_CHECK_BUFFER`.
+    uint64 internal constant REMOTE_RELAY_GAS_CHECK_BUFFER = GasConstants.L1_RELAY_GAS_CHECK_BUFFER;
+
+    // Public getters kept for ABI compatibility. They report the remote budgets that `baseGas` uses;
+    // this contract reads the `LOCAL_` and `REMOTE_` constants directly.
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_CONSTANT_OVERHEAD = REMOTE_RELAY_CONSTANT_OVERHEAD;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_CALL_OVERHEAD = REMOTE_RELAY_CALL_OVERHEAD;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_RESERVED_GAS = REMOTE_RELAY_RESERVED_GAS;
+
+    /// @inheritdoc CrossDomainMessenger
+    uint64 public constant override RELAY_GAS_CHECK_BUFFER = REMOTE_RELAY_GAS_CHECK_BUFFER;
 
     /// @notice Constructs the L2CrossDomainMessenger contract.
     constructor() {
         _disableInitializers();
     }
@@ -41,10 +75,22 @@ contract L2CrossDomainMessenger is ProxyAdminOwnedBase, CrossDomainMessenger, IS
     /// @custom:legacy
     function l1CrossDomainMessenger() public view returns (CrossDomainMessenger) {
         return otherMessenger;
     }
 
+    /// @inheritdoc CrossDomainMessenger
+    function baseGas(bytes memory _message, uint32 _minGasLimit) public pure override returns (uint64) {
+        return _baseGas({
+            _message: _message,
+            _minGasLimit: _minGasLimit,
+            _relayConstantOverhead: REMOTE_RELAY_CONSTANT_OVERHEAD,
+            _relayCallOverhead: REMOTE_RELAY_CALL_OVERHEAD,
+            _relayReservedGas: REMOTE_RELAY_RESERVED_GAS,
+            _relayGasCheckBuffer: REMOTE_RELAY_GAS_CHECK_BUFFER
+        });
+    }
+
     /// @inheritdoc CrossDomainMessenger
     function _sendMessage(address _to, uint64 _gasLimit, uint256 _value, bytes memory _data) internal override {
         IL2ToL1MessagePasser(payable(Predeploys.L2_TO_L1_MESSAGE_PASSER)).initiateWithdrawal{ value: _value }(
             _to, _gasLimit, _data
         );
@@ -57,6 +103,16 @@ contract L2CrossDomainMessenger is ProxyAdminOwnedBase, CrossDomainMessenger, IS
 
     /// @inheritdoc CrossDomainMessenger
     function _isUnsafeTarget(address _target) internal view override returns (bool) {
         return _target == address(this) || _target == address(Predeploys.L2_TO_L1_MESSAGE_PASSER);
     }
+
+    /// @inheritdoc CrossDomainMessenger
+    function _localRelayReservedGas() internal pure override returns (uint64) {
+        return LOCAL_RELAY_RESERVED_GAS;
+    }
+
+    /// @inheritdoc CrossDomainMessenger
+    function _localRelayGasCheckBuffer() internal pure override returns (uint64) {
+        return LOCAL_RELAY_GAS_CHECK_BUFFER;
+    }
 }
```

## libraries/SafeCall.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/libraries/SafeCall.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/SafeCall.sol
index a8ae9ec..a539135 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/libraries/SafeCall.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/SafeCall.sol
@@ -2,27 +2,30 @@
 pragma solidity ^0.8.0;
 
 /// @title SafeCall
 /// @notice Perform low level safe calls
 library SafeCall {
+    /// @notice EIP-8037 state gas for a CALL that sends value to an empty account: 120 bytes at
+    ///         1,530 gas per byte. The CALL charges it before the 63/64 split.
+    uint256 internal constant NEW_ACCOUNT_STATE_GAS = 183_600;
+
     /// @notice Performs a low level call without copying any returndata.
     /// @dev Passes no calldata to the call context.
     /// @param _target   Address to call
     /// @param _gas      Amount of gas to pass to the call
     /// @param _value    Amount of value to pass to the call
     function send(address _target, uint256 _gas, uint256 _value) internal returns (bool success_) {
         assembly {
-            success_ :=
-                call(
-                    _gas, // gas
-                    _target, // recipient
-                    _value, // ether value
-                    0, // inloc
-                    0, // inlen
-                    0, // outloc
-                    0 // outlen
-                )
+            success_ := call(
+                _gas, // gas
+                _target, // recipient
+                _value, // ether value
+                0, // inloc
+                0, // inlen
+                0, // outloc
+                0 // outlen
+            )
         }
     }
 
     /// @notice Perform a low level call with all gas without copying any returndata
     /// @param _target   Address to call
@@ -44,20 +47,19 @@ library SafeCall {
     )
         internal
         returns (bool success_)
     {
         assembly {
-            success_ :=
-                call(
-                    _gas, // gas
-                    _target, // recipient
-                    _value, // ether value
-                    add(_calldata, 32), // inloc
-                    mload(_calldata), // inlen
-                    0, // outloc
-                    0 // outlen
-                )
+            success_ := call(
+                _gas, // gas
+                _target, // recipient
+                _value, // ether value
+                add(_calldata, 32), // inloc
+                mload(_calldata), // inlen
+                0, // outloc
+                0 // outlen
+            )
         }
     }
 
     /// @notice Perform a low level call without copying any returndata
     /// @param _target   Address to call
@@ -87,11 +89,12 @@ library SafeCall {
     ///      1.) The 40_000 base buffer is to account for the worst case of the dynamic cost of the
     ///          `CALL` opcode's `address_access_cost`, `positive_value_cost`, and
     ///          `value_to_empty_account_cost` factors with an added buffer of 5,700 gas. It is
     ///          still possible to self-rekt by initiating a withdrawal with a minimum gas limit
     ///          that does not account for the `memory_expansion_cost` & `code_execution_cost`
-    ///          factors of the dynamic cost of the `CALL` opcode.
+    ///          factors of the dynamic cost of the `CALL` opcode. Under EIP-8037, value to an
+    ///          empty account also costs `NEW_ACCOUNT_STATE_GAS`, which callers must reserve.
     ///      2.) This function should *directly* precede the external call if possible. There is an
     ///          added buffer to account for gas consumed between this check and the call, but it
     ///          is only 5,700 gas.
     ///      3.) Because EIP-150 ensures that a maximum of 63/64ths of the remaining gas in the call
     ///          frame may be passed to a subcontext, we need to ensure that the gas will not be
@@ -111,23 +114,26 @@ library SafeCall {
     ///         gas.
     /// @param _target   Address to call
     /// @param _minGas   The minimum amount of gas that may be passed to the call
     /// @param _value    Amount of value to pass to the call
     /// @param _calldata Calldata to pass to the call
+    /// @dev Sending value to an account with no code, balance or nonce also requires
+    ///      `NEW_ACCOUNT_STATE_GAS`. `EXTCODEHASH` returns zero for exactly those accounts.
     function callWithMinGas(
         address _target,
         uint256 _minGas,
         uint256 _value,
         bytes memory _calldata
     )
         internal
         returns (bool)
     {
         bool _success;
-        bool _hasMinGas = hasMinGas(_minGas, 0);
+        uint256 newAccountGas = _value != 0 && _target.codehash == bytes32(0) ? NEW_ACCOUNT_STATE_GAS : 0;
+        bool _hasMinGas = hasMinGas(_minGas, newAccountGas);
         assembly {
-            // Assertion: gasleft() >= (_minGas * 64) / 63 + 40_000
+            // Assertion: gasleft() >= (_minGas * 64) / 63 + 40_000 + newAccountGas
             if iszero(_hasMinGas) {
                 // Store the "Error(string)" selector in scratch space.
                 mstore(0, 0x08c379a0)
                 // Store the pointer to the string length in scratch space.
                 mstore(32, 32)
@@ -150,19 +156,18 @@ library SafeCall {
             // The call will be supplied at least ((_minGas * 64) / 63) gas due to the
             // above assertion. This ensures that, in all circumstances (except for when the
             // `_minGas` does not account for the `memory_expansion_cost` and `code_execution_cost`
             // factors of the dynamic cost of the `CALL` opcode), the call will receive at least
             // the minimum amount of gas specified.
-            _success :=
-                call(
-                    gas(), // gas
-                    _target, // recipient
-                    _value, // ether value
-                    add(_calldata, 32), // inloc
-                    mload(_calldata), // inlen
-                    0x00, // outloc
-                    0x00 // outlen
-                )
+            _success := call(
+                gas(), // gas
+                _target, // recipient
+                _value, // ether value
+                add(_calldata, 32), // inloc
+                mload(_calldata), // inlen
+                0x00, // outloc
+                0x00 // outlen
+            )
         }
         return _success;
     }
 }
```

## libraries/Constants.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/libraries/Constants.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/Constants.sol
index 5e5d5d1..33c9277 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/libraries/Constants.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/Constants.sol
@@ -49,11 +49,11 @@ library Constants {
 
     /// @notice Special constant key for the PermittedProxyDeployment instruction.
     string internal constant PERMITTED_PROXY_DEPLOYMENT_KEY = "PermittedProxyDeployment";
 
     /// @notice Special constant value for the PermittedProxyDeployment instruction to permit all
-    ///         contracts to be deployed. Used for both initial deployments and migrations.
+    ///         contracts to be deployed. Used for initial deployments only.
     bytes internal constant PERMIT_ALL_CONTRACTS_INSTRUCTION = bytes("ALL");
 
     /// @notice Current bundle artifact path for Network Upgrade Transaction bundles.
     string internal constant CURRENT_BUNDLE_PATH = "snapshots/upgrades/current-upgrade-bundle.json";
```

## L1/OptimismPortal2.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol
index 7714b67..f16a3b9 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol
@@ -9,10 +9,11 @@ import { ReinitializableBase } from "src/universal/ReinitializableBase.sol";
 
 // Libraries
 import { EOA } from "src/libraries/EOA.sol";
 import { SafeCall } from "src/libraries/SafeCall.sol";
 import { Constants } from "src/libraries/Constants.sol";
+import { Predeploys } from "src/libraries/Predeploys.sol";
 import { Types } from "src/libraries/Types.sol";
 import { Hashing } from "src/libraries/Hashing.sol";
 import { SecureMerkleTrie } from "src/libraries/trie/SecureMerkleTrie.sol";
 import { AddressAliasHelper } from "src/vendor/AddressAliasHelper.sol";
 import { Claim, GameStatus, GameType, GameTypes } from "src/dispute/lib/Types.sol";
@@ -119,14 +120,13 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     uint256 private spacer_61_0_32;
 
     /// @notice Address of the AnchorStateRegistry contract.
     IAnchorStateRegistry public anchorStateRegistry;
 
-    /// @notice Address of the ETHLockbox contract. NOTE that as of v4.1.0 it is not possible to
-    ///         set this value in storage and it is only possible for this value to be set if the
-    ///         chain was first upgraded to v4.0.0. Chains that skip v4.0.0 will not have any
-    ///         ETHLockbox set here.
+    /// @notice Address of the ETHLockbox contract. Set by `initialize` when given a nonzero
+    ///         lockbox and by `migrateToSharedDisputeGame`. Must be nonzero while the ETH_LOCKBOX
+    ///         feature is enabled.
     IETHLockbox public ethLockbox;
 
     /// @custom:legacy
     /// @custom:spacer superRootsActive
     bool private spacer_63_20_1;
@@ -170,10 +170,15 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     /// @notice Emitted when a withdrawal transaction is finalized.
     /// @param withdrawalHash Hash of the withdrawal transaction.
     /// @param success        Whether the withdrawal transaction was successful.
     event WithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);
 
+    /// @notice Emitted when a proof for a withdrawal transaction is deleted.
+    /// @param withdrawalHash Hash of the withdrawal transaction.
+    /// @param proofSubmitter Address of the proof submitter.
+    event WithdrawalProofDeleted(bytes32 indexed withdrawalHash, address indexed proofSubmitter);
+
     /// @notice Thrown when a withdrawal has already been finalized.
     error OptimismPortal_AlreadyFinalized();
 
     /// @notice Thrown when the target of a withdrawal is unsafe.
     error OptimismPortal_BadTarget();
@@ -212,10 +217,14 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     error OptimismPortal_InvalidProofTimestamp();
 
     /// @notice Thrown when the root claim of a dispute game is invalid.
     error OptimismPortal_InvalidRootClaim();
 
+    /// @notice Thrown when a withdrawal from the L2CrossDomainMessenger fails in the
+    ///         L1CrossDomainMessenger.
+    error OptimismPortal_L1CDMCallFailed();
+
     /// @notice Thrown when migrating to the registry that was previously
     /// set on the OptimismPortal prior to the migration
     error OptimismPortal_MigratingToSameRegistry();
 
     /// @notice Thrown when a withdrawal is being finalized by a reentrant call.
@@ -223,10 +232,13 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
 
     /// @notice Thrown when calling a function that is only available when INTEROP
     /// is enabled
     error OptimismPortal_NotUsingInterop();
 
+    /// @notice Thrown when calling a function that requires an active ETHLockbox.
+    error OptimismPortal_NotUsingLockbox();
+
     /// @notice Thrown when a withdrawal has not been proven for long enough.
     error OptimismPortal_ProofNotOldEnough();
 
     /// @notice Thrown when a withdrawal has not been proven.
     error OptimismPortal_Unproven();
@@ -238,14 +250,17 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     error OptimismPortal_ZeroAddress();
 
     /// @notice Thrown when the new lockbox has not authorized this portal.
     error OptimismPortal_LockboxNotAuthorizedForPortal();
 
+    /// @notice Thrown when a dispute game has not been permanently invalidated.
+    error OptimismPortal_DisputeGameNotInvalidated();
+
     /// @notice Semantic version.
-    /// @custom:semver 5.8.0
+    /// @custom:semver 6.1.0
     function version() public pure virtual returns (string memory) {
-        return "5.8.0";
+        return "6.1.0";
     }
 
     /// @param _proofMaturityDelaySeconds The proof maturity delay in seconds.
     constructor(uint256 _proofMaturityDelaySeconds) ReinitializableBase(3) {
         PROOF_MATURITY_DELAY_SECONDS = _proofMaturityDelaySeconds;
@@ -287,11 +302,11 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
         __ResourceMetering_init();
     }
 
     /// @notice Getter for the current paused status.
     function paused() public view returns (bool) {
-        return systemConfig.paused();
+        return ethLockbox.paused();
     }
 
     /// @notice Getter for the proof maturity delay.
     function proofMaturityDelaySeconds() public view returns (uint256) {
         return PROOF_MATURITY_DELAY_SECONDS;
@@ -303,17 +318,17 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     }
 
     /// @notice Returns the SuperchainConfig contract.
     /// @return ISuperchainConfig The SuperchainConfig contract.
     function superchainConfig() external view returns (ISuperchainConfig) {
-        return systemConfig.superchainConfig();
+        return ethLockbox.superchainConfig();
     }
 
     /// @custom:legacy
     /// @notice Getter function for the address of the guardian.
     function guardian() external view returns (address) {
-        return systemConfig.guardian();
+        return ethLockbox.guardian();
     }
 
     /// @custom:legacy
     /// @notice Getter for the dispute game finality delay.
     function disputeGameFinalityDelaySeconds() external view returns (uint256) {
@@ -451,15 +466,15 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
         // on L2. If this is true, under the assumption that the SecureMerkleTrie does not have
         // bugs, then we know that this withdrawal was actually triggered on L2 and can therefore
         // be relayed on L1.
         if (
             SecureMerkleTrie.verifyInclusionProof({
-                _key: abi.encode(storageKey),
-                _value: hex"01",
-                _proof: _withdrawalProof,
-                _root: _outputRootProof.messagePasserStorageRoot
-            }) == false
+                    _key: abi.encode(storageKey),
+                    _value: hex"01",
+                    _proof: _withdrawalProof,
+                    _root: _outputRootProof.messagePasserStorageRoot
+                }) == false
         ) {
             revert OptimismPortal_InvalidMerkleProof();
         }
 
         // Designate the withdrawalHash as proven by storing the disputeGameProxy and timestamp in
@@ -480,16 +495,19 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
     /// @param _tx Withdrawal transaction to finalize.
     function finalizeWithdrawalTransaction(Types.WithdrawalTransaction memory _tx) external {
         finalizeWithdrawalTransactionExternalProof(_tx, msg.sender);
     }
 
-    /// @notice Migrates the total ETH balance of this contract to the ETHLockbox.
+    /// @notice Migrates the total ETH balance of this contract to the ETHLockbox. Custom gas
+    ///         token chains keep custody in the portal and cannot migrate ETH.
     function migrateLiquidity() public {
-        if (!_isUsingInterop()) revert OptimismPortal_NotUsingInterop();
+        if (!_isUsingLockbox()) revert OptimismPortal_NotUsingLockbox();
         // Liquidity migration can only be triggered by the ProxyAdmin owner.
         _assertOnlyProxyAdminOwner();
 
+        if (_isUsingCustomGasToken()) revert OptimismPortal_NotAllowedOnCGTMode();
+
         // Migrate the liquidity.
         uint256 ethBalance = address(this).balance;
         ethLockbox.lockETH{ value: ethBalance }();
         emit ETHMigrated(address(ethLockbox), ethBalance);
     }
@@ -609,28 +627,44 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
         bool success = SafeCall.callWithMinGas(_tx.target, _tx.gasLimit, _tx.value, _tx.data);
 
         // Reset the l2Sender back to the default value.
         l2Sender = Constants.DEFAULT_L2_SENDER;
 
-        // All withdrawals are immediately finalized. Replayability can
+        // Reverting here is useful for determining the exact gas cost to successfully execute the
+        // sub call to the target contract if the minimum gas limit specified by the user would not
+        // be sufficient to execute the sub call.
+        if (!success && tx.origin == Constants.ESTIMATION_ADDRESS) {
+            revert OptimismPortal_GasEstimation();
+        }
+
+        // A failed call means the L1CrossDomainMessenger reverted without recording the message,
+        // e.g. because it ran out of gas. Revert so the withdrawal stays unfinalized and can be
+        // finalized again with more gas, instead of being finalized with no way to replay it.
+        //
+        // Not every messenger failure is a gas problem. The messenger reverts whatever the gas
+        // when the message targets an unsafe address (the L1CrossDomainMessenger or this
+        // contract) or is a legacy message that was already relayed. Such withdrawals can be
+        // proven but never finalized, where before they were finalized as failed. Their funds
+        // stay locked in the same place either way.
+        //
+        // Checking the sender is enough because the L2CrossDomainMessenger only initiates
+        // withdrawals to `otherMessenger`, and blocks `L2ToL1MessagePasser` as a relay target.
+        if (!success && _tx.sender == Predeploys.L2_CROSS_DOMAIN_MESSENGER) {
+            revert OptimismPortal_L1CDMCallFailed();
+        }
+
+        // All other withdrawals are immediately finalized. Replayability can
         // be achieved through contracts built on top of this contract
         emit WithdrawalFinalized(withdrawalHash, success);
 
         // If using ETHLockbox, send ETH back to the Lockbox in the case of a failed transaction or
         // it'll get stuck here and would need to be moved back via admin action.
         if (_isUsingLockbox()) {
             if (!success && _tx.value > 0) {
                 ethLockbox.lockETH{ value: _tx.value }();
             }
         }
-
-        // Reverting here is useful for determining the exact gas cost to successfully execute the
-        // sub call to the target contract if the minimum gas limit specified by the user would not
-        // be sufficient to execute the sub call.
-        if (!success && tx.origin == Constants.ESTIMATION_ADDRESS) {
-            revert OptimismPortal_GasEstimation();
-        }
     }
 
     /// @notice Checks that a withdrawal has been proven and is ready to be finalized.
     /// @param _withdrawalHash Hash of the withdrawal.
     /// @param _proofSubmitter Address of the proof submitter.
@@ -668,10 +702,33 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
         if (!anchorStateRegistry.isGameClaimValid(disputeGameProxy)) {
             revert OptimismPortal_InvalidRootClaim();
         }
     }
 
+    /// @notice Deletes a withdrawal proof whose dispute game can never lead to finalization.
+    ///         Permissionless because both conditions checked here are permanent.
+    /// @param _withdrawalHash Hash of the withdrawal.
+    /// @param _proofSubmitter Address of the proof submitter.
+    function deleteProvenWithdrawal(bytes32 _withdrawalHash, address _proofSubmitter) external {
+        ProvenWithdrawal memory provenWithdrawal = provenWithdrawals[_withdrawalHash][_proofSubmitter];
+        if (provenWithdrawal.timestamp == 0) {
+            revert OptimismPortal_Unproven();
+        }
+
+        IDisputeGame disputeGameProxy = provenWithdrawal.disputeGameProxy;
+        if (
+            disputeGameProxy.status() != GameStatus.CHALLENGER_WINS
+                && !anchorStateRegistry.isGameBlacklisted(disputeGameProxy)
+        ) {
+            revert OptimismPortal_DisputeGameNotInvalidated();
+        }
+
+        delete provenWithdrawals[_withdrawalHash][_proofSubmitter];
+
+        emit WithdrawalProofDeleted(_withdrawalHash, _proofSubmitter);
+    }
+
     /// @notice Accepts deposits of ETH and data, and emits a TransactionDeposited event for use in
     ///         deriving deposit transactions. Note that if a deposit is made by a contract, its
     ///         address will be aliased when retrieved using `tx.origin` or `msg.sender`. Consider
     ///         using the CrossDomainMessenger contracts for a simpler developer experience.
     /// @dev    The `msg.value` is locked on the ETHLockbox and minted as ETH when the deposit
@@ -776,16 +833,13 @@ contract OptimismPortal2 is Initializable, ResourceMetering, ReinitializableBase
         if (systemConfig.isFeatureEnabled(Features.INTEROP) && !systemConfig.isFeatureEnabled(Features.ETH_LOCKBOX)) {
             revert OptimismPortal_InvalidInteropState();
         }
     }
 
-    /// @notice Asserts that the ETHLockbox is set/unset correctly depending on the feature flag.
+    /// @notice Asserts that the ETHLockbox is configured.
     function _assertValidLockboxState() internal view {
-        if (
-            systemConfig.isFeatureEnabled(Features.ETH_LOCKBOX) && address(ethLockbox) == address(0)
-                || !systemConfig.isFeatureEnabled(Features.ETH_LOCKBOX) && address(ethLockbox) != address(0)
-        ) {
+        if (!systemConfig.isFeatureEnabled(Features.ETH_LOCKBOX) || address(ethLockbox) == address(0)) {
             revert OptimismPortal_InvalidLockboxState();
         }
     }
 
     /// @notice Checks if a target address is unsafe.
```

## L1/L1StandardBridge.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1StandardBridge.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1StandardBridge.sol
index b8943aa..e3ddd58 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1StandardBridge.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1StandardBridge.sol
@@ -112,12 +112,11 @@ contract L1StandardBridge is StandardBridge, ProxyAdminOwnedBase, Reinitializabl
         _assertOnlyProxyAdminOrProxyAdminOwner();
 
         // Now perform initialization logic.
         systemConfig = _systemConfig;
         __StandardBridge_init({
-            _messenger: _messenger,
-            _otherBridge: StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE))
+            _messenger: _messenger, _otherBridge: StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE))
         });
     }
 
     /// @inheritdoc StandardBridge
     function paused() public view override returns (bool) {
```

## L2/L2StandardBridge.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L2/L2StandardBridge.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L2/L2StandardBridge.sol
index d2a70b0..78d0fdc 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L2/L2StandardBridge.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L2/L2StandardBridge.sol
@@ -71,12 +71,11 @@ contract L2StandardBridge is ProxyAdminOwnedBase, StandardBridge, ISemver {
     /// @notice Initializer.
     /// @param _otherBridge Contract for the corresponding bridge on the other chain.
     function initialize(StandardBridge _otherBridge) external initializer {
         _assertOnlyProxyAdminOrProxyAdminOwner();
         __StandardBridge_init({
-            _messenger: ICrossDomainMessenger(Predeploys.L2_CROSS_DOMAIN_MESSENGER),
-            _otherBridge: _otherBridge
+            _messenger: ICrossDomainMessenger(Predeploys.L2_CROSS_DOMAIN_MESSENGER), _otherBridge: _otherBridge
         });
     }
 
     /// @notice Allows EOAs to bridge ETH by sending directly to the bridge.
     receive() external payable override onlyEOA {
```

## L1/L1ERC721Bridge.sol

```diff
diff --git a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol
index 8753b1f..51d5574 100644
--- a/home/user/ethereum-optimism/op-v8.0.0/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol
@@ -57,11 +57,13 @@ contract L1ERC721Bridge is ERC721Bridge, ProxyAdminOwnedBase, ReinitializableBas
         // Initialization transactions must come from the ProxyAdmin or its owner.
         _assertOnlyProxyAdminOrProxyAdminOwner();
 
         // Now perform initialization logic.
         systemConfig = _systemConfig;
-        __ERC721Bridge_init({ _messenger: _messenger, _otherBridge: ERC721Bridge(payable(Predeploys.L2_ERC721_BRIDGE)) });
+        __ERC721Bridge_init({
+            _messenger: _messenger, _otherBridge: ERC721Bridge(payable(Predeploys.L2_ERC721_BRIDGE))
+        });
     }
 
     /// @inheritdoc ERC721Bridge
     function paused() public view override returns (bool) {
         return systemConfig.paused();
```

## libraries/GasConstants.sol (new in v9)

```diff
diff --git a/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/GasConstants.sol b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/GasConstants.sol
new file mode 100644
index 0000000..35732a1
--- /dev/null
+++ b/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/libraries/GasConstants.sol
@@ -0,0 +1,78 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.0;
+
+// Gas budgets for `CrossDomainMessenger.relayMessage`, named for the chain the relay executes on. A
+// messenger uses its own chain's values in `relayMessage` and the other chain's values in `baseGas`,
+// so each value must cover the worst case on the chain it is named for. `RELAY_CALL_OVERHEAD` is
+// shared because `SafeCall.hasMinGas` is.
+// File-level rather than a library so that contract constants can be initialized from them. Import
+// as `import "src/libraries/GasConstants.sol" as GasConstants;`. NatSpec on file-level constants
+// accepts only `@dev`.
+
+////////////////////////////////////////////////////////////////
+//                     Constant overhead                      //
+////////////////////////////////////////////////////////////////
+
+// Covers `relayMessage` from entry up to the `hasMinGas` check: the pause check, version decode,
+// message hashing, cold reads of `successfulMessages` and `failedMessages`, the other-messenger
+// check (on L1, the portal's `l2Sender()` call) and the target checks. Used only by `baseGas`. Too
+// low, and a relay given exactly `baseGas` fails the check and is recorded as failed instead of
+// executing.
+// To set: measure that path on the chain's EVM with cold storage, and add margin.
+
+/// @dev Set empirically before Glamsterdam. The Amsterdam measurement under `RELAY_CALL_OVERHEAD`
+///      shows its slack also absorbs EIP-8037 state gas for value sent to a new account.
+uint64 constant L1_RELAY_CONSTANT_OVERHEAD = 200_000;
+
+/// @dev Set empirically.
+uint64 constant L2_RELAY_CONSTANT_OVERHEAD = 200_000;
+
+////////////////////////////////////////////////////////////////
+//                       Call overhead                        //
+////////////////////////////////////////////////////////////////
+
+// `SafeCall.hasMinGas` requires 40,000 gas above `minGasLimit * 64 / 63` for the CALL's dynamic
+// costs (cold access, value transfer, new account). Used only by `baseGas`, which must supply at
+// least that much. Shared by both chains because `SafeCall.hasMinGas` is.
+// To set: at least the allowance hardcoded in `SafeCall.hasMinGas`. Change them together.
+
+/// @dev On L1, sending value to a new account also costs EIP-8037 state gas (183,600), which this
+///      does not cover; `baseGas` absorbs it in the other budgets' slack. Measured under Amsterdam,
+///      an empty message needs 391,338 against a `baseGas` of 415,160.
+///      `test_relayMessage_valueToNewAccount_succeeds` covers it.
+uint64 constant RELAY_CALL_OVERHEAD = 40_000;
+
+////////////////////////////////////////////////////////////////
+//                        Reserved gas                        //
+////////////////////////////////////////////////////////////////
+
+// `relayMessage` forwards `gasleft()` minus this to the target, so it covers the CALL's own charges
+// (value transfer, cold target access, EIP-7702 delegate access) and everything after the call:
+// resetting `xDomainMsgSender`, writing `successfulMessages` or `failedMessages` (a fresh slot) and
+// emitting the event. Too low, and a target that uses all its gas makes the relay revert after the
+// call, so the message is recorded in neither mapping and cannot be replayed.
+// To set: on the chain's EVM, find the smallest reserve that still records a value-carrying message
+// to a cold EIP-7702 delegated target that burns all forwarded gas, and add margin.
+// `test_relayMessage_valueToColdDelegatedTarget_succeeds` covers this case on L1.
+
+/// @dev Includes EIP-8037 state gas for the fresh slot (97,920). Measured minimum under Amsterdam:
+///      127,089.
+uint64 constant L1_RELAY_RESERVED_GAS = 135_000;
+
+/// @dev Measured minimum under Prague: 35,969.
+uint64 constant L2_RELAY_RESERVED_GAS = 40_000;
+
+////////////////////////////////////////////////////////////////
+//                      Gas check buffer                      //
+////////////////////////////////////////////////////////////////
+
+// Covers the work between the `hasMinGas` check and the CALL: setting `xDomainMsgSender` (a warm,
+// nonzero-to-nonzero write, so no state gas) and preparing the call's arguments. Too low, and the
+// target can receive less than `minGasLimit`.
+// To set: the cost of that window on the chain's EVM, rounded up generously.
+
+/// @dev The `xDomainMsgSender` write alone costs 10,100 under Amsterdam.
+uint64 constant L1_RELAY_GAS_CHECK_BUFFER = 15_000;
+
+/// @dev The `xDomainMsgSender` write alone costs 2,900 under Prague.
+uint64 constant L2_RELAY_GAS_CHECK_BUFFER = 5_000;
```

