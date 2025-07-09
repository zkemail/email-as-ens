// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IGroth16Verifier {
    /**
     * @notice Verifies a Groth16 zero-knowledge proof
     * @param _pA The first component of the proof (A point)
     * @param _pB The second component of the proof (B point)
     * @param _pC The third component of the proof (C point)
     * @param _pubSignals The public signals used in the proof verification
     * @return True if the proof is valid, false otherwise
     * @dev This function verifies a Groth16 zk-SNARK proof by checking that the proof
     *      satisfies the circuit constraints defined by the public signals.
     */
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[60] calldata _pubSignals
    )
        external
        view
        returns (bool);
}
