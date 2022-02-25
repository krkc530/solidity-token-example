pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

contract TestAuction {

    ERC20Contract private _erc20;
    ERC721Contract private _erc721;

    mapping (uint256 => address) private _highestBidder; // 가장 높은 가격 제시한 사람
    mapping (uint256 => uint256) private _highestBid; // 가장 높은 가격
    mapping (uint256 => bool) _enrollList; // NFT 등록 여부
    mapping (uint256 => uint256) private _endTime; // NFT bid 종료 시간

    constructor(address erc20, address erc721) { // 토큰 instance 설정
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    }

    function enrollNFT(uint256 tokenId, uint256 startPrice, uint256 deltaTime) public { // NFT 경매 등록 
        require( // 실제 토큰소유자가 호출했는지, 권한 위임(별개)했는지 체크
            _erc721.ownerOf(tokenId) == msg.sender &&
            _erc721.getApproved(tokenId) == address(this),
            "TestAuction: Authentication error"
        );
        require( // 등록 상태 체크
            !_enrollList[tokenId],
            "TestAuction: Token already enrolled"
        );

        _enrollList[tokenId] = true;    // NFT 등록
        _highestBid[tokenId] = startPrice;  // 시작가 저장
        _endTime[tokenId] = block.timestamp + deltaTime; // 종료 시간 저장
    }

    function bidNFT(uint256 tokenId, uint256 bidPrice) public { // NFT 입찰
        require( // 등록 여부 체크
            _enrollList[tokenId] = true,
            "TestAuction: NFT not enrolled"
        );
        require( // 가격 체크
            _highestBid[tokenId] < bidPrice,
            "TestAuction: Amount error"
        );
        require( // 종료 시간 체크
            _endTime[tokenId] > block.timestamp,
            "TestAuction: Timeout"
        );
        
        _highestBid[tokenId] = bidPrice; // 가격 업데이트
        _highestBidder[tokenId] = msg.sender; // 예비 낙찰자 업데이트

    }

    function endAuction(uint256 tokenId) public { // 경매 종료
        require( // 종료 시간 체크
            _endTime[tokenId] <= block.timestamp,
            "TestAuction: Not closed yet"
        );

        address _owner = _erc721.ownerOf(tokenId);
        _erc20.transferFrom(_highestBidder[tokenId], _owner, _highestBid[tokenId]);  // erc20:  구매자 -price-> 판매자 
        _erc721.transferFrom(_owner, _highestBidder[tokenId], tokenId);              // erc721: 판매자 -token-> 구매자 

        // 등록 초기화
        _enrollList[tokenId] = false;
    }

    function getBidPrice(uint256 tokenId) public view returns (uint256) {
        return _highestBid[tokenId];
    }

}
