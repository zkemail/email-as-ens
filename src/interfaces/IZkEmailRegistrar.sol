// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

struct ProveAndClaimCommand {
    // e.g ["com", "gmail"]
    string[] domainName;
    // e.g email@gmail.com
    string emailAddress;
    // on-chain owner of email@gmail.com.zk.eth
    address owner;
    // RSA pubkey data of domainName (e.g public key of gmail.com) - Usually 144 to 528 bytes! can be set to 0x0 if
    // verifier doesn't need the raw publicKey for verification
    // e.g with ICP oracle raw public key is not required but for DNSSEC oracle the raw public key is needed.
    bytes dkimSiger;
    // hash of RSA pubkey
    bytes32 dkimSignerHash;
    // used to prevent double use of the command
    bytes32 emailNullifier;
    // signed timestamp in email header. 0 if not supported (e.g outlook.com dosn't sign timestamp)
    uint256 timestamp;
    // ignored here but needed for zk proof verification
    bytes32 accountSalt;
    // same
    bool embededCode;
    // zkemail proof of validity of the fields of this struct
    bytes proof;
}

interface IZkEmailRegistrar {
    function proveAndClaim(ProveAndClaimCommand memory command) external;
    function proveAndClaimWithResolver(ProveAndClaimCommand memory command, address resolver, address addr) external;
}
