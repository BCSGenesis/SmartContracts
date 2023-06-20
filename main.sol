// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Payment {

    address public owner;

    constructor(){
        owner=msg.sender;
    }

    //고객 구조체
    struct Customer {
        address  customerWallet;
        string customerAddress;
        Basket basket;
        Order goingOrder;
        mapping(uint=>Order) pastOrderList;
    }
    //가게 점주 입장 구조체
    struct Store_own {
        address  storeWallet;
        string storeName;
        string storeAddress;
        mapping(string=>Menu)menuList;
        mapping(uint=>Order)orderList;
    }


    //가게 고객 입장 구조체
    struct Store_cus {
        address  storeWallet;
        string storeName;
        string storeAddress;
        mapping(string=>Menu) menuList;
    }
    //배달원 구조체
    struct Rider {
        address  riderWallet;
        mapping(uint=>Order) orders;
    }
    //메뉴 구조체
    struct Menu {
        string name;
        uint price;
        uint count;
    }
    //장바구니 구조체체
    struct Basket {
        address customerAddr;
        address storeAddr;
        string customerAddress;
        string storeAddress;
        Menu[] menuNames;
        uint foodPrice;
        uint deliveryFee;
    }
    //주문 구조체
    struct Order {
        uint orderID;
        address customerAddr;
        address storeAddr;
        address riderAddr;
        string customerAddress;
        string storeAddress;
        mapping(string=>Menu) menuName;
        uint foodPrice;
        uint deliveryFee;
        uint deliveryTip;
        storeState storeStatus;
        riderState riderStatus;
    }
    //주문에 대한 가게 반응 상태
    enum storeState {decline, accept,cookFinish, isPicked,notyetChoice,checkMoney}
    //주문에 대한 배달원 반응 상태
    enum riderState {notSelected, inDelivery, isPicked, deliveryComplete,checkMoney}

    //고객들 저장된 맵핑
    mapping(address => Customer) customers;
    //가게들 저장된 배열(고객이 쇼핑하는 입장)
    Store_cus[] stores_customer;
    //가게들 저장된 배열(가게주인 관리하는 입장)
    mapping(address=>Store_own) stores_owner;
    //배달원들 저장된 맵핑
    mapping(address => Rider) riders;
    //배달대기목록
    Order[] deliveryWaitingList;

    //주문고유번호
    uint public orderNum;

    //가게------------------------------------------------------------------------------------------------

    //가게 등록 기능
    function storeRegist(string memory _storeName,string memory _storeAddress) public {
        //stores_customer 배열에 가게 추가하기
        Store_cus storage newStore_cus = stores_customer.push();
        newStore_cus.storeWallet=msg.sender;
        newStore_cus.storeName=_storeName;
        newStore_cus.storeAddress=_storeAddress;

        //stores_owner 맵핑에 가게 추가하기
        Store_own storage newStore_own=stores_owner[msg.sender];
        newStore_own.storeWallet= msg.sender;
        newStore_own.storeName=_storeName;
        newStore_own.storeAddress=_storeAddress;

    }
    /*
    function get1(uint _n)public view returns(string memory){
        return stores_customer[_n].storeName;
    }
    function get2(address _a)public view returns(string memory){
        return stores_owner[_a].storeName;
    }
    */


    //가게 메뉴 등록 기능
    function storeMenuRegist(string memory _menuName,uint _price)public{
        //stores_customer 배열의 Menu[]에 메뉴 추가하기
        for(uint i=0;i<stores_customer.length;i++){
            if(stores_customer[i].storeWallet==msg.sender){
                stores_customer[i].menuList[_menuName]=Menu(_menuName,_price,0);
            }
        }
        //stores_owner 매핑의 Menu[]에 메뉴 추가하기
        stores_owner[msg.sender].menuList[_menuName]=Menu(_menuName,_price,0);
    }
    /*
    function get3(uint _n,string memory _menuName)public view returns(Menu memory){
        return stores_customer[_n].menuList[_menuName];
    }
    function get4(address _a,string memory _menuName)public view returns(Menu memory){
        return stores_owner[_a].menuList[_menuName];
    }
    */

    //가게의 주문 수락
    function storeAccept(uint _orderId) public {
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_orderId].customerAddr].goingOrder.storeStatus=storeState.accept;
        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_orderId].storeStatus=storeState.accept;
    }

    //가게의 주문 거절
    function storeDecline(uint _orderId) public {
        //고객의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_orderId].customerAddr].goingOrder.storeStatus=storeState.decline;

        //가게(stores_owner)의 order상태 변경
        stores_owner[msg.sender].orderList[_orderId].storeStatus=storeState.decline;

        //배달대기리스트에서 주문건 삭제
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                delete deliveryWaitingList[i];
            }
        }
        //가게 매핑에서 지우기
        delete stores_owner[msg.sender].orderList[_orderId];
        
    }

    //가게의 요리 완료
    function cookFinish(uint _orderId)public {
        //가게(stores_owner)의 order상태 변경
        customers[stores_owner[msg.sender].orderList[_orderId].customerAddr].goingOrder.storeStatus=storeState.cookFinish;

        //고객의 order상태 변경
        stores_owner[msg.sender].orderList[_orderId].storeStatus=storeState.cookFinish;

    }


    //고객--------------------------------------------------------------------------------------------



    //고객 등록 기능
    function customerRegist(string memory _customerAddress) public {
        Customer storage newCustomer=customers[msg.sender];
        newCustomer.customerWallet=msg.sender;
        newCustomer.customerAddress=_customerAddress;

    }
    /*
    function getCustomer(address _a)public view returns (string memory){
        return customers[_a].customerAddress;
    }
    */

    //장바구니에 메뉴 담기
    function addMenuToBusket(address _storeAddr,string memory _foodName,uint _count)public {
        customers[msg.sender].basket.customerAddr=msg.sender;
        customers[msg.sender].basket.storeAddr=_storeAddr;
        customers[msg.sender].basket.customerAddress=customers[msg.sender].customerAddress;
        for(uint i=0;i<stores_customer.length;i++){
            if(stores_customer[i].storeWallet == _storeAddr){
                customers[msg.sender].basket.storeAddress = stores_customer[i].storeAddress;
                customers[msg.sender].basket.menuNames.push(Menu(stores_customer[i].menuList[_foodName].name,stores_customer[i].menuList[_foodName].price,_count));
            }
        }       
        customers[msg.sender].basket.foodPrice=menuTotalPriceForBasket();
        customers[msg.sender].basket.deliveryFee=0;
    }

    //메뉴 총 가격 계산하기
    function menuTotalPriceForBasket()public view returns(uint){
        uint totalPrice;
        uint menuLength = customers[msg.sender].basket.menuNames.length;
        for (uint i = 0; i < menuLength; i++) {
            totalPrice += customers[msg.sender].basket.menuNames[i].price*customers[msg.sender].basket.menuNames[i].count;
        }
        return totalPrice;
    }

    // function getBasketMenu(uint _n)public view returns(Menu memory){
    //     return customers[msg.sender].basket.menuNames[_n];
    // }

    //주문하기
    function ordering(uint _deliveryTip) public {
        //고객정보에 주문 추가
        orderNum++;
        Order storage newOrder = customers[msg.sender].goingOrder;
        newOrder.orderID= orderNum;
        newOrder.customerAddr=msg.sender;
        newOrder.storeAddr=customers[msg.sender].basket.storeAddr;
        newOrder.customerAddress=customers[msg.sender].basket.customerAddress;
        newOrder.storeAddress=customers[msg.sender].basket.storeAddress;
        for(uint i=0;i<customers[msg.sender].basket.menuNames.length;i++){
            newOrder.menuName[customers[msg.sender].basket.menuNames[i].name]=customers[msg.sender].basket.menuNames[i];
        }
        newOrder.foodPrice=menuTotalPriceForBasket();
        newOrder.deliveryFee=0;
        newOrder.deliveryTip=_deliveryTip;
        newOrder.storeStatus=storeState.notyetChoice;
        newOrder.riderStatus=riderState.notSelected; 
        //가게(가게맵핑)에 주문 추가
        Order storage newOrder2 = stores_owner[customers[msg.sender].basket.storeAddr].orderList[newOrder.orderID];
        newOrder2.orderID= orderNum;
        newOrder2.customerAddr=msg.sender;
        newOrder2.storeAddr=customers[msg.sender].basket.storeAddr;
        newOrder2.customerAddress=customers[msg.sender].basket.customerAddress;
        newOrder2.storeAddress=customers[msg.sender].basket.storeAddress;
        for(uint i=0;i<customers[msg.sender].basket.menuNames.length;i++){
            newOrder2.menuName[customers[msg.sender].basket.menuNames[i].name]=customers[msg.sender].basket.menuNames[i];
        }
        newOrder2.foodPrice=menuTotalPriceForBasket();
        newOrder2.deliveryFee=0;
        newOrder2.deliveryTip=_deliveryTip;
        newOrder2.storeStatus=storeState.notyetChoice;
        newOrder2.riderStatus=riderState.notSelected;
        //배달 목록에 등록
        Order storage newOrder3 = deliveryWaitingList.push();
        newOrder3.orderID= orderNum;
        newOrder3.customerAddr=msg.sender;
        newOrder3.storeAddr=customers[msg.sender].basket.storeAddr;
        newOrder3.customerAddress=customers[msg.sender].basket.customerAddress;
        newOrder3.storeAddress=customers[msg.sender].basket.storeAddress;
        for(uint i=0;i<customers[msg.sender].basket.menuNames.length;i++){
            newOrder.menuName[customers[msg.sender].basket.menuNames[i].name]=customers[msg.sender].basket.menuNames[i];
        }
        newOrder3.foodPrice=menuTotalPriceForBasket();
        newOrder3.deliveryFee=0;
        newOrder3.deliveryTip=_deliveryTip;
        newOrder3.storeStatus=storeState.notyetChoice;
        newOrder3.riderStatus=riderState.notSelected; 
    }


    // function getdelivery(uint _n)public view returns(uint,address){
    //     return (deliveryWaitingList[_n].orderID,deliveryWaitingList[_n].riderAddr);
    // }
    // function getOrderingCusOrder()public view returns (uint,uint ){
    //     return (customers[msg.sender].goingOrder.orderID,customers[msg.sender].goingOrder.foodPrice);
    // }
    // function getOrderingStoreOrder(uint _n)public view returns (uint,uint ){
    //     return (stores_owner[msg.sender].orderList[_n].orderID,stores_owner[msg.sender].orderList[_n].foodPrice);
    // }
    // function getOrderingDelOrder(uint _n)public view returns (uint,uint ){
    //     return (deliveryWaitingList[_n].orderID,deliveryWaitingList[_n].foodPrice);
    // }

    //주문건 조건이 맞을경우, 컨트랙트에 돈 지불
    function payment()public payable {
        //고객 주문건이 가게는수락, 라이더는 배달하기로 선택한 상태
        require(customers[msg.sender].goingOrder.storeStatus==storeState.accept &&
                customers[msg.sender].goingOrder.riderStatus==riderState.isPicked);
        //컨트랙트에 가격지불
        require(
            msg.value==(customers[msg.sender].goingOrder.foodPrice+
            customers[msg.sender].goingOrder.deliveryFee+
            customers[msg.sender].goingOrder.deliveryTip)*1 ether
            );
        //가게(stores_owner)의 order상태 변경
        stores_owner[customers[msg.sender].goingOrder.storeAddr].orderList[customers[msg.sender].goingOrder.orderID].storeStatus=storeState.checkMoney;
        //배달조회목록주문건의 상태변경
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].customerAddr==msg.sender){
                deliveryWaitingList[i].storeStatus=storeState.checkMoney;     
            }
        }        
        //고객의 order상태 변경
        customers[msg.sender].goingOrder.storeStatus==storeState.checkMoney;
        //배달원 주문건의 상태 변경
        riders[customers[msg.sender].goingOrder.riderAddr].orders[customers[msg.sender].goingOrder.orderID].riderStatus = riderState.checkMoney;
