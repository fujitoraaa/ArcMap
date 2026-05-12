// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ==========================================
// THƯ VIỆN RENDER SVG ĐỘC LẬP
// ==========================================
library ArcMapSVG {
    using Strings for uint256;

    function getMonthName(uint256 month) internal pure returns (string memory) {
        string[12] memory months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return months[month - 1];
    }

    function timestampToDate(uint256 timestamp) public pure returns (string memory) {
        uint256 z = timestamp / 86400 + 719468;
        uint256 era = (z >= 0 ? z : z - 146096) / 146097;
        uint256 doe = uint256(z - era * 146097);
        uint256 yoe = (doe - doe/1460 + doe/36524 - doe/146096) / 365;
        uint256 y = uint256(yoe) + era * 400;
        uint256 doy = doe - (365*yoe + yoe/4 - yoe/100);
        uint256 mp = (5*doy + 2)/153;
        uint256 d = doy - (153*mp + 2)/5 + 1;
        uint256 m = mp < 10 ? mp + 3 : mp - 9;
        y = m <= 2 ? y + 1 : y;
        return string(abi.encodePacked(getMonthName(m), " ", d.toString(), ", ", y.toString()));
    }

    function generateSVG(string memory domainName, uint256 timestamp) public pure returns (string memory) {
        string memory dateStr = timestampToDate(timestamp);
        string memory pinPath = "M50 10C33.4 10 20 23.4 20 40C20 62.5 50 90 50 90C50 90 80 62.5 80 40C80 23.4 66.6 10 50 10ZM50 55C41.7 55 35 48.3 35 40C35 31.7 41.7 25 50 25C58.3 25 65 31.7 65 40C65 48.3 58.3 55 50 55ZM42 46L50 28L58 46H52L50 41L48 46H42Z";

        return string(abi.encodePacked(
            '<svg width="1000" height="1000" viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">',
            '<defs>',
                '<linearGradient id="bgG" x1="0%" y1="0%" x2="100%" y2="100%">',
                    '<stop offset="0%" style="stop-color:#020b14;stop-opacity:1" />',
                    '<stop offset="100%" style="stop-color:#1e3a4d;stop-opacity:1" />',
                '</linearGradient>',
                '<linearGradient id="rainbow" x1="0%" y1="0%" x2="100%" y2="0%">',
                    '<stop offset="0%" style="stop-color:#00f2fe;stop-opacity:1" /><stop offset="50%" style="stop-color:#f8ea7e;stop-opacity:1" /><stop offset="100%" style="stop-color:#ff00de;stop-opacity:1" />',
                '</linearGradient>',
                '<filter id="glow"><feGaussianBlur stdDeviation="3" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
                '<pattern id="p" x="0" y="0" width="160" height="160" patternUnits="userSpaceOnUse" patternTransform="rotate(-10)">',
                    '<path d="', pinPath, '" fill="white" fill-opacity="0.08" transform="scale(0.8) translate(20,20)"/>',
                    '<path d="', pinPath, '" fill="white" fill-opacity="0.04" transform="scale(0.8) translate(120,120)"/>',
                '</pattern>',
            '</defs>',
            '<rect width="1000" height="1000" fill="url(#bgG)"/>',
            '<rect width="1000" height="1000" fill="url(#p)"/>',
            '<rect x="30" y="30" width="940" height="940" rx="80" fill="none" stroke="white" stroke-width="2" opacity="0.2" filter="url(#glow)"/>',
            '<text x="80" y="160" font-family="Arial, sans-serif" font-size="80" font-weight="900" fill="url(#rainbow)" filter="url(#glow)">@', domainName, '.arc</text>',
            '<g transform="translate(600, 830)">',
                '<path d="M40 10C25 10 13 22 13 37C13 58 40 85 40 85C40 85 67 58 67 37C67 22 55 10 40 10ZM40 52C32 52 25 45 25 37C25 29 32 22 40 22C48 22 55 29 55 37C55 45 48 52 40 52Z" fill="white" filter="url(#glow)"/>',
                '<text x="95" y="70" font-family="Arial, sans-serif" font-size="65" font-weight="900" fill="white">ARCMAP</text>',
                '<text x="130" y="125" font-family="Arial, sans-serif" font-size="32" font-weight="bold" fill="white" opacity="0.6">', dateStr, '</text>',
            '</g>',
            '</svg>'
        ));
    }
}

// ==========================================
// CONTRACT CHÍNH
// ==========================================
contract ARCMAP is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;
    IERC20 public usdcToken;
    uint256 public pricePerYear = 5 * 10**6; 

    mapping(string => address) public domains;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(string => uint256) public domainExpiry;
    mapping(uint256 => uint256) public mintTimestamp;

    error InvalidDuration();
    error DomainTakenOrNotExpired();
    error PaymentFailed();

    constructor(address _usdcAddress) ERC721("Arc Domain Registry", "ARCNS") Ownable(msg.sender) {
        usdcToken = IERC20(_usdcAddress);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory name = tokenIdToDomain[tokenId];
        uint256 ts = mintTimestamp[tokenId];
        
        string memory svg = Base64.encode(bytes(ArcMapSVG.generateSVG(name, ts)));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "@', name, '.arc", "image": "data:image/svg+xml;base64,', svg, '"}'
        ))));
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function mintDomain(string memory domainName, uint256 yearsToRegister) public {
        if (yearsToRegister == 0) revert InvalidDuration();
        if (domains[domainName] != address(0) && block.timestamp <= domainExpiry[domainName]) revert DomainTakenOrNotExpired();
        
        uint256 totalCost = pricePerYear * yearsToRegister;
        if (!usdcToken.transferFrom(msg.sender, address(this), totalCost)) revert PaymentFailed();
        
        uint256 tokenId = _nextTokenId++;
        domains[domainName] = msg.sender;
        tokenIdToDomain[tokenId] = domainName;
        domainExpiry[domainName] = block.timestamp + (yearsToRegister * 365 days);
        mintTimestamp[tokenId] = block.timestamp;
        
        _mint(msg.sender, tokenId);
    }

    function getDomainsByOwner(address owner) public view returns (string[] memory) {
        uint256 balance = balanceOf(owner);
        string[] memory result = new string[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenIdToDomain[tokenOfOwnerByIndex(owner, i)];
        }
        return result;
    }

    function getOwner(string memory domainName) public view returns (address) {
        if (block.timestamp > domainExpiry[domainName]) return address(0);
        return domains[domainName];
    }

    function withdrawUSDC(address to) external onlyOwner {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        usdcToken.transfer(to, balance);
    }

    function setPricePerYear(uint256 newPrice) external onlyOwner {
        pricePerYear = newPrice;
    }
}
