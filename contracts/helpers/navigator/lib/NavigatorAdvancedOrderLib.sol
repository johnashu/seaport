// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    AdvancedOrder,
    CriteriaResolver,
    OfferItem,
    ConsiderationItem,
    OrderParameters
} from "seaport-types/src/lib/ConsiderationStructs.sol";

import { Side } from "seaport-types/src/lib/ConsiderationEnums.sol";

import { CriteriaHelperLib } from "./CriteriaHelperLib.sol";

import { HelperItemLib } from "./HelperItemLib.sol";

import {
    NavigatorAdvancedOrder,
    NavigatorConsiderationItem,
    NavigatorOfferItem,
    NavigatorOrderParameters
} from "./SeaportNavigatorTypes.sol";

library NavigatorAdvancedOrderLib {
    using CriteriaHelperLib for uint256[];
    using HelperItemLib for NavigatorConsiderationItem;
    using HelperItemLib for NavigatorOfferItem;

    /*
     * @dev Converts an array of AdvancedOrders to an array of
     *      NavigatorAdvancedOrders.
     */
    function fromAdvancedOrders(
        AdvancedOrder[] memory orders
    ) internal pure returns (NavigatorAdvancedOrder[] memory) {
        uint256 ordersLength = orders.length;
        NavigatorAdvancedOrder[]
            memory helperOrders = new NavigatorAdvancedOrder[](ordersLength);
        for (uint256 i; i < ordersLength; i++) {
            helperOrders[i] = fromAdvancedOrder(orders[i]);
        }
        return helperOrders;
    }

    /*
     * @dev Converts an AdvancedOrder to a NavigatorAdvancedOrder.
     */
    function fromAdvancedOrder(
        AdvancedOrder memory order
    ) internal pure returns (NavigatorAdvancedOrder memory) {
        uint256 orderParamtersOfferLength = order.parameters.offer.length;
        uint256 orderParamtersConsiderationLength = order
            .parameters
            .consideration
            .length;

        // Copy over the offer items.
        NavigatorOfferItem[] memory offerItems = new NavigatorOfferItem[](
            orderParamtersOfferLength
        );

        OfferItem memory offerItem;

        for (uint256 i; i < orderParamtersOfferLength; i++) {
            offerItem = order.parameters.offer[i];
            offerItems[i] = NavigatorOfferItem({
                itemType: offerItem.itemType,
                token: offerItem.token,
                identifier: offerItem.identifierOrCriteria,
                startAmount: offerItem.startAmount,
                endAmount: offerItem.endAmount,
                candidateIdentifiers: new uint256[](0)
            });
        }
        // Copy over the consideration items.
        NavigatorConsiderationItem[]
            memory considerationItems = new NavigatorConsiderationItem[](
                orderParamtersConsiderationLength
            );
        ConsiderationItem memory considerationItem;
        for (uint256 i; i < orderParamtersConsiderationLength; i++) {
            considerationItem = order.parameters.consideration[i];
            considerationItems[i] = NavigatorConsiderationItem({
                itemType: considerationItem.itemType,
                token: considerationItem.token,
                identifier: considerationItem.identifierOrCriteria,
                startAmount: considerationItem.startAmount,
                endAmount: considerationItem.endAmount,
                recipient: considerationItem.recipient,
                candidateIdentifiers: new uint256[](0)
            });
        }
        return
            NavigatorAdvancedOrder({
                parameters: NavigatorOrderParameters({
                    offerer: order.parameters.offerer,
                    zone: order.parameters.zone,
                    offer: offerItems,
                    consideration: considerationItems,
                    orderType: order.parameters.orderType,
                    startTime: order.parameters.startTime,
                    endTime: order.parameters.endTime,
                    zoneHash: order.parameters.zoneHash,
                    salt: order.parameters.salt,
                    conduitKey: order.parameters.conduitKey,
                    totalOriginalConsiderationItems: order
                        .parameters
                        .totalOriginalConsiderationItems
                }),
                numerator: order.numerator,
                denominator: order.denominator,
                signature: order.signature,
                extraData: order.extraData
            });
    }

    /*
     * @dev Converts an array of NavigatorAdvancedOrders to an array of
     *      AdvancedOrders and an array of CriteriaResolvers.
     */
    function toAdvancedOrder(
        NavigatorAdvancedOrder memory order,
        uint256 orderIndex
    ) internal pure returns (AdvancedOrder memory, CriteriaResolver[] memory) {
        uint256 orderParamtersOfferLength = order.parameters.offer.length;
        uint256 orderParamtersConsiderationLength = order
            .parameters
            .consideration
            .length;

        // Create an array of CriteriaResolvers to be populated in the for loop
        // below. It might be longer than it needs to be, but it gets trimmed in
        // the assembly block below.
        CriteriaResolver[] memory criteriaResolvers = new CriteriaResolver[](
            orderParamtersOfferLength +
                orderParamtersConsiderationLength
        );
        uint256 criteriaResolverLen;

        // Copy over the offer items, converting candidate identifiers to a
        // criteria root if necessary and populating the criteria resolvers
        // array.
        OfferItem[] memory offer = new OfferItem[](
            orderParamtersOfferLength
        );

        NavigatorOfferItem memory navigatorOfferItem;
        for (uint256 i; i < orderParamtersOfferLength; i++) {
            navigatorOfferItem = order.parameters.offer[i];
            if (navigatorOfferItem.hasCriteria()) {
                navigatorOfferItem.validate();
                offer[i] = OfferItem({
                    itemType: navigatorOfferItem.normalizeType(),
                    token: navigatorOfferItem.token,
                    identifierOrCriteria: uint256(
                        navigatorOfferItem.candidateIdentifiers.criteriaRoot()
                    ),
                    startAmount: navigatorOfferItem.startAmount,
                    endAmount: navigatorOfferItem.endAmount
                });
                criteriaResolvers[criteriaResolverLen] = CriteriaResolver({
                    orderIndex: orderIndex,
                    side: Side.OFFER,
                    index: i,
                    identifier: navigatorOfferItem.identifier,
                    criteriaProof: navigatorOfferItem.candidateIdentifiers.criteriaProof(
                        navigatorOfferItem.identifier
                    )
                });
                criteriaResolverLen++;
            } else {
                offer[i] = OfferItem({
                    itemType: navigatorOfferItem.itemType,
                    token: navigatorOfferItem.token,
                    identifierOrCriteria: navigatorOfferItem.identifier,
                    startAmount: navigatorOfferItem.startAmount,
                    endAmount: navigatorOfferItem.endAmount
                });
            }
        }

        // Copy over the consideration items, converting candidate identifiers
        // to a criteria root if necessary and populating the criteria resolvers
        // array.
        ConsiderationItem[] memory consideration = new ConsiderationItem[](
            orderParamtersConsiderationLength
        );
        NavigatorConsiderationItem memory navigatorConsiderationItem;
        for (uint256 i; i < orderParamtersConsiderationLength; i++) {
            navigatorConsiderationItem = order
                .parameters
                .consideration[i];
            if (navigatorConsiderationItem.hasCriteria()) {
                navigatorConsiderationItem.validate();
                consideration[i] = ConsiderationItem({
                    itemType: navigatorConsiderationItem.normalizeType(),
                    token: navigatorConsiderationItem.token,
                    identifierOrCriteria: uint256(
                        navigatorConsiderationItem.candidateIdentifiers.criteriaRoot()
                    ),
                    startAmount: navigatorConsiderationItem.startAmount,
                    endAmount: navigatorConsiderationItem.endAmount,
                    recipient: navigatorConsiderationItem.recipient
                });
                criteriaResolvers[criteriaResolverLen] = CriteriaResolver({
                    orderIndex: orderIndex,
                    side: Side.CONSIDERATION,
                    index: i,
                    identifier: navigatorConsiderationItem.identifier,
                    criteriaProof: navigatorConsiderationItem.candidateIdentifiers.criteriaProof(
                        navigatorConsiderationItem.identifier
                    )
                });
                criteriaResolverLen++;
            } else {
                consideration[i] = ConsiderationItem({
                    itemType: navigatorConsiderationItem.itemType,
                    token: navigatorConsiderationItem.token,
                    identifierOrCriteria: navigatorConsiderationItem.identifier,
                    startAmount: navigatorConsiderationItem.startAmount,
                    endAmount: navigatorConsiderationItem.endAmount,
                    recipient: navigatorConsiderationItem.recipient
                });
            }
        }

        // This just encodes the length of the array that we gradually built up
        // above. It's just a way of creating an array of arbitrary length. It's
        // initialized to its longest possible length at the top, then populated
        // partially or fully in the for loop above. Finally, the length is set
        // here surgically.
        assembly {
            mstore(criteriaResolvers, criteriaResolverLen)
        }

        return (
            AdvancedOrder({
                parameters: OrderParameters({
                    offerer: order.parameters.offerer,
                    zone: order.parameters.zone,
                    offer: offer,
                    consideration: consideration,
                    orderType: order.parameters.orderType,
                    startTime: order.parameters.startTime,
                    endTime: order.parameters.endTime,
                    zoneHash: order.parameters.zoneHash,
                    salt: order.parameters.salt,
                    conduitKey: order.parameters.conduitKey,
                    totalOriginalConsiderationItems: order
                        .parameters
                        .totalOriginalConsiderationItems
                }),
                numerator: order.numerator,
                denominator: order.denominator,
                signature: order.signature,
                extraData: order.extraData
            }),
            criteriaResolvers
        );
    }

    /*
     * @dev Converts an array of NavigatorAdvancedOrders to an array of
     *      AdvancedOrders and an array of CriteriaResolvers.
     */
    function toAdvancedOrders(
        NavigatorAdvancedOrder[] memory orders
    )
        internal
        pure
        returns (AdvancedOrder[] memory, CriteriaResolver[] memory)
    {
        uint256 ordersLength = orders.length;
        // Create an array of AdvancedOrders to be populated in the for loop
        // below.
        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](
            ordersLength
        );

        // Create an array of CriteriaResolvers to be populated in the for loop
        // below. It might be longer than it needs to be, but it gets trimmed in
        // the assembly block below.
        uint256 maxCriteriaResolvers;
        NavigatorOrderParameters memory parameters;
        for (uint256 i; i < ordersLength; i++) {
            parameters = orders[i].parameters;
            maxCriteriaResolvers += (parameters.offer.length +
                parameters.consideration.length);
        }
        uint256 criteriaResolverIndex;
        CriteriaResolver[] memory criteriaResolvers = new CriteriaResolver[](
            maxCriteriaResolvers
        );

        // Copy over the NavigatorAdvancedOrder[] orders to the AdvancedOrder[]
        // array, converting and populating the criteria resolvers array.
        for (uint256 i = 0; i < ordersLength; i++) {
            (
                AdvancedOrder memory order,
                CriteriaResolver[] memory orderResolvers
            ) = toAdvancedOrder(orders[i], i);
            advancedOrders[i] = order;
            uint256 orderResolversLength = orderResolvers.length;
            for (uint256 j; j < orderResolversLength; j++) {
                criteriaResolvers[criteriaResolverIndex] = orderResolvers[j];
                criteriaResolverIndex++;
            }
        }

        // This just encodes the length of the array that we gradually built up
        // above. It's just a way of creating an array of arbitrary length. It's
        // initialized to its longest possible length at the top, then populated
        // partially or fully in the for loop above. Finally, the length is set
        // here surgically.
        assembly {
            mstore(criteriaResolvers, criteriaResolverIndex)
        }

        return (advancedOrders, criteriaResolvers);
    }
}
