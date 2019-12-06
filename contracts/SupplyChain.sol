pragma solidity >=0.4.21 <0.6.0;

contract SupplyChain {

    address public owner;

    uint public skuCount;

    mapping (uint => Item) items;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        uint state;
        address payable seller;
        address payable buyer;
    }
    
    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

    modifier checkOwner () { 
      require (owner == msg.sender, "you are not owner");
      _;
    }
    modifier verifyCaller (address _address) {
        require (msg.sender == _address, "verify caller!");
        _;
    }
    modifier paidEnough(uint _price){ 
        require(msg.value >= _price, "paid not enough");
        _;
    }

    modifier checkValue(uint _sku) {
        _;
        items[_sku].buyer.transfer(msg.value - items[_sku].price);

    }
    modifier forSale(uint _sku) {
        require(items[_sku].state == uint(State.ForSale), "it is not for sale");
        _;
    }
    
    modifier sold(uint _sku){
        require(items[_sku].state == uint(State.Sold));
        _;   
    }
    modifier shipped(uint _sku){
        require(items[_sku].state == uint(State.Shipped));
        _; 
    }
    modifier received(uint _sku){
        require(items[_sku].state == uint(State.Received));
        _;   
    }

    constructor() public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint _price) public returns(bool){
      emit LogForSale(skuCount);
      items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: uint(State.ForSale), seller: msg.sender, buyer: address(0)});
      skuCount = skuCount + 1;
      return true;
    }

    function buyItem(uint _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku){
      items[_sku].buyer = msg.sender;
      items[_sku].state = uint(State.Sold);
      items[_sku].seller.transfer(items[_sku].price);
      emit LogSold(items[_sku].sku);
    }

    function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
        items[sku].state = uint(State.Shipped);
        emit LogShipped(items[sku].sku);
    }

    function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer){
        items[sku].state = uint(State.Received);
        emit LogReceived(items[sku].sku);
    }

    function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
      name = items[_sku].name;
      sku = items[_sku].sku;
      price = items[_sku].price;
      state = uint(items[_sku].state);
      seller = items[_sku].seller;
      buyer = items[_sku].buyer;
      return (name, sku, price, state, seller, buyer);
    }

}
