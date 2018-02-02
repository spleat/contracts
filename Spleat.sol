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
        uint256 restaurantOrderId;
    }
    
    mapping (uint256 => Order) public orders;
    
    function openOrder(Restaurant restaurant, string deliveryAddress, string phone) public returns (uint256) {
        var id = uint256(block.blockhash(block.number - 1)) ^ uint256(keccak256(restaurant, deliveryAddress, phone));
        orders[id] = Order(msg.sender, restaurant, deliveryAddress, phone, new uint256[](0), new address[](0), 0, 0);
        return id;
    }
    
    function addItem(uint256 orderId, uint256 id) public payable checkPayment(orderId, id) {
        var o = orders[id];
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
    
    function removeItem(uint256 orderId, uint256 id) public onlyBuyer(orderId, id) {
        
    }
    
    modifier onlyBuyer(uint256 orderId, uint256 id) {
        
        _;
    }
    
    function makeOrder(uint256 id) public onlyOwner(id) {
        var o = orders[id];
        var restaurantOrderId = o.restaurant.order.value(o.payed)(o.deliveryAddress, o.phone, o.items);
        o.restaurantOrderId = restaurantOrderId;
    }
    
    modifier onlyOwner(uint256 id) {
        require(msg.sender == orders[id].owner);
        _;
    }
    
    function restaurantOrderStatus(uint256 id) public view returns (Restaurant.Status) {
        var o = orders[id];
        return o.restaurant.orderStatus(o.restaurantOrderId);
    }
}