/*
struct Basket {
        address customerAddr;
        address storeAddr;
        string customerAddress;
        string storeAddress;
        Menu[] menuNames;
        uint foodPrice;
        uint deliveryFee;
    }
*/
        // //고객의 basket초기화
        // customers[msg.sender].basket.customerAddr=address(0);
        // customers[msg.sender].basket.storeAddr=address(0);
        // customers[msg.sender].basket.customerAddress="";
        // customers[msg.sender].basket.storeAddress="";
        // for(uint i=0;i<customers[msg.sender].basket.menuNames.length;i++){
        //     customers[msg.sender].basket.menuNames.pop();
        //     customers[msg.sender].basket.menuNames.pop();
        // }
        // customers[msg.sender].basket.foodPrice=0;
        // customers[msg.sender].basket.deliveryFee=0;
    }



    //라이더---------------------------------------------------------------------------------------------
    /*
    function customerRegist(string memory _customerAddress) public {
        Customer storage newCustomer=customers[msg.sender];
        newCustomer.customerWallet=msg.sender;
        newCustomer.customerAddress=_customerAddress;

    }
    struct Rider {
        address  riderWallet;
        mapping(address=>Order) orders;
    }
    mapping(address => Rider) riders;
    */
    //라이더 등록 기능
    function riderRegist() public{       
        Rider storage newRider = riders[msg.sender];
        newRider.riderWallet = msg.sender;

    }

    

    //라이더의 배달 선택
    function riderPickOrder(uint _orderId)public {
        //라이더의 배달목록에 추가
        
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){

                //고객 주문건에 라이더 등록
                customers[deliveryWaitingList[i].customerAddr].goingOrder.riderAddr = msg.sender;
                //가게 주문건에 라이더 등록
                stores_owner[deliveryWaitingList[i].storeAddr].orderList[_orderId].riderAddr = msg.sender;
                //배달달 주문건에 라이더 등록
                deliveryWaitingList[i].riderAddr = msg.sender;

                // //주문건의 배달상태 '선택'
                // deliveryWaitingList[i].riderStatus=riderState.selected;
                // //고객의 order상태 변경
                // customers[deliveryWaitingList[i].customerAddr].goingOrder.riderStatus = riderState.selected;
                // //가게(stores_owner)의 order상태 변경
                // stores_owner[deliveryWaitingList[i].storeAddr].orderList[_orderId].riderStatus= riderState.selected;
            }
        }
        //주문건의 배달상태 '선택'
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].riderAddr==msg.sender){
                Order storage newOrder = riders[msg.sender].orders[_orderId];
                newOrder.orderID= _orderId;
                newOrder.customerAddr=deliveryWaitingList[i].customerAddr;
                newOrder.storeAddr=deliveryWaitingList[i].storeAddr;
                newOrder.customerAddress=deliveryWaitingList[i].customerAddress;
                newOrder.storeAddress=deliveryWaitingList[i].storeAddress;
                for(uint j=0;j<customers[deliveryWaitingList[i].customerAddr].basket.menuNames.length;j++){
                    newOrder.menuName[customers[deliveryWaitingList[i].customerAddr].basket.menuNames[i].name]=customers[deliveryWaitingList[i].customerAddr].basket.menuNames[i];
                }
                newOrder.foodPrice=deliveryWaitingList[i].foodPrice;
                newOrder.deliveryFee=deliveryWaitingList[i].deliveryFee;
                newOrder.deliveryTip=deliveryWaitingList[i].deliveryTip;
                newOrder.storeStatus=deliveryWaitingList[i].storeStatus;
                newOrder.riderStatus=deliveryWaitingList[i].riderStatus;
                //배달 대기목록의 주문건 상태 수정
                deliveryWaitingList[i].storeStatus=storeState.isPicked;
                deliveryWaitingList[i].storeStatus=storeState.isPicked;
                
                //고객의 주문건 상태 수정
                customers[deliveryWaitingList[i].customerAddr].goingOrder.storeStatus=storeState.isPicked;
                customers[deliveryWaitingList[i].customerAddr].goingOrder.riderStatus=riderState.isPicked;
                //가게의 주문건 상태 수정
                stores_owner[deliveryWaitingList[i].storeAddr].orderList[_orderId].storeStatus=storeState.isPicked;
                stores_owner[deliveryWaitingList[i].storeAddr].orderList[_orderId].riderStatus=riderState.isPicked;
                  
            }
        } 
    }
