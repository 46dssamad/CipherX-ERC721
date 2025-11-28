// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "/Interfaces/IERC721.sol";
import "/Interfaces/IERC721Receiver.sol";

contract CipherX is IERC721 {
    
    // --- MAPPINGS ---
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- READ FUNCTIONS ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Address is zero");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- APPROVAL FUNCTIONS ---

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        // Requirement: Caller must be Owner OR Operator
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");
        
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // --- TRANSFER FUNCTIONS ---

    // Internal helper that updates the database (mappings)
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "From is not the owner");
        require(to != address(0), "Transfer to zero address");

        // 1. Clear approvals from previous owner
        delete _tokenApprovals[tokenId];

        // 2. Update balances
        _balances[from] -= 1;
        _balances[to] += 1;

        // 3. Update owner
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        
        // Authorization Logic:
        // 1. Is msg.sender the Owner?
        // 2. Is msg.sender the 'Approved' address (from getApproved)?
        // 3. Is msg.sender an 'Operator' (from isApprovedForAll)?
        bool isSpender = (msg.sender == owner || 
                          getApproved(tokenId) == msg.sender || 
                          isApprovedForAll(owner, msg.sender));
                          
        require(isSpender, "Not authorized to transfer");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        transferFrom(from, to, tokenId);
        // The Safety Check
        require(_checkOnERC721Received(from, to, tokenId, ""), "Transfer to non ERC721Receiver implementer");
    }

    // --- MINT FUNCTION (For Homework Testing) ---
    
    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "Mint to zero address");
        require(_owners[tokenId] == address(0), "Token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // --- INTERNAL SAFETY CHECK ---
    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        uint256 size;
        assembly { size := extcodesize(to) } // Check if address is a contract
        
        if (size > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true; // If it's a regular user wallet, it's safe
        }
    }
}