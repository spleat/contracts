pragma solidity ^0.4.19;

contract Restaurant {
    
    enum Status {
        
        pending,
        preparing,
        delivering,
        delivered,
        rejected
    }
    
    function menuItemPrice(uint256 id) public view returns (uint256);
    
    function order(string deliveryAddress, string phone, uint256[] items) public payable returns (uint256);
    
    function orderStatus(uint256 id) public view returns (Status);
}

contract Spleat {
    
    struct Order {
        
        address owner;
        Restaurant restaurant;
        string deliveryAddress;
        string phone;
        uint256[] items;
        address[] buyers;
        uint256 payed;
        bool ordered;
        uint256 restaurantOrderId;
    }
    
    mapping (uint256 => Order) public orders;
    
    event OrderOpened(uint256 indexed orderId);
    
    function openOrder(Restaurant restaurant, string deliveryAddress, string phone) public returns (uint256) {
        var orderId = uint256(block.blockhash(block.number - 1)) ^ uint256(keccak256(restaurant, deliveryAddress, phone));
        orders[orderId] = Order(msg.sender, restaurant, deliveryAddress, phone, new uint256[](0), new address[](0), 0, false, 0);
        OrderOpened(orderId);
        return orderId;
    }
    
    function addItem(uint256 orderId, uint256 id) public payable checkPayment(orderId, id) notOrdered(orderId) {
        var o = orders[orderId];
        o.items.length++;
        o.items[o.items.length - 1] = id;
        o.buyers.length++;
        o.buyers[o.buyers.length - 1] = msg.sender;
        o.payed += msg.value;
    }
    
    modifier checkPayment(uint256 orderId, uint256 id) {
        require(msg.value >= orders[orderId].restaurant.menuItemPrice(id));
        _;
    }
    
    function removeItem(uint256 orderId, uint256 id) public onlyBuyer(orderId, id) notOrdered(orderId) {
        
    }
    
    modifier onlyBuyer(uint256 orderId, uint256 id) {
        
        _;
    }
    
    function makeOrder(uint256 orderId) public onlyOwner(orderId) notOrdered(orderId) {
        var o = orders[orderId];
        var restaurantOrderId = o.restaurant.order.value(o.payed)(o.deliveryAddress, o.phone, o.items);
        o.restaurantOrderId = restaurantOrderId;
        o.ordered = true;
    }
    
    modifier onlyOwner(uint256 orderId) {
        require(msg.sender == orders[orderId].owner);
        _;
    }
    
    modifier notOrdered(uint256 orderId) {
        require(!orders[orderId].ordered);
        _;
    }
    
    function restaurantOrderStatus(uint256 orderId) public view returns (Restaurant.Status) {
        var o = orders[orderId];
        return o.restaurant.orderStatus(o.restaurantOrderId);
    }
}
