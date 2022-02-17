pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

contract TestSeller {

    ERC20Contract private _erc20;
    ERC721Contract private _erc721;

    constructor(address erc20, address erc721) { // 토큰 instance 설정
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    }

    // NFT별 가격을 저장할 mapping
    mapping(uint256 => uint256) private _tokenPrice;

    function enrollNFT(uint256 tokenId, uint256 price) public { // NFT 판매 등록 함수
        require( // 실제 토큰소유자가 호출했는지, 권한 위임(별개)했는지 체크
            _erc721.ownerOf(tokenId) == msg.sender &&
            _erc721.getApproved(tokenId) == address(this),
            "TestSeller: Authentication error"
        );

        // 가격 저장
        _tokenPrice[tokenId] = price;
    }

    function purchaseNFT(uint256 tokenId) public { // NFT 구매 함수
        address _owner = _erc721.ownerOf(tokenId);
        _erc20.transferFrom(msg.sender, _owner, _tokenPrice[tokenId]);  // erc20:  구매자 -price-> 판매자 
        _erc721.transferFrom(_owner, msg.sender, tokenId);              // erc721: 판매자 -token-> 구매자 
    }

    function getNFTPrice(uint256 tokenId) public view returns (uint256) { // NFT 가격 확인 함수
        return _tokenPrice[tokenId];
    }
}