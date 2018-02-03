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
        uint256[] itemPayment;
        uint256 paid;
        bool ordered;
        uint256 restaurantOrderId;
    }
    
    mapping (uint256 => Order) public orders;
    
    function orderById(uint256 orderId) public view returns (uint256[], address[], bool, address) {
        var o = orders[orderId];
        return (o.items, o.buyers, o.ordered, o.owner);
    }
    
    event OrderOpened(uint256 indexed orderId);
    
    function openOrder(Restaurant restaurant, string deliveryAddress, string phone) public returns (uint256) {
        var orderId = uint256(block.blockhash(block.number - 1)) ^ uint256(keccak256(restaurant, deliveryAddress, phone));
        orders[orderId] = Order(msg.sender, restaurant, deliveryAddress, phone, new uint256[](0), new address[](0), new uint256[](0), 0, false, 0);
        OrderOpened(orderId);
        return orderId;
    }
    
    function addItem(uint256 orderId, uint256 id) public payable checkPayment(orderId, id) notOrdered(orderId) {
        var o = orders[orderId];
        o.items.length++;
        o.items[o.items.length - 1] = id;
        o.buyers.length++;
        o.buyers[o.buyers.length - 1] = msg.sender;
        o.itemPayment.length++;
        o.itemPayment[o.itemPayment.length - 1] = msg.value;
        o.paid += msg.value;
    }
    
    modifier checkPayment(uint256 orderId, uint256 id) {
        require(msg.value >= orders[orderId].restaurant.menuItemPrice(id));
        _;
    }
    
    function removeItem(uint256 orderId, uint256 id) public onlyBuyer(orderId, id) notOrdered(orderId) {
        var o = orders[orderId];
        for (uint256 i = 0; i < o.items.length; i++) {
            if (o.items[i] == id && o.buyers[i] == msg.sender) {
                o.paid -= o.itemPayment[i];
                msg.sender.transfer(o.itemPayment[i]);
                if (i != o.items.length - 1) {
                    o.items[i] = o.items[o.items.length - 1];
                    o.buyers[i] = o.buyers[o.buyers.length - 1];
                    o.itemPayment[i] = o.itemPayment[o.itemPayment.length - 1];
                }
                o.items.length--;
                o.buyers.length--;
                o.itemPayment.length--;
                break;
            }
        }
    }
    
    modifier onlyBuyer(uint256 orderId, uint256 id) {
        var o = orders[orderId];
        var everythingGood = false;
        for (uint256 i = 0; i < o.items.length; i++) {
            if (o.items[i] == id && o.buyers[i] == msg.sender) {
                everythingGood = true;
                break;
            }
        }
        require(everythingGood);
        _;
    }
    
    function makeOrder(uint256 orderId) public onlyOwner(orderId) notOrdered(orderId) {
        var o = orders[orderId];
        var restaurantOrderId = o.restaurant.order.value(o.paid)(o.deliveryAddress, o.phone, o.items);
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
    
    function orderItems(uint256 orderId) public view returns (uint256[]) {
        var o = orders[orderId];
        return o.items;
    }
    
    function orderBuyers(uint256 orderId) public view returns (address[]) {
        var o = orders[orderId];
        return o.buyers;
    }
    
    function restaurantOrderStatus(uint256 orderId) public view returns (Restaurant.Status) {
        var o = orders[orderId];
        return o.restaurant.orderStatus(o.restaurantOrderId);
    }
}
