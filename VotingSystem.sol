// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationVotingSystem {
    struct Proposal {
        string name;
        uint voteCount;
        uint creationTime;
        bool active;
    }

    struct Voter {
        uint reputation;
        bool hasVoted;
        uint voteWeight;
    }

    Proposal[] public proposals;
    address public owner;
    address[] public voterAddresses;  // Array to store voter addresses

    mapping(address => Voter) public voters;

    event ProposalCreated(uint proposalId, string name);
    event VoteCast(address indexed voter, uint proposalId, uint weight);
    event ProposalDeactivated(uint proposalId);
    event VotingReset();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier proposalExists(uint proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist.");
        _;
    }

    modifier proposalIsActive(uint proposalId) {
        require(proposals[proposalId].active, "Proposal is not active.");
        _;
    }

    function createProposal(string memory name) public onlyOwner {
        proposals.push(Proposal({
            name: name,
            voteCount: 0,
            creationTime: block.timestamp,
            active: true
        }));
        emit ProposalCreated(proposals.length - 1, name);
    }

    function registerVoter(address voter, uint reputation) public onlyOwner {
        require(voters[voter].reputation == 0, "Voter already registered.");
        voters[voter] = Voter({
            reputation: reputation,
            hasVoted: false,
            voteWeight: 0
        });
        voterAddresses.push(voter);  // Add voter address to the array
    }

    function calculateVoteWeight(address voter) public view returns (uint) {
        return voters[voter].reputation * 1 ether;
    }

    function vote(uint proposalId) public proposalExists(proposalId) proposalIsActive(proposalId) {
        Voter storage voter = voters[msg.sender];
        require(!voter.hasVoted, "You have already voted.");
        require(voter.reputation > 0, "No reputation assigned.");

        voter.voteWeight = calculateVoteWeight(msg.sender);
        proposals[proposalId].voteCount += voter.voteWeight;
        voter.hasVoted = true;

        emit VoteCast(msg.sender, proposalId, voter.voteWeight);
    }

    function deactivateProposal(uint proposalId) public onlyOwner proposalExists(proposalId) {
        proposals[proposalId].active = false;
        emit ProposalDeactivated(proposalId);
    }

    function resetVoting() public onlyOwner {
        for (uint i = 0; i < proposals.length; i++) {
            proposals[i].voteCount = 0;
            proposals[i].active = true;
        }

        for (uint i = 0; i < voterAddresses.length; i++) {
            address voterAddr = voterAddresses[i];
            voters[voterAddr].hasVoted = false;
            voters[voterAddr].voteWeight = 0;
        }

        emit VotingReset();
    }

    function getWinningProposal() public view returns (string memory winningProposalName) {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].active && proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        winningProposalName = proposals[winningProposalIndex].name;
    }

    function getProposal(uint proposalId) public view proposalExists(proposalId) returns (string memory name, uint voteCount, bool active) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.name, proposal.voteCount, proposal.active);
    }
}