/*
//주문에 대한 가게 반응 상태
    enum storeState {decline, accept,cookFinish, isPicked,notyetChoice,checkMoney}
    //주문에 대한 배달원 반응 상태
    enum riderState {notSelected, inDelivery, isPicked, deliveryComplete}
*/
    //배달 시작 기능
    function riderStartDelivery(uint _orderId)public {
        //돈 받아야 배달 출발조건건
        require(riders[msg.sender].orders[_orderId].riderStatus==riderState.checkMoney);
        //배달 상태 진행중으로로
        riders[msg.sender].orders[_orderId].riderStatus=riderState.inDelivery;
        //배달 대기목록의 배달 상태 진행중으로로
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                deliveryWaitingList[i].riderStatus=riderState.inDelivery;
            }
        }
        
    }
    //배달 완료 기능
    function riderFinishDelivery(uint _orderId)public {
        require(riders[msg.sender].orders[_orderId].riderStatus==riderState.inDelivery);
        riders[msg.sender].orders[_orderId].riderStatus=riderState.deliveryComplete;

        //배달 대기목록의 배달 상태 완료로
        for(uint i=0;i<deliveryWaitingList.length;i++){
            if(deliveryWaitingList[i].orderID==_orderId){
                deliveryWaitingList[i].riderStatus=riderState.inDelivery;
            }
        }
        //고객의 배달 과거목록에 추가
        
        Order storage pastOrder = customers[riders[msg.sender].orders[_orderId].customerAddr].pastOrderList[_orderId];
        
        pastOrder.orderID= customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.orderID;
        pastOrder.customerAddr=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.customerAddr;
        pastOrder.storeAddr=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.storeAddr;
        pastOrder.customerAddress=customers[riders[msg.sender].orders[_orderId].customerAddr].basket.customerAddress;
        pastOrder.storeAddress=customers[riders[msg.sender].orders[_orderId].customerAddr].basket.storeAddress;
        for(uint i=0;i<customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames.length;i++){
            pastOrder.menuName[customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames[i].name]=customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames[i];
        }
        pastOrder.foodPrice=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.foodPrice;
        pastOrder.deliveryFee=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.deliveryFee;
        pastOrder.deliveryTip=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.deliveryTip;
        pastOrder.storeStatus=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.storeStatus;
        pastOrder.riderStatus=customers[riders[msg.sender].orders[_orderId].customerAddr].goingOrder.riderStatus; 
        
        //고객의 goingOrder초기화
        

        customers[msg.sender].goingOrder.orderID= orderNum;
        customers[msg.sender].goingOrder.customerAddr=msg.sender;
        customers[msg.sender].goingOrder.storeAddr=customers[msg.sender].basket.storeAddr;
        customers[msg.sender].goingOrder.customerAddress=customers[msg.sender].basket.customerAddress;
        customers[msg.sender].goingOrder.storeAddress=customers[msg.sender].basket.storeAddress;
        for(uint i=0;i<customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames.length;i++){
            delete customers[msg.sender].goingOrder.menuName[customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames[0].name];
        }        
        customers[msg.sender].goingOrder.foodPrice=menuTotalPriceForBasket();
        customers[msg.sender].goingOrder.deliveryFee=0;
        customers[msg.sender].goingOrder.deliveryTip=0;
        customers[msg.sender].goingOrder.storeStatus=storeState.notyetChoice;
        customers[msg.sender].goingOrder.riderStatus=riderState.notSelected; 
        

        //고객의 basket초기화
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.customerAddr=address(0);
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.storeAddr=address(0);
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.customerAddress="";
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.storeAddress="";
        for(uint i=0;i<customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames.length;i++){
            customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames.pop();
            customers[riders[msg.sender].orders[_orderId].customerAddr].basket.menuNames.pop();
        }
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.foodPrice=0;
        customers[riders[msg.sender].orders[_orderId].customerAddr].basket.deliveryFee=0;

    }

    // function getRiderMyOrder(uint _orderId)public view returns(address){
    //         return riders[msg.sender].orders[_orderId].customerAddr;
    //     }   
    /*
    function getStoreState()public view returns(storeState){
        return customers[msg.sender].goingOrder.storeStatus;
    }
    function getRiderState()public view returns(riderState){
        return customers[msg.sender].goingOrder.riderStatus;
    }
    function getFoodPrice()public view returns(uint){
        return customers[msg.sender].goingOrder.foodPrice;
    }
    function getDeliveryFee()public view returns(uint){
        return customers[msg.sender].goingOrder.deliveryFee;
    }
    function getDeliveryTip()public view returns(uint){
        return customers[msg.sender].goingOrder.deliveryTip;
    }
    */

    //관리자---------------------------------------------------------------------------------------------

    function withdraw(uint _amount)public {
        require(msg.sender == owner);
        payable (msg.sender).transfer(_amount * 1 ether);
    }

}