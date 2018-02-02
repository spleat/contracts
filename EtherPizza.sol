pragma solidity ^0.4.19;

contract Ownable {
    
    address owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Menu is Ownable {
    
    struct MenuItem {
        
        uint256 id;
        string description;
        uint256 price;
    }
    
    MenuItem[] public menu;
    mapping (uint256 => uint256) internal idToIndexMap;
    
    function Menu() public {
        menu.length++;
    }
    
    function addMenuItem(string description, uint256 price) public onlyOwner {
        var index = menu.length;
        var id = uint256(block.blockhash(block.number - 1)) ^ uint256(keccak256(index, description, price));
        assert(idToIndexMap[id] == 0);
        idToIndexMap[id] = index;
        menu.length++;
        menu[index] = MenuItem(id, description, price);
    }
    
    function removeMenuItem(uint256 id) public onlyOwner {
        var index = idToIndexMap[id];
        assert(index != 0);
        delete idToIndexMap[id];
        if (index != menu.length - 1) {
            var item = menu[menu.length - 1];
            idToIndexMap[item.id] = index;
            menu[index] = item;
        }
        menu.length--;
    }
    
    function menuLength() public view returns (uint256) {
        return menu.length - 1;
    }
    
    function menuItem(uint256 index) public view returns (uint256, string, uint256) {
        require(index < menuLength());
        var item = menu[index + 1];
        return (item.id, item.description, item.price);
    }
    
    function menuItemPrice(uint256 id) public view returns (uint256) {
        var index = idToIndexMap[id];
        assert(index != 0);
        return menu[index].price;
    }
    
    function wholeMenu() public view returns (uint256[], bytes32[], uint256[]) {
        var length = menuLength();
        uint256[] memory ids = new uint256[](length);
        bytes32[] memory descriptions = new bytes32[](length);
        uint256[] memory prices = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            var item = menu[i + 1];
            ids[i] = item.id;
            string memory strDesc = item.description;
            bytes32 bytesDesc;
            assembly {
                bytesDesc := mload(add(strDesc, 32))
            }
            descriptions[i] = bytesDesc;
            prices[i] = item.price;
        }
        return (ids, descriptions, prices);
    }
}

contract EtherPizza is Menu {
    
    enum Status {
        
        pending,
        preparing,
        delivering,
        delivered,
        rejected
    }
    
    event OrderStatusUpdate(uint256 indexed id, Status status);
    
    struct Order {
        
        string deliveryAddress;
        string phone;
        Status status;
        uint256[] items;
    }
    
    Order[] public orders;
    
    function order(
            string deliveryAddress,
            string phone,
            uint256[] items)
            
            public
            payable
            checkPayment(items)
            returns (uint256) {
        
        var id = orders.length;
        orders.length++;
        orders[id] = Order(deliveryAddress, phone, Status.pending, items);
        OrderStatusUpdate(id, Status.pending);
        return id;
    }
    
    modifier checkPayment(uint256[] items) {
        require(msg.value >= calculateCost(items));
        _;
    }
    
    function calculateCost(uint256[] items) public view returns (uint256) {
        uint256 cost = 0;
        for (uint256 i = 0; i < items.length; i++) {
            var index = idToIndexMap[items[i]];
            assert(index != 0);
            cost += menu[index].price;
        }
        return cost;
    }
    
    function updateStatus(uint256 id, Status status) public onlyOwner {
        require(id < orders.length);
        orders[id].status = status;
        OrderStatusUpdate(id, status);
    }
    
    function orderStatus(uint256 id) public view returns (Status) {
        return orders[id].status;
    }
    
    function collectLoot() public onlyOwner {
        msg.sender.transfer(this.balance);
    }
}
