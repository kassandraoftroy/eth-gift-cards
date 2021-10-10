// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {
    ERC721,
    ERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IENS, IResolver} from "./ENS.sol";
import "./Base64.sol";


// solhint-disable
contract EthGiftCards is ERC721Enumerable, Ownable, ReentrancyGuard {

    struct Card {
        uint256 value;
        uint256 theme;
        string ens;
        string[6] note;
        address issuer;
    }

    bytes32 constant SUFFIX = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes('eth'))));

    uint256 public lastThemeId;
    uint256 public lastTokenId;
    mapping(uint256 => string) public themes;
    mapping(uint256 => Card) public cards;
    IENS private ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    constructor(
        string memory name_,
        string memory symbol_,
        string[] memory themes_
    ) ERC721(name_, symbol_) {
        addThemes(themes_);
    }

    function addThemes(string[] memory themes_) public onlyOwner() {
        uint256 len = themes_.length;
        uint256 currentTotal = lastThemeId;
        for (uint256 i=0; i<len; i++) {
            themes[currentTotal+i+1] = themes_[i];
        }
        lastThemeId += len;
    }

    function mint(string[6] memory note_, uint32 theme_, address firstOwner, string memory ensPrefix_) external payable nonReentrant() {
        require(msg.value > 0, 'no value');
        require(theme_ > 0 && theme_ <= lastThemeId, 'invalid theme');
        for (uint256 i=0; i<6; i++) {
            require(bytes(note_[i]).length <= 42, 'note line too long');
        }
        require(keccak256(bytes(ensPrefix_)) == keccak256(bytes("")) || msg.sender==resolve(ensPrefix_), 'ens does not resolve');
        lastTokenId += 1;
        uint256 newTokenId = lastTokenId;
        cards[newTokenId] = Card({
            theme: theme_,
            note: note_,
            ens: ensPrefix_,
            issuer: msg.sender,
            value: msg.value
        });
        _safeMint(firstOwner, newTokenId);
    }

    function burn(uint256 tokenId) external nonReentrant() {
        require(msg.sender == ownerOf(tokenId), "caller not owner");
        uint256 amount = cards[tokenId].value;
        delete cards[tokenId];
        _burn(tokenId);
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "failed to send eth");
    }

    function resolve(string memory ensPrefix_) public view returns(address) {
        bytes32 node = keccak256(abi.encodePacked(SUFFIX, keccak256(bytes(ensPrefix_))));
        IResolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Card memory card = cards[tokenId];

        string[17] memory parts;
        parts[0] = themes[card.theme];
        parts[1] = getValueString(card.value);
        parts[2] = ' /><text x="10" y="60" class="base"> from: ';
        parts[3] = getIssuerString(card.issuer, card.ens);
        parts[4] = ' ETH</text><text x="10" y="100" class="base">note:</text><text x="30" y="120" class="base">';
        parts[5] = card.note[0];
        parts[6] = '</text><text x="30" y="140" class="base">';
        parts[7] = card.note[1];
        parts[8] = '</text><text x="30" y="160" class="base">';
        parts[9] = card.note[2];
        parts[10] = '</text><text x="30" y="180" class="base">';
        parts[11] = card.note[3];
        parts[12] = '</text><text x="30" y="200" class="base">';
        parts[13] = card.note[4];
        parts[14] = '</text><text x="30" y="220" class="base">';
        parts[15] = card.note[5];
        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Gift Card #', uint2str(tokenId), '", "description": "Eth Gift Cards are Ether wrapped as an ERC721 NFT with a custom note. Owner can burn the NFT to retreive the Ether.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function getIssuerString(address issuer_, string memory ens_) internal pure returns (string memory) {
        if (keccak256(bytes(ens_)) == keccak256(bytes(""))) {
            return string(abi.encodePacked("0x", addr2str(issuer_)));
        } else {
            return string(abi.encodePacked(ens_, ".eth"));
        }
    }

    function getValueString(uint256 value_) internal pure returns (string memory) {
        uint256 end = value_ % 1 ether;
        uint256 start = value_ / 1 ether;
        string memory startString = uint2str(start);
        string memory endString = uint2str(end);
        while (bytes(endString).length < 17) {
            endString = string(abi.encodePacked("0", endString));
        }
        return string(abi.encodePacked(startString, ".", endString));
    }

    function addr2str(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {}
}