// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseOrderTest } from "../utils/BaseOrderTest.sol";
import {
    ConsiderationItem,
    OfferItem,
    ItemType,
    OrderType,
    AdvancedOrder,
    Order,
    CriteriaResolver,
    BasicOrderParameters,
    AdditionalRecipient,
    FulfillmentComponent,
    Fulfillment,
    OrderComponents,
    OrderParameters
} from "../../../contracts/lib/ConsiderationStructs.sol";
import {
    ConsiderationInterface
} from "../../../contracts/interfaces/ConsiderationInterface.sol";
import {
    FulfillmentLib,
    FulfillmentComponentLib,
    OrderParametersLib,
    OrderComponentsLib,
    OrderLib,
    OfferItemLib,
    ConsiderationItemLib,
    SeaportArrays
} from "../../../contracts/helpers/sol/lib/SeaportStructLib.sol";
import {
    TestTransferValidationZoneOfferer
} from "../../../contracts/test/TestTransferValidationZoneOfferer.sol";

contract TestTransferValidationZoneOffererTest is BaseOrderTest {
    using FulfillmentLib for Fulfillment;
    using FulfillmentComponentLib for FulfillmentComponent;
    using FulfillmentComponentLib for FulfillmentComponent[];
    using OfferItemLib for OfferItem;
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem;
    using ConsiderationItemLib for ConsiderationItem[];
    using OrderComponentsLib for OrderComponents;
    using OrderParametersLib for OrderParameters;
    using OrderLib for Order;
    using OrderLib for Order[];

    TestTransferValidationZoneOfferer zone;

    // constant strings for recalling struct lib "defaults"
    // ideally these live in a base test class
    string constant ONE_ETH = "one eth";
    string constant THREE_ERC20 = "three erc20";
    string constant SINGLE_721 = "single 721";
    string constant VALIDATION_ZONE = "validation zone";
    string constant FIRST_FIRST = "first first";
    string constant SECOND_FIRST = "second first";
    string constant FIRST_SECOND = "first second";
    string constant SECOND_SECOND = "second second";
    string constant FIRST_SECOND__FIRST = "first&second first";
    string constant FIRST_SECOND__SECOND = "first&second second";

    function setUp() public virtual override {
        super.setUp();
        zone = new TestTransferValidationZoneOfferer(address(0));

        // create a default considerationItem for one ether;
        // note that it does not have recipient set
        ConsiderationItemLib
        .empty()
        .withItemType(ItemType.NATIVE)
        .withToken(address(0)) // not strictly necessary
            .withStartAmount(1 ether)
            .withEndAmount(1 ether)
            .withIdentifierOrCriteria(0)
            .saveDefault(ONE_ETH); // not strictly necessary

        // create a default considerationItem for three erc20;
        // note that it does not have recipient set
        ConsiderationItemLib
            .empty()
            .withItemType(ItemType.ERC20)
            .withStartAmount(3 ether)
            .withEndAmount(3 ether)
            .withIdentifierOrCriteria(0)
            .saveDefault(THREE_ERC20); // not strictly necessary

        // create a default offerItem for a single 721;
        // note that it does not have token or identifier set
        OfferItemLib
            .empty()
            .withItemType(ItemType.ERC721)
            .withStartAmount(1)
            .withEndAmount(1)
            .saveDefault(SINGLE_721);

        OrderComponentsLib
        .empty()
        .withOfferer(offerer1.addr)
        .withZone(address(zone))
        // fill in offer later
        // fill in consideration later
        .withOrderType(OrderType.FULL_RESTRICTED)
        .withStartTime(block.timestamp)
        .withEndTime(block.timestamp + 1)
        .withZoneHash(bytes32(0)) // not strictly necessary
            .withSalt(0)
            .withConduitKey(conduitKeyOne)
            .saveDefault(VALIDATION_ZONE); // not strictly necessary
        // fill in counter later

        // create a default fulfillmentComponent for first_first
        // corresponds to first offer or consideration item in the first order
        FulfillmentComponent memory firstFirst = FulfillmentComponentLib
            .empty()
            .withOrderIndex(0)
            .withItemIndex(0)
            .saveDefault(FIRST_FIRST);
        // create a default fulfillmentComponent for second_first
        // corresponds to first offer or consideration item in the second order
        FulfillmentComponent memory secondFirst = FulfillmentComponentLib
            .empty()
            .withOrderIndex(1)
            .withItemIndex(0)
            .saveDefault(SECOND_FIRST);
        // create a default fulfillmentComponent for first_first
        // corresponds to first offer or consideration item in the first order
        FulfillmentComponent memory firstSecond = FulfillmentComponentLib
            .empty()
            .withOrderIndex(0)
            .withItemIndex(1)
            .saveDefault(FIRST_SECOND);
        // create a default fulfillmentComponent for second_first
        // corresponds to first offer or consideration item in the second order
        FulfillmentComponent memory secondSecond = FulfillmentComponentLib
            .empty()
            .withOrderIndex(1)
            .withItemIndex(1)
            .saveDefault(SECOND_SECOND);

        // create a one-element array comtaining first_first
        SeaportArrays.FulfillmentComponents(firstFirst).saveDefaultMany(
            FIRST_FIRST
        );
        // create a one-element array comtaining second_first
        SeaportArrays.FulfillmentComponents(secondFirst).saveDefaultMany(
            SECOND_FIRST
        );

        // create a two-element array comtaining first_first and second_first
        SeaportArrays
            .FulfillmentComponents(firstFirst, secondFirst)
            .saveDefaultMany(FIRST_SECOND__FIRST);

        // create a two-element array comtaining first_second and second_second
        SeaportArrays
            .FulfillmentComponents(firstSecond, secondSecond)
            .saveDefaultMany(FIRST_SECOND__SECOND);
    }

    struct Context {
        ConsiderationInterface seaport;
    }

    function test(
        function(Context memory) external fn,
        Context memory context
    ) internal {
        try fn(context) {
            fail("Expected revert");
        } catch (bytes memory reason) {
            assertPass(reason);
        }
    }

    function testExecFulfillAvailableAdvancedOrdersWithConduitAndNative()
        public
    {
        prepareFulfillAvailableAdvancedOrdersWithConduitAndNative();
        test(
            this.execFulfillAvailableAdvancedOrdersWithConduitAndNative,
            Context({ seaport: consideration })
        );
        test(
            this.execFulfillAvailableAdvancedOrdersWithConduitAndNative,
            Context({ seaport: referenceConsideration })
        );
    }

    function prepareFulfillAvailableAdvancedOrdersWithConduitAndNative()
        internal
    {
        test721_1.mint(offerer1.addr, 42);
        test721_1.mint(offerer1.addr, 43);
    }

    function execFulfillAvailableAdvancedOrdersWithConduitAndNative(
        Context memory context
    ) external stateless {
        // Set up an NFT recipient.
        address considerationRecipientAddress = makeAddr(
            "considerationRecipientAddress"
        );

        // This instance of the zone expects the fulfiller to be the recipient
        // recipient of all spent items.
        TestTransferValidationZoneOfferer transferValidationZone = new TestTransferValidationZoneOfferer(
                address(0)
            );

        // Set up variables we'll use below the following block.
        OrderComponents memory orderComponentsOne;
        OrderComponents memory orderComponentsTwo;
        AdvancedOrder[] memory advancedOrders;

        // Create a block to deal with stack depth issues.
        {
            // Create the offer items for the first order.
            OfferItem[] memory offerItemsOne = SeaportArrays.OfferItems(
                OfferItemLib
                    .fromDefault(SINGLE_721)
                    .withToken(address(test721_1))
                    .withIdentifierOrCriteria(42)
            );

            // Create the consideration items for the first order.
            ConsiderationItem[] memory considerationItemsOne = SeaportArrays
                .ConsiderationItems(
                    ConsiderationItemLib.fromDefault(ONE_ETH).withRecipient(
                        considerationRecipientAddress
                    ),
                    ConsiderationItemLib
                        .fromDefault(THREE_ERC20)
                        .withToken(address(token1))
                        .withRecipient(considerationRecipientAddress)
                );

            // Create the order components for the first order.
            orderComponentsOne = OrderComponentsLib
                .fromDefault(VALIDATION_ZONE)
                .withOffer(offerItemsOne)
                .withConsideration(considerationItemsOne)
                .withZone(address(transferValidationZone));

            // Create the offer items for the second order.
            OfferItem[] memory offerItemsTwo = SeaportArrays.OfferItems(
                OfferItemLib
                    .fromDefault(SINGLE_721)
                    .withToken(address(test721_1))
                    .withIdentifierOrCriteria(43)
            );

            // Create the order components for the second order.
            orderComponentsTwo = OrderComponentsLib
                .fromDefault(VALIDATION_ZONE)
                .withOffer(offerItemsTwo)
                .withConsideration(considerationItemsOne)
                .withZone(address(transferValidationZone));

            // Create the orders.
            Order[] memory orders = _buildOrders(
                context,
                SeaportArrays.OrderComponentsArray(
                    orderComponentsOne,
                    orderComponentsTwo
                ),
                offerer1.key
            );

            // Convert the orders to advanced orders.
            advancedOrders = SeaportArrays.AdvancedOrders(
                orders[0].toAdvancedOrder(1, 1, ""),
                orders[1].toAdvancedOrder(1, 1, "")
            );
        }

        // Create the fulfillments for the offers.
        FulfillmentComponent[][] memory offerFulfillments = SeaportArrays
            .FulfillmentComponentArrays(
                SeaportArrays.FulfillmentComponents(
                    FulfillmentComponentLib.fromDefault(FIRST_FIRST)
                ),
                SeaportArrays.FulfillmentComponents(
                    FulfillmentComponentLib.fromDefault(SECOND_FIRST)
                )
            );

        // Create the fulfillments for the considerations.
        FulfillmentComponent[][]
            memory considerationFulfillments = SeaportArrays
                .FulfillmentComponentArrays(
                    FulfillmentComponentLib.fromDefaultMany(
                        FIRST_SECOND__FIRST
                    ),
                    FulfillmentComponentLib.fromDefaultMany(
                        FIRST_SECOND__SECOND
                    )
                );

        // Create the empty criteria resolvers.
        CriteriaResolver[] memory criteriaResolvers;

        // Make the call to Seaport.
        context.seaport.fulfillAvailableAdvancedOrders{ value: 3 ether }({
            advancedOrders: advancedOrders,
            criteriaResolvers: criteriaResolvers,
            offerFulfillments: offerFulfillments,
            considerationFulfillments: considerationFulfillments,
            fulfillerConduitKey: bytes32(conduitKeyOne),
            recipient: address(0),
            maximumFulfilled: 2
        });
    }

    function testAggregate() public {
        prepareAggregate();

        test(this.execAggregate, Context({ seaport: consideration }));
        test(this.execAggregate, Context({ seaport: referenceConsideration }));
    }

    ///@dev prepare aggregate test by minting tokens to offerer1
    function prepareAggregate() internal {
        test721_1.mint(offerer1.addr, 1);
        test721_2.mint(offerer1.addr, 1);
    }

    function execAggregate(Context memory context) external stateless {
        (
            Order[] memory orders,
            FulfillmentComponent[][] memory offerFulfillments,
            FulfillmentComponent[][] memory considerationFulfillments,
            bytes32 conduitKey,
            uint256 numOrders
        ) = _buildFulfillmentData(context);

        context.seaport.fulfillAvailableOrders{ value: 2 ether }({
            orders: orders,
            offerFulfillments: offerFulfillments,
            considerationFulfillments: considerationFulfillments,
            fulfillerConduitKey: conduitKey,
            maximumFulfilled: numOrders
        });
    }

    ///@dev build multiple orders from the same offerer
    function _buildOrders(
        Context memory context,
        OrderComponents[] memory orderComponents,
        uint256 key
    ) internal view returns (Order[] memory) {
        Order[] memory orders = new Order[](orderComponents.length);
        for (uint256 i = 0; i < orderComponents.length; i++) {
            orders[i] = toOrder(context.seaport, orderComponents[i], key);
        }
        return orders;
    }

    function _buildFulfillmentData(
        Context memory context
    )
        internal
        view
        returns (
            Order[] memory,
            FulfillmentComponent[][] memory,
            FulfillmentComponent[][] memory,
            bytes32,
            uint256
        )
    {
        ConsiderationItem[] memory considerationArray = SeaportArrays
            .ConsiderationItems(
                ConsiderationItemLib.fromDefault(ONE_ETH).withRecipient(
                    offerer1.addr
                )
            );
        OfferItem[] memory offerArray = SeaportArrays.OfferItems(
            OfferItemLib
                .fromDefault(SINGLE_721)
                .withToken(address(test721_1))
                .withIdentifierOrCriteria(1)
        );
        // build first order components
        OrderComponents memory orderComponents = OrderComponentsLib
            .fromDefault(VALIDATION_ZONE)
            .withOffer(offerArray)
            .withConsideration(considerationArray)
            .withCounter(context.seaport.getCounter(offerer1.addr));

        // second order components only differs by what is offered
        offerArray = SeaportArrays.OfferItems(
            OfferItemLib
                .fromDefault(SINGLE_721)
                .withToken(address(test721_2))
                .withIdentifierOrCriteria(1)
        );
        // technically we do not need to copy() since first order components is
        // not used again, but to encourage good practices, make a copy and
        // edit that
        OrderComponents memory orderComponents2 = orderComponents
            .copy()
            .withOffer(offerArray);

        Order[] memory orders = _buildOrders(
            context,
            SeaportArrays.OrderComponentsArray(
                orderComponents,
                orderComponents2
            ),
            offerer1.key
        );

        // create fulfillments
        // offer fulfillments cannot be aggregated (cannot batch transfer 721s) so there will be one array per order
        FulfillmentComponent[][] memory offerFulfillments = SeaportArrays
            .FulfillmentComponentArrays(
                // first FulfillmentComponents[] is single FulfillmentComponent for test721_1 id 1
                FulfillmentComponentLib.fromDefaultMany(FIRST_FIRST),
                // second FulfillmentComponents[] is single FulfillmentComponent for test721_2 id 1
                FulfillmentComponentLib.fromDefaultMany(SECOND_FIRST)
            );
        // consideration fulfillments can be aggregated (can batch transfer eth) so there will be one array for both orders
        FulfillmentComponent[][]
            memory considerationFulfillments = SeaportArrays
                .FulfillmentComponentArrays(
                    // two-element fulfillmentcomponents array, one for each order
                    FulfillmentComponentLib.fromDefaultMany(FIRST_SECOND__FIRST)
                );

        return (
            orders,
            offerFulfillments,
            considerationFulfillments,
            conduitKeyOne,
            2
        );
    }

    function toOrder(
        ConsiderationInterface seaport,
        OrderComponents memory orderComponents,
        uint256 pkey
    ) internal view returns (Order memory order) {
        bytes32 orderHash = seaport.getOrderHash(orderComponents);
        bytes memory signature = signOrder(seaport, pkey, orderHash);
        order = OrderLib
            .empty()
            .withParameters(orderComponents.toOrderParameters())
            .withSignature(signature);
    }
}
