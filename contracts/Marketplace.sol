pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

import "./payment/Purchasable.sol";
import "./payment/Borrowable.sol";
import "./token/ERC20/ERC20.sol";
import "./entity/Asset.sol";
import "./reward/TokenPool.sol";

import "./Component.sol";


contract Marketplace is Component {
  
  using SafeMath for uint256;   

  // Address where funds are collected
  TokenPool private tokenPool;

  // The Asset being sold
  Purchasable public purchasable;
  Borrowable public borrowable;

  /**
   * Event for token purchase logging
   * @param _purchaser - who paid for the tokens
   * @param _seller - who got the tokens
   * @param _value - weis paid for purchase
   */
  event OrderSuccess(
  address indexed _purchaser,
  address indexed _seller,
  uint256 _value
  );

  /**
   * Event for token purchase logging
   * @param _purchaser - who paid for the tokens
   * @param _seller - who got the tokens
   * @param _value - weis paid for purchase
   */
  event LeaseSuccess(
    address indexed _purchaser,
    address indexed _seller,
    uint256 _value
  );

  /**
   * @dev Constructor for this contract.
   * @param _tokenPool - Address where collected revenue will be forwarded to
   * @param _asset - Address of the token being sold
   */
  constructor(
    TokenPool _tokenPool, 
    Asset _asset
  ) 
    public 
  {
    tokenPool = _tokenPool;

    purchasable = Purchasable(_asset);
    borrowable = Borrowable(_asset);
  }
  
  /**
   * @dev Execute auction
   * @param _assetId ID of the AIA token to query the owner of
   */
  function order(
    uint256 _assetId
  ) 
    public 
    payable
    whenNotPaused
    returns (bool)
  {
    address seller = purchasable.sellerOf(_assetId);
    uint256 price = purchasable.priceOf(_assetId);

    require(seller != address(0));
    require(seller != msg.sender);

    if (purchasable.isOnAuction(_assetId)) {
      tokenPool.fundTo(msg.sender, price);
      purchasable.executeAuction(msg.sender, _assetId, price);

      emit OrderSuccess(msg.sender, seller, price);

      return true;
    }

    return false;
  }

  /**
   * @dev Execute auction multiply 
   * @param _assetIds ID list of the AIA token to query the owner of
   */
  function orderSeveral(
    uint256[] _assetIds
  ) 
    public 
    payable
    whenNotPaused
    returns (bool)
  {
    address seller = borrowable.sellerOneOf(_assetIds);
    require(seller != address(0));
    require(seller != msg.sender);

    bool result = true;
    for (uint i = 0; i < _assetIds.length; i++) {
      result = order(_assetIds[i]) && result;
    }

    return result;
  }
}