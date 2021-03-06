// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;


  // <skuCount>
  uint public skuCount;
//  uint public dbgPrice;

  // <items mapping>
  mapping (uint => Item) public items;

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State { ForSale, Sold, Shipped, Received }


  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable buyer;
    address payable seller;
  }
  /*
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);

  // <LogSold event: sku arg>
  event LogSold(uint sku);
  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);

  /*
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner
  modifier isOwner (address _address) {
    require (owner == _address);
    _;
  }

  modifier verifyCaller (uint _sku, State _state) {
      if (_state == State.Shipped){
        require (msg.sender == items[_sku].seller);
      }
      if (_state == State.Received){
        require (msg.sender == items[_sku].buyer);
      }
    _;
  }

  modifier paidEnough(uint _sku) {
    require(msg.value >= items[_sku].price);
    _;
  }

  modifier checkValue2(uint _sku, uint _val) {
    uint _price = items[_sku].price;
    uint buyerBal =  items[_sku].buyer.balance;
    uint sellerBal = items[_sku].seller.balance;
    _;
    //require(buyerBal - items[_sku].buyer.balance == _val - _price);
    require(items[_sku].seller.balance - sellerBal== _price);

    //refund them after pay for item (why it is before, _ checks for logic before func)
    //require(items[_sku].sku != 0);

    //uint _price = items[_sku].price;
    //uint amountToRefund = msg.value - _price;
    //items[_sku].buyer.transfer(amountToRefund);
    _;
  }
  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    address payable buyer = payable(items[_sku].buyer);

    buyer.transfer(amountToRefund);
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  modifier forSale(uint _sku){
      require(items[_sku].state == State.ForSale);
      _;
  }
    modifier sold(uint _sku){
      require(items[_sku].state == State.Sold);
      _;
  }
    modifier shipped(uint _sku){
      require(items[_sku].state == State.Shipped);
      _;
  }
    modifier received(uint _sku){
      require(items[_sku].state == State.Received);
      _;
  }
  // modifier sold(uint _sku)
  // modifier shipped(uint _sku)
  // modifier received(uint _sku)

  constructor() public payable {
      owner = msg.sender;
      skuCount = 0;
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
  }

  function addItem(string memory _name, uint _price) public returns (bool) {

      Item memory myItem = Item(_name, skuCount, _price, State.ForSale, payable(address(0)), payable(msg.sender));
      items[skuCount] = myItem;
      emit LogForSale(skuCount);
      skuCount += 1;
      return true;


    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true

    // hint:
    // items[skuCount] = Item({
    //  name: _name,
    //  sku: skuCount,
    //  price: _price,
    //  state: State.ForSale,
    //  seller: msg.sender,
    //  buyer: address(0)
    //});
    //
    //skuCount = skuCount + 1;
    // emit LogForSale(skuCount);
    // return true;
  }

  // Implement this buyItem function.
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller,
  // 3. set the buyer as the person who called this transaction,
  // 4. set the state to Sold.
  // 5. this function should use 3 modifiers to check
  //    - if the item is for sale,
  //    - if the buyer paid enough,
  //    - check the value after the function is called to make
  //      sure the buyer is refunded any excess ether sent.
  // 6. call the event associated with this function!
  function buyItem(uint sku) public payable forSale(sku) paidEnough(sku) checkValue(sku)  {

      items[sku].buyer = payable(msg.sender);
      address payable seller = payable(items[sku].seller);
      address payable buyer = payable(items[sku].buyer);
      items[sku].state = State.Sold;
      seller.transfer(items[sku].price);
    /////  buyer.transfer(msg.value - items[sku].price); //called in checkValue
      //dbgPrice = msg.value - items[sku].price;
      emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already
  //    - the person calling this function is the seller.
  // 2. Change the state of the item to shipped.
  // 3. call the event associated with this function!
  function shipItem(uint sku) public sold(sku) verifyCaller(sku, State.Shipped) {
      items[sku].state = State.Shipped;
      emit LogShipped(sku);
  }

  // 1. Add modifiers to check
  //    - the item is shipped already
  //    - the person calling this function is the buyer.
  // 2. Change the state of the item to received.
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) verifyCaller(sku, State.Received){
      items[sku].state = State.Received;
      emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view
     returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
