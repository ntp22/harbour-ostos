import QtQuick 2.0
import Sailfish.Silica 1.0
import "../dbaccess.js" as DBA

/*
 * Copyright Antti Ketola 2015
 * License: GPL V3
 *
 * Main list page of the shopping list app
 */

Page {
    id: firstPage

    SilicaListView {
        id: firstPageView

        Component.onCompleted: {
            console.log("FirstPage SilicaListView: Component.onCompleted");
            shopModel.clear();
            DBA.repopulateShopList(shopModel); // ShopModel
            refreshShoppingListByShop();
        }

        header: PageHeader {
            height:Theme.paddingLarge *4
            ShopSelector {
                id: mainListShopSelector
                label: qsTr("Shop")
                listmodel: shopModel
                onEntered: {
                    onClicked: { refreshShoppingListByShop()}
                    DBA.repopulateShopList(shopModel); // ShopModel
                    shoppingListModel.clear();
                }
            }
        }

        anchors.fill: parent

        contentWidth: parent.width
        contentHeight: parent.height + Theme.paddingLarge
        VerticalScrollDecorator { flickable: firstPageView }

        model: shoppingListModel
        delegate: listLine

        ViewPlaceholder {
            enabled: shoppingListModel.count == 0
            text: qsTr("No items")
        }

        PullDownMenu {

            MenuItem {
                text: qsTr("Help")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("HelpPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Dump list");
                onClicked: {
                    DBA.dumpShoppingList();
                    console.log("...dumped.");
                }
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    pageStack.push("SettingsPage.qml")
                }
            }

            MenuItem {
                text: qsTr("Edit shops")
                onClicked: { pageStack.push(Qt.resolvedUrl("ShopPage.qml"));}
            }

            MenuItem {
                text: qsTr("Add new item")
                onClicked: pageStack.push(Qt.resolvedUrl("ItemDetailsPage.qml"))
            }

            MenuItem {
                text: qsTr("Refresh")
                onClicked: refreshShoppingListByShop();
            }
        }

    }
    /*
     * This is the ListItem of the shopping list row
     */
    Component {
        id: listLine
        ListItem {
            onClicked: { //ListItem
                firstPageView.currentIndex = index;
                ci = index;
                stateIndicator.cycle();
                //                console.log("Clicked ListItem, index=" + index + " listView.currentIndex = " + listView.currentIndex);
            }
            onPressed: {
                firstPageView.currentIndex = index
                ci = index;
                //                console.log("Pressed ListItem, index=" + index + " listView.currentIndex = " + listView.currentIndex)
            }

            menu: LineButtonsMenu {
                id: lineButtonsMenu
                modelindex: index
            }

            Rectangle {
                id: llr
                //spacing: 10
                width: firstPage.width
                anchors.verticalCenter: parent.verticalCenter

                StatButton { id: stateIndicator }

                Label {
                    x: 83
                    width: firstPage.width *.5
                    anchors.verticalCenter: parent.verticalCenter
                    truncationMode: TruncationMode.Fade
                    text: iname //+ " " + iqty + " " + iunit
                }
                Row{
                    x: firstPage.width * 0.75
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: iqty
                    }
                    Label {
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: iunit
                    }
                }
            }
        }
    } // END Component listLine


    RemorsePopup { id: remorse }

    function purgeShoppingList() {
        remorse.execute(qsTr("Clearing"), function() { DBA.deleteAllShoppingList(); shoppingListModel.clear() }, 10000 )
    }
}


